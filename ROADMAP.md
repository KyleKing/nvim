# ROADMAP

Phased backlog with enough context to resume each item. Completed work is removed rather than checked off (history lives in git).

## Phase 1: Configuration ideas

Captured from a prior scratch list (next.md, removed 2026-07):

- Trouble/quickfix integration in `./irm`
- Better completions/omnifunc, evaluate Tab completion behavior
- Effective LSP folding (and verify in `:checkhealth`)
- Built-in argument highlighting: <https://github.com/m-demare/hlargs.nvim>
- Expand Spaghetti Code.nvim with trails/callgraphs (if not already covered): <https://github.com/nvim-mini/mini.nvim/discussions/1698>

## Phase 2: LSP navigation test fixtures

Continuation of the LSP_GTD.md draft (removed 2026-07). The user-facing behavior is now documented in `doc/src/config.md` (LSP Navigation); what remains is behavioral test coverage.

Goal: a `lua/tests/docs/lsp_navigation.lua` fixture covering the picker bindings (`<leader>lgd/lgi/lgr/lgt/lgs`), `K` hover, illuminate `]r`/`[r` reference jumps, and `<leader>lsc`/`<leader>lsC` call hierarchy. Note that `gd`/`grr`/`gri` are deliberately `<nop>` in this config (`deps/lsp.lua`), so tests should assert the nop plus the picker replacements.

Known implementation challenges from the draft:

- Tests need real LSP servers (ts_ls, pyright, lua_ls). Approach: spawn a temp project fixture directory, open a file, `vim.wait()` for client attach
- Monorepo re-export behavior (definition lands on a barrel file, not the source) needs a minimal two-package TypeScript fixture: `package-b/utils.ts` exporting through `package-b/index.ts`, imported by `package-a/main.ts`
- MiniPick is interactive; either drive it with `vim.api.nvim_input` in `nvim_interaction_test`, or validate the picker function/config instead of the UI
- LSP responses are async; wrap assertions in `vim.wait(2000, ...)`

Recommended sequencing from the draft: start with config-validation tests (bindings exist and point at the right picker scopes), then add one end-to-end temp-project test for the re-export case.

## Phase 3: Testing architecture evolution

Design essays live in `ideas-testdoc/` (documentation-driven testing, composable system design, testable TUI patterns). Revisit when extending the fixture system in `lua/tests/docs/`; `ACTUALLY_GOOD_TESTS.md` is the current authority for the implemented schema.

## Phase 4: Module rename

Rename `lua/find-relative-executable/` to `project-tools` (noted in AGENTS.md). Touchpoints: requires in `deps/lsp.lua`, conform/nvim-lint integration, `doc/workspace-diagnostics.md`, and tests.
