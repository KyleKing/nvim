# Regression Test Guide

Quick reference for adding tests when bugs are discovered. Tests should be added **before** fixing the bug (TDD approach).

## Decision Tree: Which Test Type?

```
Bug discovered
├─ In custom utility code (lua/kyleking/utils/*, find-relative-executable/)?
│  └─ Add test to lua/tests/custom/*_spec.lua
│
├─ In plugin keybinding behavior?
│  ├─ Simple keybinding (no <leader>, <C-...>)?
│  │  └─ Add test to lua/tests/docs/<plugin>.lua (fixture)
│  └─ Complex keybinding with special keys?
│     └─ Add test to lua/tests/plugins/*_spec.lua OR use API calls in fixture
│
├─ In LSP/linting/formatting workflow?
│  └─ Add test to lua/tests/integration/*_spec.lua
│
└─ In configuration (setting not applied, wrong value)?
   └─ Add config validation test to appropriate spec file
```

## Test Templates by Category

### 1. Custom Utility Functions (Tier 1 - High Priority)

**Location**: `lua/tests/custom/<module>_spec.lua`

**When**: Bug in code you wrote (utils/, find-relative-executable/)

**Template**:

```lua
local MiniTest = require("mini.test")
local module = require("kyleking.utils.<module_name>")

local T = MiniTest.new_set({ hooks = {} })

T["function_name"] = MiniTest.new_set()

T["function_name"]["reproduces bug #123"] = function()
    -- Setup: Create condition that triggers bug
    local input = "edge case that failed"

    -- Execute: Run the buggy function
    local result = module.function_name(input)

    -- Assert: Verify expected behavior (this will fail before fix)
    MiniTest.expect.equality(result, "expected output")
end

if ... == nil then MiniTest.run() end
return T
```

**Example** (fs_utils.lua bug):

```lua
T["find_git_root"]["handles symlinked directories"] = function()
    -- Bug: find_git_root failed when called from symlinked path
    local helpers = require("tests.helpers")
    local tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir .. "/repo/.git", "p")
    vim.fn.mkdir(tmpdir .. "/link-parent", "p")

    local link = tmpdir .. "/link-parent/link"
    vim.fn.system({"ln", "-s", tmpdir .. "/repo", link})

    local result = fs_utils.find_git_root(link .. "/nested/path")
    MiniTest.expect.equality(result, tmpdir .. "/repo")

    vim.fn.delete(tmpdir, "rf")
end
```

### 2. Plugin Keybinding Behavior (Tier 2)

**Location**: `lua/tests/docs/<plugin>.lua` (for simple keys) or `lua/tests/plugins/*_spec.lua` (for complex)

**When**: Plugin keybinding doesn't work as documented

**Template (Simple Keys - Doc Fixture)**:

```lua
-- Add to existing fixture's grammars array
{
    pattern = "pattern from docs",
    desc = "Short description",
    tests = {
        {
            name = "reproduces bug #456",
            before = { "content", "before" },
            cursor = { 1, 0 },
            keys = "keybinding",
            expect = { lines = { "expected", "output" } },
        },
    },
}
```

**Template (Complex Keys - API-based)**:

```lua
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({ hooks = {} })

T["plugin_command"]["reproduces bug #456"] = function()
    local bufnr = helpers.create_test_buffer({ "original content" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Execute via API (not feedkeys) when <leader> or <C-...> involved
    require("plugin").command()

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    MiniTest.expect.equality(lines, { "expected content" })

    helpers.delete_buffer(bufnr)
end
```

**Example** (mini.surround bug):

```lua
{
    name = "handles multi-line surrounding",  -- Bug: crashed on multi-line text
    before = { "line 1", "line 2", "line 3" },
    cursor = { 1, 0 },
    keys = "saip\"",  -- Surround around paragraph
    expect = {
        lines = { '"line 1"', '"line 2"', '"line 3"' },
    },
}
```

### 3. LSP/Linting/Formatting Integration (Tier 2)

**Location**: `lua/tests/integration/*_spec.lua`

**When**: LSP doesn't start, formatter not applied, linter not running

**Template**:

```lua
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({ hooks = {} })

T["lsp_feature"]["reproduces bug #789"] = function()
    -- Create buffer with filetype that should trigger LSP
    local bufnr = helpers.create_test_buffer({ "code here" }, "python")
    vim.api.nvim_set_current_buf(bufnr)

    -- Wait for LSP to attach
    vim.wait(2000, function()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        return #clients > 0
    end)

    -- Verify LSP attached
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    MiniTest.expect.equality(#clients > 0, true, "LSP should attach to Python files")

    helpers.delete_buffer(bufnr)
end
```

**Example** (formatting bug):

```lua
T["format_on_save"]["applies prettier to json"] = function()
    -- Bug: prettier not running on JSON files
    local bufnr = helpers.create_test_buffer({ '{"key":"value"}' }, "json")
    vim.api.nvim_buf_set_name(bufnr, "test.json")
    vim.api.nvim_set_current_buf(bufnr)

    -- Trigger format
    require("conform").format({ bufnr = bufnr })

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    -- Prettier should format with spaces
    MiniTest.expect.equality(lines[1]:match("^%s+"), "  ")

    helpers.delete_buffer(bufnr)
end
```

### 4. Configuration Validation (Tier 3)

**Location**: Appropriate `lua/tests/plugins/*_spec.lua` or `lua/tests/docs/<plugin>.lua`

**When**: Config option not set correctly, wrong default value

**Template**:

```lua
T["config"]["reproduces bug #101"] = function()
    local config = require("plugin").config

    -- Verify config value that was wrong
    MiniTest.expect.equality(config.option, expected_value)
end
```

**Example** (mini.ai config bug):

```lua
T["config"]["n_lines set to 500 for performance"] = function()
    -- Bug: default 50 caused freezes on large files
    local MiniAi = require("mini.ai")
    MiniTest.expect.equality(MiniAi.config.n_lines, 500)
end
```

## Quick Commands

```bash
# Run single test file during development
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/custom/my_spec.lua')" -c "qall!"

# Run with verbose output to see assertion details
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/custom/my_spec.lua', {verbose=true})" -c "qall!"

# Update doc fixture snapshots if using snapshot testing
UPDATE_SNAPSHOTS=1 MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"
```

## Test Helpers Reference

Available in `lua/tests/helpers.lua`:

### Buffer Management

```lua
-- Create test buffer
local bufnr = helpers.create_test_buffer({"line1", "line2"}, "lua")

-- Delete buffer when done
helpers.delete_buffer(bufnr)

-- Full cleanup (buffers, autocmds, etc)
helpers.full_cleanup()
```

### Keymap Testing

```lua
-- Check if keymap exists and matches expected function
helpers.check_keymap("n", "<leader>ff", "pick.builtin.files")
```

### Plugin Loading

```lua
-- Check if plugin loaded (avoid this, prefer behavioral tests)
local loaded = helpers.is_plugin_loaded("mini.surround")
```

### Nvim Interaction

```lua
-- Run commands in test context
helpers.nvim_interaction_test(function()
    vim.cmd("edit test.lua")
    -- assertions here
end)
```

## Common Pitfalls

### ❌ Don't: Test existence only

```lua
-- Bad: only checks if function exists
MiniTest.expect.equality(type(plugin.func), "function")
```

### ✅ Do: Test behavior

```lua
-- Good: checks what function does
local result = plugin.func(input)
MiniTest.expect.equality(result, expected_output)
```

### ❌ Don't: Use feedkeys for <leader> keys

```lua
-- Bad: feedkeys doesn't process special keys correctly
vim.api.nvim_feedkeys("<leader>ff", "n", false)
```

### ✅ Do: Call API directly

```lua
-- Good: call the function directly
require("mini.pick").builtin.files()
```

### ❌ Don't: Forget cleanup

```lua
-- Bad: leaves test buffers around
local bufnr = vim.api.nvim_create_buf(false, true)
-- test code...
-- missing: helpers.delete_buffer(bufnr)
```

### ✅ Do: Always cleanup

```lua
-- Good: cleanup after test
local bufnr = helpers.create_test_buffer({"test"}, "lua")
-- test code...
helpers.delete_buffer(bufnr)
```

## Test Organization

```
lua/tests/
├── custom/           # Tier 1: Custom code (highest value)
│   ├── *_spec.lua    # One file per module
│   └── helpers.lua   # Test utilities
├── plugins/          # Tier 2: Plugin config behavior
│   └── *_spec.lua    # Grouped by functionality
├── integration/      # Tier 2: Workflow tests
│   └── *_spec.lua    # LSP, formatting, linting
├── docs/             # Documentation-driven tests
│   ├── *.lua         # Fixtures (tests + docs)
│   └── *.snap        # Snapshot files
├── core/             # Core functionality
│   └── smoke_spec.lua # Startup validation
└── ui/               # UI components
    └── *_spec.lua    # Statusline, picker, etc
```

## Coverage Tracking

```bash
# Run tests with coverage for custom modules
./scripts/run_tests_with_coverage.sh custom

# View coverage report
cat .luacov.report.out | grep "kyleking/utils"

# Target: >80% coverage for custom modules
```

## Workflow: Bug → Test → Fix

1. **Reproduce**: Understand the bug and how to trigger it
1. **Write Test**: Add failing test that reproduces the bug
1. **Verify Failure**: Run test, confirm it fails
1. **Fix Bug**: Implement the fix
1. **Verify Pass**: Run test, confirm it passes
1. **Add Edge Cases**: Add related edge case tests
1. **Run Full Suite**: Ensure no regressions

```bash
# Step 3: Verify test fails
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/custom/my_spec.lua')" -c "qall!"
# Expected: test should fail

# (implement fix in code)

# Step 5: Verify test passes
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/custom/my_spec.lua')" -c "qall!"
# Expected: test should pass

# Step 7: Run full suite
MINI_DEPS_LATER_AS_NOW=1 nvim --headless -c "lua require('kyleking.utils.test_runner').run_tests_parallel()" -c "sleep 10" -c "qall!"
# Expected: all tests pass
```

## References

- Test architecture: `ACTUALLY_GOOD_TESTS.md`
- Test helpers: `lua/tests/helpers.lua`
- Existing examples: Browse `lua/tests/` for patterns
- Mini.test docs: `:help mini.test`
