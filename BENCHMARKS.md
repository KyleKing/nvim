# Startup Performance Benchmarks

Automated measurements from `scripts/measure_nvim.sh`. Each value is the
median of 3 runs to reduce noise from background load and disk cache state.
Every entry also records the commit and machine it was measured on, since
results aren't comparable across hardware. See
`PLAN_benchmark_reliability.md` for the methodology history.

Target: <150ms with config (threshold: 300ms)

## Historical range (pre-2026-07-20, superseded methodology)

These were single-sample measurements with no commit/machine tagging, taken
before `g:python3_host_prog` was pinned and the node/perl/ruby providers were
disabled -- "Opening Python file" below includes ~80ms of Neovim's
provider-discovery probe, not config cost. Kept only for historical range,
collapsed from 7 near-duplicate entries.

| Date range              | With config | Opening Python file |
| ------------------------ | ----------- | -------------------- |
| 2026-02-04 (5 runs)      | 27-38ms     | 88-167ms              |
| 2026-02-06 -- 2026-07-20 | 26-41ms     | 69-128ms              |

## Results


### 2026-07-20 23:36:03

- Commit: 1c2d5ac
- Machine: Apple M2 Pro (10 cores), macOS 26.5.2
- Load average: 1.64 1.59 1.59
- No config: 006.689ms
- With config: 037.326ms
- Opening init.lua: 042.159ms
- Opening Python file: 040.473ms

### 2026-07-20 23:45:35

- Commit: c9cd1bb
- Machine: Apple M4 Pro (12 cores), macOS 26.5.2
- Load average: 1.24 1.51 1.88
- No config: 005.043ms
- With config: 026.930ms
- Opening init.lua: 035.256ms
- Opening Python file: 031.196ms

### 2026-07-21 22:59:22

- Commit: 214a31d
- Machine: Apple M2 Pro (10 cores), macOS 26.5.2
- Load average: 1.67 2.41 2.59
- No config: 007.516ms
- With config: 037.063ms
- Opening init.lua: 047.553ms
- Opening Python file: 042.949ms
