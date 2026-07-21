# PLAN: Fix benchmark noise and cross-machine comparability

## Problem

The 2026-07-20 15:54:03 -> 23:11:10 BENCHMARKS.md entries looked like a regression: "With config" 26ms -> 38ms, "Opening Python file" 69ms -> 128ms, across 10 commits (d59b67d..dafd6da) including a treesitter/markdown fix pass.

Bisecting each of those 10 commits in isolated worktrees (3 runs each, median) found no step-function jump. Every commit sits in the same noisy 34-39ms band for "With config":

| commit              | runs (ms)        |
| ------------------- | ---------------- |
| d59b67d (baseline)  | 34.1, 34.1, 34.0 |
| 723c516             | 34.6, 36.6, 36.3 |
| 559ffb0             | 44.5, 34.7, 35.6 |
| 64ee99f             | 37.6, 35.3, 35.1 |
| 6a3a2dc             | 34.4, 35.3, 38.0 |
| dafd6da (docs-only) | 39.5, 38.4, 38.6 |

`dafd6da` is a docs-only commit (appends a BENCHMARKS.md entry) with zero runtime diff from `6a3a2dc`, and `6a3a2dc` itself ranged 34-38ms across runs. So the appearance of a regression was measurement noise, not a real one.

Separately, and unrelated to any commit: "Opening Python file" is dominated by Neovim's python3 provider probe, not config code. `--startuptime` on that case shows:

```
119.680  079.258: sourcing .../autoload/provider/python3.vim
```

~79ms of the ~120ms total is `has('python3')` / host-provider resolution (PATH/pyenv scan for a python3 interpreter), because `g:python3_host_prog` is unset anywhere in the config. This cost varies run to run (113-128ms measured across identical commits) and swamps any real config-driven delta, which is why that metric looked like it nearly doubled.

Root cause of the false alarm: the benchmark harness has no noise control (single run, no repeats, no machine identity) and one uncontrolled variable (python3 provider probe) big enough to dominate its own signal.

## Fixes

### 1. Pin the python3 provider (removes the biggest source of noise)

Set `g:python3_host_prog` explicitly in `lua/kyleking/core/options.lua` (or wherever `vim.g` options are set) to skip the PATH/pyenv scan:

```lua
vim.g.python3_host_prog = vim.fn.exepath("python3")
```

Resolve once at config load (cheap, single `exepath` call) rather than letting Neovim's provider autoload do a broader search. This makes "Opening Python file" measure config/plugin cost again instead of interpreter discovery cost.

### 2. Record machine identity (already implemented)

`scripts/measure_nvim.sh` now appends `Commit: <short sha>` and `Machine: <CPU model> (<cores> cores), <OS version>` to every BENCHMARKS.md entry, using `sysctl`/`sw_vers` on macOS and `/proc/cpuinfo`/`uname` on Linux. This resolves the "different computers" ambiguity going forward — done, no further action needed here.

### 3. Add load-state context to rule out noise from background activity

The bisection found up to 10ms same-machine variance from run to run, likely background system load. Add one more line to the appended entry:

```bash
LOAD_AVG=$(sysctl -n vm.loadavg 2>/dev/null || uptime | grep -oE 'load average.*' )
```

Append as `Load average: <value>` so a spiky entry can be explained (or dismissed) without re-running the benchmark days later.

### 4. Take the median of N runs instead of a single sample

`scripts/measure_nvim.sh` currently runs each of the 4 measurements once. Wrap each measurement in a loop of 3 runs and record the median, matching what the bisection agent had to do manually to get a trustworthy number. Keep the per-run cost low (nvim headless startup is ~30-100ms) so 3x runtime is still a sub-second addition to `mise run measure`.

### 5. Treat the current history as noise, not a regression log

No code fix needed for the 10 bisected commits (d59b67d..dafd6da) themselves. Do not revert or investigate the markdown/treesitter fixes (64ee99f, 6a3a2dc) further on performance grounds; they are not implicated.

## Order of work

1. Pin `g:python3_host_prog` (#1) -- highest signal-to-effort, fixes the metric that looked worst.
1. Add median-of-3 sampling (#4) -- makes every future entry self-consistent.
1. Add load average to the appended entry (#3) -- cheap, explains outliers.
1. No action on #2, already shipped in this session.
