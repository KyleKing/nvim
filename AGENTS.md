# AGENTS.md

## Commands

### Documentation generation

**IMPORTANT**: Never edit `doc/kyleking-neovim.txt` directly. It is auto-generated.

The vimdoc help file is generated from markdown sources using panvimdoc:

```bash
# Edit source files in doc/src/*.md
# Then regenerate vimdoc:
prek run panvimdoc --all-files

# The vimdoc is also regenerated automatically by pre-commit hooks
```

**Source files**:

- `doc/src/main.md` - Entry point (includes other files)
- `doc/src/config.md` - Configuration, commands, testing
- `doc/src/plugins.md` - Plugin guides
- `doc/src/vim-essentials.md` - Vim fundamentals
- `doc/src/notes.md` - Learning notes

**Generated output**: `doc/kyleking-neovim.txt` (accessible via `:h kyleking-neovim`)

### Linting and formatting

```bash
prek run --all-files          # Run all pre-commit hooks (stylua, selene, prettier, mdformat, etc.)
prek run stylua --all-files   # Run only StyLua
prek run selene --all-files   # Run only Selene linter
```

### Running tests

```bash
# Single test file (fastest, ~1-2 seconds)
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/custom/constants_spec.lua')" -c "qall!"

# CI tests - no external tool dependencies (fast, ~3-5 seconds)
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua require('kyleking.utils.test_runner').run_ci_tests()" -c "qall!"

# All tests - parallel workers (recommended, ~6-8 seconds, requires stylua/ruff/etc.)
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua require('kyleking.utils.test_runner').run_tests_parallel()" -c "sleep 10" -c "qall!"

# All tests - sequential (fallback, ~20 seconds)
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run()" -c "qall!"

# Random order - detect test dependencies (useful for finding state leakage)
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua require('kyleking.utils.test_runner').run_all_tests(false, true, 12345)" -c "qall!"

# Coverage tracking (requires luacov: luarocks install luacov)
./scripts/run_tests_with_coverage.sh custom  # Custom modules only (fast)
./scripts/run_tests_with_coverage.sh all     # All tests with coverage
./scripts/run_tests_with_coverage.sh lua/tests/custom/ui_spec.lua  # Specific file

# View coverage report
cat .luacov.report.out
```

**Interactive commands** (only when cwd is config directory):

| Command                          | Keybind      | Description                            |
| -------------------------------- | ------------ | -------------------------------------- |
| `:RunTestCI`                     | -            | CI-safe tests (no external tools)      |
| `:RunAllTests`                   | `<leader>ta` | Sequential with optimizations          |
| `:RunFailedTests`                | `<leader>tf` | Re-run only failed tests               |
| `:RunTestsParallel`              | `<leader>tp` | Parallel workers (requires ext. tools) |
| `:RunTestsRandom [seed]`         | `<leader>tr` | Random order sequential                |
| `:RunTestsParallelRandom [seed]` | -            | Parallel + random order                |

### Documentation-driven tests

Plugin documentation is auto-generated from test fixtures in `lua/tests/docs/`. Each fixture defines both behavioral tests and the documentation for that plugin.

```bash
# Run all fixture tests
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Run single fixture
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua require('tests.docs.runner').run_fixture('lua/tests/docs/surround.lua')" -c "qall!"

# Update snapshots (creates new, updates changed, prunes stale)
UPDATE_SNAPSHOTS=1 MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Profile fixture performance (shows timing per fixture/grammar/test)
PROFILE_TESTS=1 MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Generate documentation (auto-runs in pre-commit)
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua require('tests.docs.generator').generate_all()" +qall
```

**Hybrid testing approach**:

1. **Simple keybindings** (no special keys): Use `keys` field with `expect.lines`
1. **Complex keybindings** (`<leader>`, `<C-...>`): Use direct API calls in `expect.fn`
1. **UI-heavy plugins** (pick, files, diff): Focus on config validation
1. **Async operations** (hipatterns highlights): Use `setup.fn` with `vim.wait()`

See `ACTUALLY_GOOD_TESTS.md` for fixture schema and architecture.

See `REGRESSION_TEST_GUIDE.md` for quick reference on adding tests for bugs.

### Startup validation

The subprocess-based smoke test in `lua/tests/core/smoke_spec.lua` spawns a fresh nvim and checks stderr for `mini.deps` two-stage execution errors. This catches nil-rhs keymap errors and other issues that only surface after all `later()` callbacks complete -- issues that in-process MiniTest cases cannot observe due to `vim.schedule` nesting.

## Architecture

### Boot sequence

`init.lua` -> `lua/kyleking/init.lua` which loads two phases:

1. **Core** (`lua/kyleking/core/init.lua`): options -> lsp -> keymaps -> autocmds
1. **Plugins** (`lua/kyleking/setup-deps.lua`): bootstraps mini.deps, then requires each `lua/kyleking/deps/*.lua` file

### Plugin management (mini.deps)

All plugins are managed through mini.deps, not lazy.nvim. Each `deps/*.lua` file groups related plugins by functionality (not one-file-per-plugin).

```lua
local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("author/plugin")
    require("plugin").setup({ ... })
    vim.keymap.set("n", "<leader>xx", function() require("plugin").action() end, { desc = "..." })
end)
```

- `now()` for plugins needed at startup (colorscheme, mini.test)
- `later()` for everything else (deferred loading)
- Set `MINI_DEPS_LATER_AS_NOW=1` to make `later()` behave like `now()` (useful for testing)
- Plugin keymaps belong in their respective `deps/*.lua` file, not in `core/keymaps.lua`
- Wrap plugin function calls in keymaps with anonymous functions to prevent nil-rhs errors when the plugin hasn't loaded yet

### mini.nvim ecosystem

This config uses mini.nvim modules heavily instead of standalone plugins: mini.pick (fuzzy finder), mini.files (file explorer), mini.diff/mini.git (git), mini.hipatterns (keyword highlights), mini.surround, mini.ai (enhanced text objects), mini.move, mini.clue (which-key), mini.comment, mini.trailspace, mini.icons (Nerd Font icons), mini.statusline, mini.tabline, and more.

For mini.ai text object bindings and custom specs, see `:help mini.ai` and `lua/kyleking/deps/editing.lua`.

### Test structure

Tests use mini.test (not plenary or busted). Test files live in `lua/tests/` and follow `*_spec.lua` naming.

```
lua/tests/
├── helpers.lua           # Shared test utilities
├── core/                 # Core functionality tests (smoke, completion)
├── plugins/              # Per-plugin tests
├── custom/               # Custom utility tests
├── integration/          # Workflow tests
└── ui/                   # UI component tests
```

Test file pattern:

```lua
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({ hooks = { pre_case = function() end } })
T["group"] = MiniTest.new_set()
T["group"]["case name"] = function()
    MiniTest.expect.equality(actual, expected, "message")
end

if ... == nil then MiniTest.run() end
return T
```

See `lua/tests/helpers.lua` for available test utilities (`nvim_interaction_test`, `check_keymap`, `create_test_buffer`, etc.).

### Test quality guidelines

Tests should verify **behavior**, not **existence**. The subprocess smoke test (`smoke_spec.lua`) already catches plugin load failures.

**Do write tests that:**

- Verify custom code produces expected output (Tier 1)
- Verify plugin configuration produces expected behavior (Tier 2)
- Test edge cases, error paths, and regressions

**Do not write tests that only:**

- Check `is_plugin_loaded("X")` or `type(X.func) == "function"`
- Verify a keymap exists without testing what it does
- Spawn a subprocess, call `pcall(function() end)`, and check exit code 0
- Assert `true == true` to unconditionally pass

When testing plugin configuration, prefer asserting config values or behavioral outcomes:

```lua
-- Good: tests config value
MiniTest.expect.equality(MiniAi.config.n_lines, 500)

-- Good: tests behavior
vim.cmd("normal gcc")
local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
MiniTest.expect.equality(line:match("^%s*%-%-") ~= nil, true)

-- Bad: tests existence only
MiniTest.expect.equality(helpers.is_plugin_loaded("mini.comment"), true)
MiniTest.expect.equality(type(flash.jump), "function")
```

### LSP configuration (nvim 0.11+)

LSP configuration is split across three locations:

1. **Core setup** (`lua/kyleking/core/lsp.lua`): Completion, snippet, keymap setup
1. **Server configs** (`lsp/*.lua`): Per-server settings files returning `{filetypes, root_markers, settings}` tables:
    - `lsp/lua_ls.lua`, `lsp/pyright.lua`, `lsp/gopls.lua`, `lsp/ts_ls.lua`, `lsp/terraformls.lua`
    - Auto-loaded by nvim 0.11+ native LSP system
    - To add new LSP: create `lsp/<server>.lua` following existing patterns
1. **Plugin integration** (`lua/kyleking/deps/lsp.lua`): Linters (nvim-lint), formatting (conform.nvim), signature help, plugin-dependent servers (jsonls/yamlls with SchemaStore)

### Tool resolution (find-relative-executable)

`lua/find-relative-executable/init.lua` resolves project-local binaries for linters/formatters. Walks upward from buffer to find `pyproject.toml` (-> `.venv/bin/`) or `package.json` (-> `node_modules/.bin/`), caches by project root, falls back to `$PATH`. Used in `deps/lsp.lua` and `deps/formatting.lua`.

See `lua/find-relative-executable/init.lua` for API (`resolve`, `command_for`, `cmd_for`, `clear_cache`).

### Key conventions

- Leader: `<space>`, local leader: `,`
- `local K = vim.keymap.set` alias consistently used in deps files
- **Use mode arrays**: `vim.keymap.set({ "n", "x" }, ...)` instead of separate calls for each mode
- Autocmd groups prefixed with `kyleking_` (e.g., `kyleking_winsep`)
- Theme colors accessed via `require("kyleking.theme").get_colors()`
- `PLANNED:` comments mark features to add when upstream support arrives
- Skip floating windows in global autocmds: `if vim.api.nvim_win_get_config(0).relative ~= "" then return end`

### Custom utilities

- `lua/kyleking/utils/noqa.lua` - Diagnostic suppression (noqa-style comments). See file for API.
- `lua/kyleking/utils/fs_utils.lua` - File system utilities (git worktrees, Python path detection)
- `lua/kyleking/utils/list_editing.lua` - Markdown/djot list editing (continuation, indent/dedent, djot blank line handling)
- `lua/kyleking/utils/preview.lua` - CLI-based markdown/djot preview in browser using pandoc or djot CLI

## Style

- **Commits**: Commitizen conventional commits
- **JSON**: 4-space indent (pretty-format-json), prettier does NOT handle JSON
- Avoid `MiniPlugin` globals in source files; use `local x = require("mini.plugin")` to keep selene clean
