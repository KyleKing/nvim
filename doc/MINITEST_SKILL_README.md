# Mini.Test Claude Skill

A comprehensive Claude Skill for working with [Mini.Test](https://github.com/nvim-mini/mini.test), a powerful Neovim testing framework.

## Files

- **`minitest-claude-skill.json`** - The Claude Skill schema definition
- **`minitest-claude-skill-guide.md`** - Comprehensive implementation guide with examples
- **`claude-skills-guide.md`** - General guide on building Claude Skills

## Quick Start

### Using the Skill

The skill supports 8 different actions:

1. **`generate_test_file`** - Generate a complete test file
2. **`create_test_case`** - Create individual test cases
3. **`explain_api`** - Get API documentation
4. **`generate_expectation`** - Generate expectation code
5. **`create_hooks`** - Create test hooks
6. **`create_parametrized_test`** - Create parametrized tests
7. **`create_child_neovim_test`** - Create isolated tests
8. **`run_test_example`** - Get examples of running tests

### Example Usage

```json
{
  "action": "generate_test_file",
  "module_name": "kyleking.deps.color",
  "file_path": "color_spec.lua",
  "test_cases": [
    {
      "name": "initialization",
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

## Skill Features

- ✅ Generates properly structured Mini.Test files
- ✅ Understands your project structure (`lua/kyleking/deps/*`)
- ✅ Follows your existing test patterns
- ✅ Supports all Mini.Test features (hooks, parametrization, child Neovim)
- ✅ Provides comprehensive API documentation
- ✅ Includes best practices and common patterns

## Mini.Test Quick Reference

### Basic Test Structure

```lua
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
        post_case = function() end,
    },
})

T["module_name"] = MiniTest.new_set()
T["module_name"].test_name = function()
    MiniTest.expect.equality(1 + 1, 2, "Math works")
end

if ... == nil then MiniTest.run() end
return T
```

### Common Expectations

- `MiniTest.expect.equality(actual, expected, message)`
- `MiniTest.expect.no_equality(actual, expected, message)`
- `MiniTest.expect.error(f, message)`
- `MiniTest.expect.no_error(f, message)`
- `MiniTest.expect.truthy(value, message)`
- `MiniTest.expect.falsy(value, message)`

### Running Tests

- `:RunAllTests` - Run all tests
- `:RunFailedTests` - Run only failed tests
- `<leader>ta` - Keymap for all tests
- `<leader>tf` - Keymap for failed tests

## Documentation

For detailed information, see:
- [Implementation Guide](minitest-claude-skill-guide.md) - Complete guide with examples
- [Claude Skills Guide](claude-skills-guide.md) - General Claude Skills documentation
- [Mini.Test GitHub](https://github.com/nvim-mini/mini.test) - Official repository
- [Mini.Test Docs](https://nvim-mini.org/mini.nvim/doc/mini-test) - Official documentation

## Integration

This skill is designed to work with your existing Neovim configuration:

- Test files: `lua/tests/*_spec.lua`
- Test runner: Configured in `lua/kyleking/setup-deps.lua`
- Module structure: `lua/kyleking/deps/*`

The skill understands your conventions and generates code that matches your existing test files (`color_spec.lua`, `terminal_integration_spec.lua`).

## Contributing

To improve this skill:

1. Update `minitest-claude-skill.json` to add new actions or parameters
2. Add examples to `minitest-claude-skill-guide.md`
3. Test with actual Mini.Test usage patterns

## License

This skill follows the same license as your Neovim configuration.
