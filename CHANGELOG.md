# Change Log

## [v0.2.0](https://github.com/cabol/shards/tree/v0.2.0) (2016-07-10)
[Full Changelog](https://github.com/cabol/shards/compare/0.1.0...v0.2.0)

**Implemented enhancements:**

- Encapsulate Shards **State** in its own module: `shards_state`.
- Fix `rebar3` build and tests – all can be done with `rebar3` directly.
- Fix `shards_dist` to handle `auto_eject_nodes` flag and/or unexpected errors.
- Implement basic select/match functions for `shards_dist` module.
- Configurable shards_owner_sup strategy, by means of restart_strategy option.
- Modify `shards_local` to avoid additional table types, handle a flag `sharded` instead. [\#10](https://github.com/cabol/shards/issues/10)
- Make distribution function to pick shard/node configurable. [\#9](https://github.com/cabol/shards/issues/9)
- Implement sharding at global level. [\#3](https://github.com/cabol/shards/issues/3)

**Closed issues:**

- OTP < 18 not supported [\#13](https://github.com/cabol/shards/issues/13)
- rebar2 compatibility [\#12](https://github.com/cabol/shards/issues/12)

**Merged pull requests:**

- General fixes and refactoring. [\#19](https://github.com/cabol/shards/pull/19) ([cabol](https://github.com/cabol))
- v0.2.0 [\#18](https://github.com/cabol/shards/pull/18) ([cabol](https://github.com/cabol))
- Preparing v0.2.0. [\#17](https://github.com/cabol/shards/pull/17) ([cabol](https://github.com/cabol))
- V0.1.1 [\#15](https://github.com/cabol/shards/pull/15) ([cabol](https://github.com/cabol))
- Enhancements and fix issue \#13. [\#14](https://github.com/cabol/shards/pull/14) ([cabol](https://github.com/cabol))
- \[\#9\] Implement configurable and dynamic pick/compute shard and node functions [\#11](https://github.com/cabol/shards/pull/11) ([cabol](https://github.com/cabol))

## [0.1.0](https://github.com/cabol/shards/tree/0.1.0) (2016-05-19)
**Closed issues:**

- Operation of the shards:info/2 does not match [\#8](https://github.com/cabol/shards/issues/8)

**Merged pull requests:**

- Fix README. [\#7](https://github.com/cabol/shards/pull/7) ([cabol](https://github.com/cabol))
- Refactor shards\_local to handle 'state' and avoid to call ETS control table. [\#6](https://github.com/cabol/shards/pull/6) ([cabol](https://github.com/cabol))
- Implemented distributed shards. [\#5](https://github.com/cabol/shards/pull/5) ([cabol](https://github.com/cabol))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*