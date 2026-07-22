# Local plugin projects

Status of the plugin checkouts under `~/Developer/kyleking` and the work left to make each part of daily use. Started July 2026 while wiring spaghetti-comb and codanna into this config.

Both wired plugins install through `vim.pack` from `file://` sources (see `lua/kyleking/deps/local.lua`). Local edits only reach the config after committing in the source repo and running `vim.pack.update({ "<name>" }, { force = true })`.

## Wired into the config

### spaghetti-comb.nvim

Navigation history with branching, bookmarks, and a floating tree view. Phase 1 of its ROADMAP (test suite, CI, selene) is complete. Loaded with `<leader>n*` keymaps; behavioral tests live in `lua/tests/plugins/spaghetti_comb_spec.lua`.

Open tasks:

- Dogfood daily and file whatever breaks against ROADMAP Phase 2 (error handling, config validation, LSP edge cases)
- Note that `setup()` remaps `<C-o>`/`<C-i>` globally to its enhanced jumplist wrappers; `<C-i>` equals `<Tab>` in most terminals, so watch for surprises there
- Phase 3 (LSP relations explorer) is where the plugin becomes genuinely useful for large codebases
- July 2026 fixes made here: removed a broken `deps/mini.nvim` gitlink that made every fresh clone fail, and guarded the LSP cursor tracker against wiped buffers

### codanna.nvim

Picker UI over the codanna semantic-search CLI. Loaded with `<leader>s*` keymaps, mini.pick preferred; tests in `lua/tests/plugins/codanna_spec.lua`. The lockfile now points at the local checkout, which is ahead of the GitHub mirror.

Open tasks:

- Commit the Makefile-to-mise migration sitting uncommitted in the repo
- Run `codanna init && codanna index .` in one or two active projects to trial it; there are no indexes on this machine yet
- codanna 0.9.10 indexed zero files in a pure-Lua repo, so it will not help inside this config; trial it on Python or TypeScript projects
- Push local commits to GitHub once the migration is committed

## Not wired

### patch_it.nvim

Applies LLM-generated patches with fuzzy matching. One initial commit, working README, no further development.

Open tasks:

- Salvage `NVIM-PATCH-PLAN.md` from `backup_patch_it.nvim` (the only difference between the two clones), then delete the backup directory
- Decide whether the plan is still worth executing before wiring anything
- A stale `patch_it.nvim` entry remains in `nvim-pack-lock.json` and the pack dir from an earlier GitHub install; `:PackClean!` removes it once you confirm it is unused

### find-relative-executable.nvim_archived

Archived. Its functionality lives in this config as the `find-relative-executable` module, with a rename to `project-tools` still planned.
