## This Config

Leader key: `<Space>` -- Local leader: `,`

## Boot Sequence

`init.lua` -> `lua/kyleking/init.lua` which loads two phases:

1. **Core** (`lua/kyleking/core/init.lua`): options -> lsp -> keymaps -> autocmds
2. **Plugins** (`lua/kyleking/setup-deps.lua`): bootstraps mini.deps, then
   requires each `lua/kyleking/deps/*.lua` file

## Plugin Management

All plugins are managed through mini.deps. Each `deps/*.lua` file groups
related plugins by functionality.

- `now()` for plugins needed at startup (colorscheme, mini.test)
- `later()` for everything else (deferred loading)
- Plugin keymaps live in their respective `deps/*.lua` file

## External Tools

This config requires external LSP servers, linters, and formatters. Install
with mise or your preferred package manager.

### LSP Servers

    # npm-based servers
    mise use -g npm:bash-language-server
    mise use -g npm:dockerfile-language-server-nodejs
    mise use -g npm:pyright
    mise use -g npm:typescript
    mise use -g npm:typescript-language-server
    mise use -g npm:vscode-langservers-extracted  # cssls, html, jsonls
    mise use -g npm:yaml-language-server
    mise use -g npm:@microsoft/compose-language-service

    # Other package managers
    mise use -g go:golang.org/x/tools/gopls
    mise use -g cargo:taplo-cli  # TOML
    brew install hashicorp/tap/terraform-ls
    brew install lua-language-server

### Linters

    # npm
    mise use -g npm:oxlint
    mise use -g npm:stylelint

    # pip/uv (or use project-local)
    uv tool install ruff
    uv tool install yamllint

    # Other
    mise use -g cargo:selene  # Lua
    brew install shellcheck

### Formatters

    # npm
    mise use -g npm:prettier
    mise use -g npm:@fsouza/prettierd

    # pip/uv
    uv tool install beautysh
    uv tool install mdformat

    # go
    mise use -g go:github.com/golangci/golangci-lint/cmd/golangci-lint
    mise use -g go:github.com/segmentio/golines

    # Other
    mise use -g cargo:stylua
    mise use -g cargo:typos-cli
    brew install shfmt

Source: `lua/kyleking/deps/lsp.lua`, `lua/kyleking/deps/formatting.lua`

## Directory Layout

    lua/kyleking/core/      Core settings (options, keymaps, autocmds, lsp)
    lua/kyleking/deps/      Plugin configurations (one file per group)
    lua/kyleking/custom/    Custom utilities
    lua/kyleking/utils/     Shared helpers (fs, json, tool_resolve, noqa)
    lsp/                    Native LSP server configs (nvim 0.11+)
    lua/tests/              Test files (*_spec.lua)

## Conventions

- `local K = vim.keymap.set` alias used in deps files
- Autocmd groups prefixed with `kyleking_`
- Theme colors: `require("kyleking.theme").get_colors()`
- `PLANNED:` comments mark features to add when upstream support arrives
- Floating windows skipped in global autocmds via `relative ~= ""`

## Keymaps

All keymaps are discoverable at runtime:

    <leader>fk     Find keymaps (searchable picker of all active keymaps)

mini.clue shows available continuations after a 500ms delay on any prefix
key. See `kyleking-neovim-clue`.

Completion keymaps (built-in LSP completion, nvim 0.11+):

    <C-Space>       Trigger completion
    <C-j>           Next item in completion menu
    <C-k>           Previous item
    <C-CR>          Accept selected completion
    <CR>            Abort completion and insert newline

Source: `lua/kyleking/core/lsp.lua`

See also: `lsp-completion`, `ins-completion`

## Custom Commands

    :RunAllTests        Run all mini.test test files (floating window)
    :RunFailedTests     Run only failed tests from last run
    :PatchApply {file}  Apply patch from current buffer to {file}
    :DiffviewOpen       Open side-by-side git diff viewer
    :DiffviewClose      Close diffview

## Testing

Tests use mini.test with parallel workers for speed. Test files live in
`lua/tests/` and follow `*_spec.lua` naming. Commands and keymaps are only
available when cwd is the config directory.

### Interactive Commands

    <leader>ta              Run all tests (sequential, optimized)
    <leader>tf              Run failed tests from last run
    <leader>tp              Run tests in parallel (fastest, recommended)
    <leader>tr              Run tests in random order

    :RunAllTests            Sequential with optimizations (~20s)
    :RunFailedTests         Re-run only failed tests
    :RunTestsParallel       Parallel workers (~6-8s, 7-8x faster)
    :RunTestsRandom [seed]  Random order, detects dependencies
    :RunTestsParallelRandom [seed]  Parallel + random

### Command Line

Single test file (fastest, ~1-2 seconds):

    MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
      -c "lua MiniTest.run_file('lua/tests/custom/constants_spec.lua')" \
      -c "qall!"

Parallel execution (recommended, ~6-8 seconds):

    MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
      -c "lua require('kyleking.utils.test_runner').run_tests_parallel()" \
      -c "sleep 10" -c "qall!"

Sequential fallback (~20 seconds):

    MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
      -c "lua MiniTest.run()" -c "qall!"

Random order (detect test dependencies):

    MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
      -c "lua require('kyleking.utils.test_runner').run_all_tests(false, true, 12345)" \
      -c "qall!"

### Performance

`MINI_DEPS_LATER_AS_NOW=1` makes plugins load synchronously during tests,
reducing waits from 1000ms to 10ms. Parallel workers spawn N nvim instances
(auto-detects CPU cores), each running tests sequentially with state cleanup
between tests. All workers run concurrently.

Performance comparison:

    Original (async)        45+ seconds     1x
    Optimized (sync)        ~20 seconds     2.2x
    Parallel workers        ~6-8 seconds    7-8x

### Random Order

Like pytest-randomly, random test order detects test interdependencies and
state leakage. Use the seed argument to reproduce failures:

    :RunTestsRandom 12345

### Test File Pattern

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

Test results display in a floating window. Press `q` or `<Esc>` to close.
Failed tests are tracked for re-running with `:RunFailedTests`.

Source: `lua/kyleking/setup-deps.lua`, `lua/kyleking/utils/test_runner.lua`,
`lua/tests/helpers.lua`

See also: `MiniTest`, `TEST-PERFORMANCE-README.md`
