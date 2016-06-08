%%%-------------------------------------------------------------------
%%% @doc
%%% Shards owners supervisor.
%%% @end
%%%-------------------------------------------------------------------
-module(shards_owner_sup).

-behaviour(supervisor).

%% API
-export([start_link/2]).

%% Supervisor callbacks
-export([init/1]).

%% Macro to setup a supervisor worker
-define(worker(Mod, Args, Spec), child(worker, Mod, Args, Spec)).

%% Default number of shards
-define(N_SHARDS, erlang:system_info(schedulers_online)).

%% Macro to check if restart strategy is allowed
-define(is_restart_strategy(S_), S_ == one_for_one; S_ == one_for_all).

%% Macro to check if option is table type
-define(is_ets_type(T_), T_ == set; T_ == ordered_set; T_ == bag; T_ == duplicate_bag).

%%%===================================================================
%%% API functions
%%%===================================================================

-spec start_link(Name, Options) -> Response when
  Name     :: atom(),
  Options  :: [term()],
  Response :: supervisor:startlink_ret().
start_link(Name, Options) ->
  supervisor:start_link({local, Name}, ?MODULE, [Name, Options]).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%% @hidden
init([Name, Options]) ->
  % ETS table to hold state info.
  Name = ets:new(Name, [
    set,
    named_table,
    public,
    {read_concurrency, true}
  ]),

  % parse options and build metadata, local and dist state
  ParsedOpts = #{
    module           := Module,
    n_shards         := NumShards,
    restart_strategy := RestartStrategy,
    opts             := Opts
  } = parse_opts(Options),
  LocalState = local_state(ParsedOpts),
  DistState = dist_state(ParsedOpts),
  Metadata = {Module, LocalState, DistState},
  true = ets:insert(Name, {'$shards_meta', Metadata}),

  % create children
  Children = [begin
    % get a local name to shard
    LocalShardName = shards_owner:shard_name(Name, Shard),
    % save relationship between shard and shard name
    true = ets:insert(Name, {Shard, LocalShardName}),
    % shard worker spec
    ?worker(shards_owner, [LocalShardName, Opts], #{id => Shard})
  end || Shard <- lists:seq(0, NumShards - 1)],

  % init shards_dist pg2 group
  ok = init_shards_dist(Name, Module),

  % launch shards supervisor
  supervise(Children, #{strategy => RestartStrategy}).

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% @private
child(Type, Module, Args, Spec) when is_map(Spec) ->
  {maps:get(id, Spec, Module),
   maps:get(start, Spec, {Module, start_link, Args}),
   maps:get(restart, Spec, permanent),
   maps:get(shutdown, Spec, 5000),
   Type,
   maps:get(modules, Spec, [Module])}.

%% @private
supervise(Children, SupFlagsMap) ->
  ok = assert_unique_ids([Id || {Id, _, _, _, _, _} <- Children]),
  SupFlags = {
    maps:get(strategy, SupFlagsMap, one_for_one),
    maps:get(intensity, SupFlagsMap, 1),
    maps:get(period, SupFlagsMap, 5)
  },
  {ok, {SupFlags, Children}}.

%% @private
assert_unique_ids([]) ->
  ok;
assert_unique_ids([Id | Rest]) ->
  case lists:member(Id, Rest) of
    true -> throw({badarg, duplicated_id});
    _    -> assert_unique_ids(Rest)
  end.

%% @private
parse_opts(Opts) ->
  AccIn = #{
    module           => shards_local,
    n_shards         => ?N_SHARDS,
    type             => set,
    pick_shard_fun   => fun shards_local:pick_shard/3,
    pick_node_fun    => fun shards_dist:pick_node/3,
    autoeject_nodes  => true,
    restart_strategy => one_for_one,
    opts             => []
  },
  parse_opts(Opts, AccIn).

%% @private
parse_opts([], Acc) ->
  Acc;
parse_opts([{scope, l} | Opts], Acc) ->
  parse_opts(Opts, Acc#{module := shards_local});
parse_opts([{scope, g} | Opts], Acc) ->
  parse_opts(Opts, Acc#{module := shards_dist});
parse_opts([{n_shards, N} | Opts], Acc) when is_integer(N), N > 0 ->
  parse_opts(Opts, Acc#{n_shards := N});
parse_opts([{pick_shard_fun, PickShard} | Opts], Acc) when is_function(PickShard) ->
  parse_opts(Opts, Acc#{pick_shard_fun := PickShard});
parse_opts([{pick_node_fun, PickNode} | Opts], Acc) when is_function(PickNode) ->
  parse_opts(Opts, Acc#{pick_node_fun := PickNode});
parse_opts([{autoeject_nodes, AutoEject} | Opts], Acc) when is_boolean(AutoEject) ->
  parse_opts(Opts, Acc#{autoeject_nodes := AutoEject});
parse_opts([{restart_strategy, Strategy} | Opts], Acc) when ?is_restart_strategy(Strategy) ->
  parse_opts(Opts, Acc#{restart_strategy := Strategy});
parse_opts([Opt | Opts], #{opts := NOpts} = Acc) when ?is_ets_type(Opt) ->
  parse_opts(Opts, Acc#{type := Opt, opts := [Opt | NOpts]});
parse_opts([Opt | Opts], #{opts := NOpts} = Acc) ->
  parse_opts(Opts, Acc#{opts := [Opt | NOpts]}).

%% @private
local_state(Opts) ->
  #{n_shards       := NumShards,
    type           := Type,
    pick_shard_fun := PickShard} = Opts,
  {NumShards, PickShard, Type}.

%% @private
dist_state(Opts) ->
  #{pick_node_fun   := PickNode,
    autoeject_nodes := AutoEject} = Opts,
  {PickNode, AutoEject}.

%% @private
init_shards_dist(Tab, shards_dist) ->
  ok = pg2:create(Tab),
  ok = pg2:join(Tab, self());
init_shards_dist(_, _) ->
  ok.
