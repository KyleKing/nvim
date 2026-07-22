# Feature-usage tracking — design

## Problem

I want to know which of my own features I actually use: keymaps, commands, and a subset of motions. The goal is to drive three decisions:

- **Remove or practice** whatever is under-used or never used. These are one category, not two: the log says a map is cold, and I decide per case whether to delete it or build the habit (mini.ai objects, mini.move, the link opener). The data is the same signal either way.
- **Improve** or rebind things I use constantly through an awkward path

Raw keystroke counters (the keyfreq lineage) can't answer this. "`j` fired 4000 times" is noise. The question is about *logical* mappings and commands, plus a curated set of compound motions like `ciw`, not physical keys.

## What already exists (verdict: build our own)

| Plugin                                                                  | What it does                    | Why it doesn't fit                                                      |
| ----------------------------------------------------------------------- | ------------------------------- | ----------------------------------------------------------------------- |
| [keymaps.nvim](https://github.com/abdul-hamid-achik/keymaps.nvim)       | `track_usage` + `:KeymapsStats` | Owns your whole keymap layer (cheatsheet-first); mechanism undocumented |
| [key-report.nvim](https://github.com/letieu/key-report.nvim)            | Exactly this idea               | Archived June 2025, core logging still on its TODO                      |
| [usage-tracker.nvim](https://github.com/gaborvecsei/usage-tracker.nvim) | Time-in-file, filetype          | Wrong axis; no semantic maps or commands                                |
| [keystats.nvim](https://github.com/OscarCreator/keystats.nvim)          | Raw keystroke heatmap           | Physical keys, not logical maps                                         |

None tracks semantic maps + commands + curated motions with a "never used" report. Build a self-contained module in `lua/kyleking/utils/` (extract to a plugin later only if it earns it), matching the existing fixture/spec workflow.

## Locked decisions (from review)

- **Scope**: maps + commands + configurable motion sampling. The sampler keeps compound sequences I care about (`ciw`, `f{char}`, operator+textobject) and drops a configurable denylist of pure-navigation single keys (`h j k l w b e 0 $` and similar).
- **Storage**: JSONL, one file per host, under a configurable Syncthing path. Default `~/Sync/.nvim/usage/<host>.jsonl`. Per-host files so Syncthing never hits an append conflict; the report globs every host file at analysis time.
- **Delivery**: this doc first, then a phased build with tests.

## Mechanisms

Three hooks, each covering a layer the others can't:

### 1. Keymaps — wrap `vim.keymap.set` at boot

`lua/kyleking/init.lua` requires `core` (which runs `core/keymaps.lua`) before anything else, and every `deps/*.lua` file captures `local K = vim.keymap.set` at require-time. So the wrapper must replace `vim.keymap.set` **on line 1 of `lua/kyleking/init.lua`, before `require("kyleking.core")`**. Do that and every alias `K` in the config points at the wrapped function for free.

The wrapper records `{lhs, desc, mode, buffer-local?}` at set-time, and for **callback** rhs swaps in a logging wrapper that records-then-calls. This is the high-signal path: the interesting maps (`<leader>xx` → `function() ... end`) are all callbacks, and `desc` (already written for clue.nvim) gives each event a stable human label.

**Blind spot — string/expr rhs.** Maps with a string rhs (`"+y`, the `gk`/`gj` expr maps, `<Space>` → `<Nop>` set via `nvim_api_set_keymap`) have no callback to wrap, so we can log that they *exist* but not that they *fired*. Two facts make this acceptable for v1: those maps are simple remaps of low decision-value, and the motion sampler (hook 3) catches the ones that matter as raw sequences anyway. The `<Space><Nop>` and other `nvim_set_keymap` calls bypass `vim.keymap.set` entirely and are invisible to hook 1; document, don't chase.

### 2. Commands — one `CmdlineLeave` autocmd

On `CmdlineLeave` with `cmdtype == ":"`, read `vim.fn.getcmdline()` and log the first token. Captures built-in (`:w`), user (`:RunAllTests`, `:PackClean`), and plugin commands with zero per-command wiring. No wrapping of `nvim_create_user_command` needed unless we later want to flag user commands defined but never called (that falls out of the never-used reconciliation in hook 4 instead).

### 3. Motions — throttled `vim.on_key` with sequence assembly

This is the hard hook and the one with real imprecision. `vim.on_key(fn, ns)` gives `(key, typed)` per press. Single-key frequency is trivial; assembling `c` `i` `w` back into the semantic unit `ciw` is a best-effort heuristic:

- Only sample in **normal** and **visual** modes (skip insert/cmdline/terminal).
- Accumulate pressed keys into a pending buffer. Flush the buffer as one "sequence" event when the operation resolves — detected via a `ModeChanged` back to a rest state, or a short idle timeout, whichever comes first.
- Drop any sequence whose entire content is in the denylist (`h j k l` etc.). Keep multi-key sequences (`ciw`, `di(`, `f;`, `gUiw`).
- Cap sequence length (e.g. 6 keys) so a stuck buffer can't log garbage.

Known limitation to accept up front: counts under a `count` prefix (`3ciw`), register prefixes (`"ayy`), and remapped operators can misattribute. The sampler is a **directional signal** ("I lean on text objects", "I never use `t`"), not an exact ledger. If it proves too noisy, hook 3 is the one to disable via config while 1 and 2 keep working.

### Coverage summary

| Layer                      | Hook                  | Fires on   | Gap                     |
| -------------------------- | --------------------- | ---------- | ----------------------- |
| `<leader>` + callback maps | wrap `vim.keymap.set` | invocation | none                    |
| string/expr maps           | wrap (set-time only)  | —          | no invocation count     |
| `nvim_set_keymap` maps     | none                  | —          | invisible               |
| `:commands`                | `CmdlineLeave`        | invocation | none                    |
| compound motions           | `vim.on_key`          | invocation | approximate attribution |

## Event schema (JSONL, one object per line)

```jsonl
{"ts": 1721577600, "kind": "map", "key": "<leader>ff", "desc": "Find files", "mode": "n", "ft": "lua", "cwd": "nvim", "host": "mbp"}
{"ts": 1721577612, "kind": "cmd", "key": "PackClean", "mode": "c", "ft": "lua", "cwd": "nvim", "host": "mbp"}
{"ts": 1721577620, "kind": "motion", "key": "ciw", "mode": "n", "ft": "python", "cwd": "irm", "host": "mbp"}
```

Fields: `ts` (epoch s), `kind` (`map`/`cmd`/`motion`), `key`, `desc` (maps only), `mode`, `ft` (buffer filetype), `cwd` (project basename, not full path, to keep lines short and avoid leaking full paths across the sync folder), `host`. Keep it flat and small — one line stays well under 200 bytes.

## Storage and sync

- Path: `opts.dir` (default `~/Sync/.nvim/usage/`), file `<host>.jsonl` where host comes from `vim.uv.os_gethostname()`. Per-device override of the directory via config, so a machine without `~/Sync` points elsewhere or disables writing.
- **Never fsync per event.** Buffer events in a Lua table, flush batched via `vim.uv` async append on a timer (e.g. every 30 s) and unconditionally on `VimLeavePre`. A crash loses at most the last window, which is fine.
- Append-only + per-host means Syncthing merges are trivial (two hosts never write the same file). The report reads every `*.jsonl` in the dir and unions them.

## Reporting — the payoff is the negative space

Counting is half the value. The decision-driving view is what I've **never** triggered. A `:FeatureUsage` command (backed by a mini.pick source) renders three views:

1. **Top used** — maps/commands/motions by count, filterable by `kind` and `ft`.
1. **Cold** — everything under-used or never used, ranked coldest first, since remove-or-practice is one decision made per row. Two signals feed it: registered but absent from the log entirely (reconcile the live keymap set via `nvim_get_keymap` across modes plus the buffer variants, and the user-command list, against the aggregated log), and used a handful of times in an early window then zero since. Show count and last-used date per row so I can tell "never knew it existed" from "tried it, dropped it" at a glance.

Reconciliation runs **lazily** when the report opens, not at startup, because `pack.later()` drains async — the full keymap set only exists after deferred loading finishes, and a live snapshot at report time is simpler and always current than a snapshot taken at a guessed moment.

## Module layout and wiring

```
lua/kyleking/utils/usage/
  init.lua       -- install(): patch vim.keymap.set, register autocmds/on_key, config
  writer.lua     -- buffered JSONL append (vim.uv async, timer + VimLeavePre flush)
  motion.lua     -- on_key sequence assembler + denylist
  report.lua     -- aggregate host files, three views, :FeatureUsage + pick source
```

Wiring: add `require("kyleking.utils.usage").install()` as the **first statement** in `lua/kyleking/init.lua`, above `require("kyleking.core")`. `install()` must be cheap and synchronous (patch the function, set two autocmds, start no heavy work) so it doesn't slow startup — the benchmark suite (`mise run bench:startup`) guards this.

## Config (defaults)

```lua
require("kyleking.utils.usage").install({
    enabled = true,
    dir = vim.fn.expand("~/Sync/.nvim/usage"),
    host = nil,                       -- default: vim.uv.os_gethostname()
    flush_interval_ms = 30000,
    track = { maps = true, commands = true, motions = true },
    motion = {
        max_seq_len = 6,
        denylist = { "h", "j", "k", "l", "w", "b", "e", "0", "$", "^", "gj", "gk" },
    },
    redact_cwd = true,                -- store project basename, not full path
})
```

## Risks and open questions

- **Motion attribution accuracy** (hook 3). Ship it behind `track.motions` so it can be cut without touching maps/commands. Open question: is the denylist the right filter, or do I want an *allowlist* of sequences I explicitly care about (`ciw`, `di(`, `ca"`)? An allowlist is far more precise and far less noisy, at the cost of only learning about motions I already thought to list. Leaning allowlist for the compound-motion view; still deciding.
- **Startup cost.** Patching one function + two autocmds is negligible, but the per-callback wrapper adds a closure and a table write on every map invocation. Measure with `bench:startup` and a hot-loop test before trusting it.
- **String-rhs invocation gap.** Accept for v1. Revisit only if a specific string-rhs map turns out to be a decision I can't make without its count.
- **Privacy in the sync folder.** `cwd` is stored as basename only. No file contents, no full paths, no typed text beyond the motion key name. Confirm that's enough before syncing.

## Test plan

- **writer**: buffered append writes valid JSONL; flush on `VimLeavePre`; missing `dir` degrades to disabled without error (custom spec).
- **map wrapper**: setting a callback map still calls the original; a logged event carries the right `lhs`/`desc`/`mode`; string-rhs maps set without error and are not double-invoked (custom spec).
- **command hook**: `CmdlineLeave` logs the first token for user and built-in commands; aborted cmdline (`<Esc>`) logs nothing (integration spec).
- **motion assembler**: `ciw` assembles to one event; a denylisted single key logs nothing; a sequence over `max_seq_len` is dropped (custom spec).
- **report**: cold view lists a registered-but-unlogged map and ranks a tried-then-dropped map by last-used date; top-used ranks by count; aggregation unions two host files (custom spec with fixture JSONL).
- **smoke**: the subprocess smoke test already catches boot breakage from the line-1 wiring.

## Phases

1. writer + map wrapper + command hook + minimal `:FeatureUsage` top-used view. Land this, run it for a couple weeks, confirm the data is worth it.
1. the cold view (reconciliation + last-used) and the pick source.
1. motion sampler (denylist or allowlist per the open question), behind `track.motions`.
