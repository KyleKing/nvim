# Mini.Test Claude Skill Implementation Guide

## Overview

This Claude Skill provides comprehensive assistance for working with [Mini.Test](https://github.com/nvim-mini/mini.test), a powerful Neovim testing framework. The skill helps you generate test files, understand the Mini.Test API, create properly structured test cases, and use expectations and hooks correctly.

## Skill Schema

The skill is defined in `minitest-claude-skill.json` and supports the following actions:

### Available Actions

1. **`generate_test_file`** - Generate a complete test file with proper structure
2. **`create_test_case`** - Create individual test cases with expectations
3. **`explain_api`** - Explain Mini.Test API functions and usage
4. **`generate_expectation`** - Generate expectation code snippets
5. **`create_hooks`** - Create test hooks (pre_once, pre_case, post_case, post_once)
6. **`create_parametrized_test`** - Create parametrized test cases
7. **`create_child_neovim_test`** - Create tests using child Neovim processes
8. **`run_test_example`** - Generate examples of running tests

## Mini.Test API Reference

### Core Functions

#### `MiniTest.new_set(opts, tbl)`
Creates a hierarchical test set. This is the fundamental building block of Mini.Test.

```lua
local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Setup before each test
        end,
        post_case = function()
            -- Cleanup after each test
        end,
    },
    parametrize = { { 1 }, { 2 } }, -- Test with different parameters
    data = { custom_data = "value" }, -- User data for filtering
    n_retry = 1, -- Number of retries
})
```

#### `MiniTest.expect.*`
Predefined expectation functions:

- `MiniTest.expect.equality(actual, expected, message)` - Assert equality
- `MiniTest.expect.no_equality(actual, expected, message)` - Assert inequality
- `MiniTest.expect.error(f, message)` - Assert function throws error
- `MiniTest.expect.no_error(f, message)` - Assert function doesn't throw
- `MiniTest.expect.truthy(value, message)` - Assert value is truthy
- `MiniTest.expect.falsy(value, message)` - Assert value is falsy
- `MiniTest.expect.reference_screenshot(child, name)` - Compare screenshots

#### `MiniTest.run_file(file, opts)`
Run tests from a specific file:

```lua
MiniTest.run_file("lua/tests/color_spec.lua", { verbose = true })
```

#### `MiniTest.run_at_location(location, opts)`
Run tests at a specific location (cursor position):

```lua
MiniTest.run_at_location({ file = "lua/tests/color_spec.lua", line = 20 })
```

#### `MiniTest.new_child_neovim(opts)`
Create an isolated child Neovim process for testing:

```lua
local child = MiniTest.new_child_neovim({
    init = function()
        -- Child Neovim initialization
        require("mini.test").setup()
    end,
})
```

### Test Case Structure

A test case is created when you define a callable entry in a test set:

```lua
T["test name"] = function()
    -- Test code here
    MiniTest.expect.equality(1 + 1, 2, "Math should work")
end
```

### Hooks

Hooks allow you to run code at different stages:

- **`pre_once`** - Before first filtered node
- **`pre_case`** - Before each test case
- **`post_case`** - After each test case
- **`post_once`** - After last filtered node

## Usage Examples

### Example 1: Generate a Basic Test File

**Request:**
```json
{
  "action": "generate_test_file",
  "module_name": "kyleking.deps.color",
  "file_path": "color_spec.lua",
  "test_cases": [
    {
      "name": "initialization",
      "description": "Verify module initializes correctly",
      "expectations": [
        {
          "type": "equality",
          "actual": "package.loaded.ccc ~= nil",
          "expected": "true",
          "message": "CCC plugin should be loaded"
        }
      ]
    }
  ]
}
```

**Generated Output:**
```lua
-- Test file for color.lua using Mini.test
local MiniTest = require("mini.test")

-- Define a new test set properly
local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Do any setup before each test case
        end,
        post_once = function()
            -- Clean up after all tests
        end,
    },
})

-- Test case for the color module initialization
T["color module"] = MiniTest.new_set()

T["color module"].initialization = function()
    -- Load the module
    require("kyleking.deps.color")

    -- Check that CCC is loaded
    MiniTest.expect.equality(package.loaded.ccc ~= nil, true, "CCC plugin should be loaded")
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

-- Return the test set for discovery by the test runner
return T
```

### Example 2: Create Parametrized Tests

**Request:**
```json
{
  "action": "create_parametrized_test",
  "module_name": "kyleking.deps.color",
  "parametrize": [
    ["#FF0000", "red"],
    ["#00FF00", "green"],
    ["#0000FF", "blue"]
  ],
  "test_cases": [
    {
      "name": "color_conversion",
      "description": "Test color conversion for different colors",
      "expectations": [
        {
          "type": "equality",
          "actual": "converted_color",
          "expected": "param[2]",
          "message": "Color should convert correctly"
        }
      ]
    }
  ]
}
```

**Generated Output:**
```lua
T["color module"]["color_conversion"] = MiniTest.new_set({
    parametrize = { { "#FF0000", "red" }, { "#00FF00", "green" }, { "#0000FF", "blue" } },
})

T["color module"]["color_conversion"].test = function(color_code, color_name)
    local converted_color = convert_color(color_code)
    MiniTest.expect.equality(converted_color, color_name, "Color should convert correctly")
end
```

### Example 3: Create Tests with Hooks

**Request:**
```json
{
  "action": "create_hooks",
  "hooks": {
    "pre_case": "package.loaded['kyleking.deps.terminal-integration'] = nil",
    "post_case": "-- Cleanup after each test"
  },
  "test_cases": [
    {
      "name": "terminal_initialization",
      "description": "Test terminal module initialization",
      "expectations": [
        {
          "type": "equality",
          "actual": "package.loaded.toggleterm ~= nil",
          "expected": "true",
          "message": "toggleterm plugin should be loaded"
        }
      ]
    }
  ]
}
```

**Generated Output:**
```lua
local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Reset the module before each test
            package.loaded["kyleking.deps.terminal-integration"] = nil
        end,
        post_case = function()
            -- Cleanup after each test
        end,
    },
})

T["terminal_integration module"] = MiniTest.new_set()

T["terminal_integration module"].terminal_initialization = function()
    -- Load the module
    require("kyleking.deps.terminal-integration")

    -- Check that toggleterm is loaded
    MiniTest.expect.equality(package.loaded.toggleterm ~= nil, true, "toggleterm plugin should be loaded")
end
```

### Example 4: Create Child Neovim Test

**Request:**
```json
{
  "action": "create_child_neovim_test",
  "module_name": "kyleking.deps.color",
  "test_description": "Test color highlighting in isolated Neovim instance",
  "use_child_neovim": true
}
```

**Generated Output:**
```lua
T["color module"].highlighting = function()
    -- Create a child Neovim process for isolation
    local child = MiniTest.new_child_neovim({
        init = function()
            -- Initialize child Neovim
            require("mini.test").setup()
            require("kyleking.deps.color")
        end,
    })

    -- Create a temporary buffer with sample color codes
    child.lua([[
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "Color examples:",
            "#FF0000 - Red",
            "#00FF00 - Green",
            "#0000FF - Blue",
        })
        vim.api.nvim_set_current_buf(bufnr)
        vim.cmd("CccHighlighterEnable")
    ]])

    -- Allow some time for highlighting
    child.sleep(100)

    -- Verify highlighting exists
    local ns = child.lua_get("vim.api.nvim_get_namespaces()['ccc.nvim']")
    MiniTest.expect.equality(ns ~= nil, true, "CCC.nvim namespace should exist")

    -- Clean up
    child.stop()
end
```

### Example 5: Explain API Function

**Request:**
```json
{
  "action": "explain_api",
  "api_function": "new_set"
}
```

**Generated Output:**
```
MiniTest.new_set(opts, tbl) creates a hierarchical test set.

Parameters:
- opts (table|nil): Options including:
  - hooks: Table with pre_once, pre_case, post_case, post_once functions
  - parametrize: Array of parameter arrays for parametrized tests
  - data: User data forwarded to test cases
  - n_retry: Number of retries (default: 1)
- tbl (table|nil): Initial test items

Returns: A test set table

Usage:
local T = MiniTest.new_set({
    hooks = { pre_case = function() end },
    parametrize = { { 1 }, { 2 } },
})
T["test"] = function(x) MiniTest.expect.equality(x, x) end
```

## Best Practices

### 1. Test File Structure

- Place test files in `lua/tests/` directory
- Name files with `*_spec.lua` pattern (e.g., `color_spec.lua`)
- Always return the test set at the end: `return T`
- Include `if ... == nil then MiniTest.run() end` for manual execution

### 2. Test Organization

- Use hierarchical test sets to organize related tests
- Group tests by module or feature
- Use descriptive names for test cases

### 3. Expectations

- Always provide meaningful messages in expectations
- Use appropriate expectation types
- Test both positive and negative cases

### 4. Hooks

- Use `pre_case` for setup that needs to run before each test
- Use `post_case` for cleanup after each test
- Use `pre_once`/`post_once` for expensive setup/teardown

### 5. Isolation

- Use child Neovim processes for tests that modify global state
- Reset module state in `pre_case` hooks when needed
- Clean up resources in `post_case` hooks

### 6. Parametrization

- Use parametrization to test multiple scenarios
- Keep parameter arrays readable
- Document what each parameter represents

## Common Patterns

### Testing Module Initialization

```lua
T["module_name"].initialization = function()
    require("module.name")
    MiniTest.expect.equality(package.loaded["module.name"] ~= nil, true, "Module should be loaded")
end
```

### Testing Keymaps

```lua
T["module_name"].keymaps = function()
    require("module.name")
    local keymap = vim.fn.maparg("<leader>xx", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "Keymap should exist")
    if keymap then
        MiniTest.expect.equality(keymap.desc, "Description", "Description should match")
    end
end
```

### Testing Autocommands

```lua
T["module_name"].autocmds = function()
    require("module.name")
    local found = false
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ pattern = "*" })) do
        if autocmd.desc == "Expected description" then
            found = true
            break
        end
    end
    MiniTest.expect.equality(found, true, "Autocmd should exist")
end
```

### Testing with Mocks

```lua
T["module_name"].with_mock = function()
    -- Save original
    local original_func = package.loaded["plugin"].func
    
    -- Create mock
    package.loaded["plugin"].func = function()
        return "mocked_value"
    end
    
    -- Test
    require("module.name")
    -- ... test code ...
    
    -- Restore original
    package.loaded["plugin"].func = original_func
end
```

## Running Tests

### From Command Line

```bash
nvim --headless -c "lua require('mini.test').run()" -c "qa"
```

### From Neovim

```lua
-- Run all tests
MiniTest.run()

-- Run specific file
MiniTest.run_file("lua/tests/color_spec.lua")

-- Run test at cursor
MiniTest.run_at_location()
```

### Using Custom Commands

Based on your setup in `setup-deps.lua`:

- `:RunAllTests` - Run all test files
- `:RunFailedTests` - Run only failed tests from last run
- `<leader>ta` - Keymap to run all tests
- `<leader>tf` - Keymap to run failed tests

## Troubleshooting

### Tests Not Running

- Ensure `require("mini.test").setup()` is called
- Check that test files return a test set
- Verify file naming matches `find_files` pattern

### Module Not Loading in Tests

- Clear package cache: `package.loaded["module.name"] = nil`
- Use `pre_case` hook to reset state
- Ensure module path is correct

### Expectations Failing

- Check actual vs expected values
- Verify types match (use `tostring()` if needed)
- Add debug output with `MiniTest.add_note()`

### Child Neovim Issues

- Ensure child process is properly initialized
- Use `child.sleep()` for async operations
- Call `child.stop()` to clean up

## Resources

- [Mini.Test GitHub](https://github.com/nvim-mini/mini.test)
- [Mini.Test Documentation](https://nvim-mini.org/mini.nvim/doc/mini-test)
- [Testing Guide](https://nvim-mini.org/mini.nvim/TESTING)
- [Mini.nvim Tests](https://github.com/nvim-mini/mini.nvim/tree/main/tests) - Examples

## Skill Implementation Notes

This skill is designed to be used with Claude's tool calling capabilities. When Claude needs to help with Mini.Test:

1. It can call the skill with appropriate parameters
2. The skill generates proper Lua code following Mini.Test patterns
3. Code follows the existing codebase conventions
4. Output includes proper error handling and best practices

The skill understands:
- Your project structure (`lua/kyleking/deps/*`)
- Your test file naming (`*_spec.lua`)
- Your existing test patterns (from `color_spec.lua` and `terminal_integration_spec.lua`)
- Your test runner setup (from `setup-deps.lua`)
