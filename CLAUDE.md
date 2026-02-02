# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Linting and formatting

```bash
prek run --all-files          # Run all pre-commit hooks (stylua, selene, prettier, mdformat, etc.)
prek run stylua --all-files   # Run only StyLua
prek run selene --all-files   # Run only Selene linter
```

### Running tests

```bash
# All tests
nvim --headless -c "lua MiniTest.run()" -c "qall!"

# Single test file
nvim --headless -c "lua MiniTest.run_file('lua/tests/core/smoke_spec.lua')" -c "qall!"
```

From within nvim (only when cwd is config directory): `:RunAllTests`, `:RunFailedTests`, `<leader>ta`, `<leader>tf`.

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
- Plugin keymaps belong in their respective `deps/*.lua` file, not in `core/keymaps.lua`
- Wrap plugin function calls in keymaps with anonymous functions to prevent nil-rhs errors when the plugin hasn't loaded yet

### mini.nvim ecosystem

This config uses mini.nvim modules heavily instead of standalone plugins: mini.pick (fuzzy finder), mini.files (file explorer), mini.diff/mini.git (git), mini.hipatterns (keyword highlights), mini.surround, mini.ai (enhanced text objects), mini.move, mini.clue (which-key), mini.comment, mini.trailspace, mini.icons (Nerd Font icons), mini.statusline, mini.tabline, and more.

**mini.ai text objects**: Provides enhanced "around/inside next/last" text objects that work with treesitter:

- `vaN` - select around next argument
- `viL` - select inside last brackets
- `daf` - delete around function call
- Works with: `f` (function), `a` (argument), `b` (brackets), `q` (quotes), `t` (tags)

### Test structure

Tests use mini.test (not plenary or busted). Test files live in `lua/tests/` and follow `*_spec.lua` naming.

```
lua/tests/
├── helpers.lua           # Shared test utilities (create_test_buffer, check_keymap, nvim_interaction_test, etc.)
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

Key test utilities in `lua/tests/helpers.lua`:

- `nvim_interaction_test(lua_code)` - Spawns subprocess nvim with full config to test plugin interactions (floats, mini.files, pickers). Use for bugs that only manifest at runtime.
- `wait_for_condition(fn, timeout_ms)` - Polls condition function until true or timeout
- `check_keymap(mode, lhs, desc_pattern)` - Validates keymap exists with matching description
- `create_test_buffer(lines)` - Creates scratch buffer with content
- `get_diagnostic_count(bufnr, severity)` - Returns count of diagnostics by severity level

### LSP configuration (nvim 0.11+)

LSP configuration is split across three locations:

1. **Core setup** (`lua/kyleking/core/lsp.lua`): Completion, snippet, keymap setup
1. **Server configs** (`lsp/*.lua`): Per-server settings files returning `{filetypes, root_markers, settings}` tables:
    - `lsp/lua_ls.lua`, `lsp/pyright.lua`, `lsp/gopls.lua`, `lsp/ts_ls.lua`, `lsp/terraformls.lua`
    - Auto-loaded by nvim 0.11+ native LSP system
    - To add new LSP: create `lsp/<server>.lua` following existing patterns
1. **Plugin integration** (`lua/kyleking/deps/lsp.lua`): Linters (nvim-lint), formatting (conform.nvim), signature help, plugin-dependent servers (jsonls/yamlls with SchemaStore)

### Tool resolution (find-relative-executable)

`lua/find-relative-executable/init.lua` resolves project-local binaries for linters/formatters. Walks upward from buffer to find `pyproject.toml` (→ `.venv/bin/`) or `package.json` (→ `node_modules/.bin/`), caches by project root, falls back to `$PATH`.

API:

- `resolve(tool, buf_path)` - Returns resolved path string
- `command_for(tool)` - Returns conform.nvim adapter function
- `cmd_for(tool)` - Returns nvim-lint adapter function
- `clear_cache()` - Clears resolution cache

Used in `deps/lsp.lua` and `deps/formatting.lua` to prefer local tool installations.

### Key conventions

- Leader: `<space>`, local leader: `,`
- `local K = vim.keymap.set` alias consistently used in deps files
- **Use mode arrays**: `vim.keymap.set({ "n", "x" }, ...)` instead of separate calls for each mode
- Autocmd groups prefixed with `kyleking_` (e.g., `kyleking_winsep`)
- Theme colors accessed via `require("kyleking.theme").get_colors()`
- `PLANNED:` comments mark features to add when upstream support arrives
- Skip floating windows in global autocmds: `if vim.api.nvim_win_get_config(0).relative ~= "" then return end`

### Custom utilities

- `lua/kyleking/utils/noqa.lua` - Diagnostic suppression (noqa-style comments for ruff, selene, oxlint, etc.)
    - `ignore_inline()` - Add suppression comment at cursor line
    - `ignore_file()` - Add file-wide suppression at top
- `lua/kyleking/utils/fs_utils.lua` - File system utilities (git worktrees, Python path detection)
- `lua/find-relative-executable/init.lua` - Project-local tool resolution (see Tool resolution section)

## Style

- **Formatter**: StyLua -- spaces for indentation, `collapse_simple_statement = "Always"`
- **Linter**: Selene with `std = "vim"` (custom `vim.toml` defines nvim globals)
- **Commits**: Commitizen conventional commits
- **JSON**: 4-space indent (pretty-format-json), prettier does NOT handle JSON
- Avoid `MiniPlugin` globals in source files; use `local x = require("mini.plugin")` to keep selene clean
