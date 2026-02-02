# Test Suite Documentation

Comprehensive test suite for nvim configuration using mini.test.

## Directory Structure

```
tests/
├── helpers.lua              # Test utility functions
├── core/                    # Core nvim functionality tests
│   └── smoke_spec.lua       # Infrastructure smoke tests
├── plugins/                 # Plugin-specific tests
├── custom/                  # Custom utilities tests
├── integration/             # Integration workflow tests
└── ui/                      # UI component tests
```

## Running Tests

### From within nvim (when cwd is config directory)

```vim
:RunAllTests        " Run all tests
:RunFailedTests     " Run only failed tests from last run

<leader>ta          " Run all tests
<leader>tf          " Run failed tests
```

### From command line

```bash
# Run all tests
nvim --headless -c "lua MiniTest.run()" -c "qall!"

# Run specific test file
nvim --headless -c "lua MiniTest.run_file('lua/tests/core/smoke_spec.lua')" -c "qall!"
```

## Test Helpers

### LSP Testing

- `wait_for_lsp_attach(bufnr, timeout_ms)` - Wait for LSP to attach to buffer
- `get_lsp_client_by_name(bufnr, name)` - Find LSP client by name

### Buffer Management

- `create_test_buffer(lines, filetype)` - Create temporary test buffer
- `delete_buffer(bufnr)` - Clean up buffer

### Async Utilities

- `wait_for_condition(fn, timeout_ms, interval_ms)` - Wait for condition
- `wait_for_autocmd(event, pattern, timeout_ms)` - Wait for autocmd registration

### Keymap Testing

- `check_keymap(lhs, mode, expected_desc)` - Verify keymap exists and matches description

### File Management

- `create_temp_file(content, extension)` - Create temporary file
- `cleanup_temp_file(filepath)` - Delete temporary file

### Diagnostics

- `get_diagnostic_count(bufnr, severity)` - Get diagnostic count for buffer

### Plugin Management

- `is_plugin_loaded(plugin_name)` - Check if plugin is loaded
- `reload_module(module_name)` - Clear module from package cache

## Writing Tests

### Basic Test Structure

```lua
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Setup before each test
        end,
        post_case = function()
            -- Cleanup after each test
        end,
    },
})

T["feature group"] = MiniTest.new_set()

T["feature group"]["test case"] = function()
    -- Arrange
    local bufnr = helpers.create_test_buffer({"line 1"}, "lua")

    -- Act
    vim.cmd("normal! i-- comment")

    -- Assert
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    MiniTest.expect.equality(line, "-- comment")

    -- Cleanup
    helpers.delete_buffer(bufnr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
```

### Test Naming Convention

- Test files: `*_spec.lua`
- Test sets: Descriptive names using spaces
- Test cases: Action-oriented descriptions

### Best Practices

1. **Cleanup**: Always clean up resources (buffers, temp files, keymaps)
1. **Isolation**: Each test should be independent
1. **Helpers**: Use helpers for common operations
1. **Async**: Use `wait_for_*` helpers for async operations
1. **LSP**: Wait for LSP attachment before testing LSP features

## Coverage Goals

- **Core**: LSP, diagnostics, keymaps, autocmds (~150 tests)
- **Plugins**: All mini.\* and third-party plugins (~200 tests)
- **Custom**: Utils, fs_utils, bin_discovery (~40 tests)
- **Integration**: Complete workflows (~50 tests)
- **Total**: ~440 tests
