# Neovim Configuration Test Suite

Comprehensive test suite for the nvim configuration using MiniTest.

## Overview

This test suite validates all configured plugins and features work correctly, including:

- **LSP Features**: Completion, go-to-definition, diagnostics, formatting
- **mini.nvim Plugins**: pick, statusline, comment, ai, icons, files, move, surround, trailspace
- **External Plugins**: conform, gitsigns, treesitter, trouble, toggleterm, etc.
- **Integration Tests**: End-to-end workflows combining multiple features

## Test Files

### Core Tests

- **`helpers.lua`**: Reusable test utilities and helper functions (DRY)
- **`lsp_spec.lua`**: LSP configuration, completion, keymaps, diagnostics, navigation
- **`mini_pick_spec.lua`**: Fuzzy finding, file navigation, picker features
- **`mini_statusline_spec.lua`**: Statusline configuration, sections, icons integration
- **`mini_comment_spec.lua`**: Commenting functionality across filetypes
- **`mini_ai_spec.lua`**: Text objects, a/i operations, operators
- **`plugins_spec.lua`**: Other configured plugins (formatting, git, terminal, etc.)
- **`integration_spec.lua`**: High-level coding workflows

### Existing Tests

- **`color_spec.lua`**: Color highlighting functionality
- **`terminal_integration_spec.lua`**: Terminal integration and toggleterm

## Running Tests

### From Neovim

The configuration includes built-in test runners accessible via the command line when in the config directory:

```vim
" Run all tests
:lua require('mini.test').run()

" Run specific test file
:lua require('mini.test').run_file('lua/tests/lsp_spec.lua')
```

### Manual Execution

Run individual test files directly:

```bash
nvim -l lua/tests/lsp_spec.lua
```

### Using Test Keymaps

If you're in the nvim config directory (`~/.config/nvim`), the setup includes custom test commands that run automatically.

## Test Structure

All tests follow MiniTest conventions:

```lua
local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() -- Setup before each test
        end,
        post_once = function() -- Cleanup after all tests
        end,
    },
})

T["test category"]["test name"] = function()
    -- Test implementation using helpers
    H.assert_equals(actual, expected, "Error message")
end

return T
```

## Helper Functions

The `helpers.lua` module provides reusable utilities:

### Buffer Management
- `create_test_buffer(lines, filetype)` - Create temporary buffer
- `delete_buffer(bufnr)` - Clean up buffer
- `set_buffer_content(bufnr, lines, cursor)` - Set buffer content
- `get_buffer_content(bufnr)` - Get buffer lines

### File Operations
- `create_temp_file(content, extension)` - Create temporary file
- `delete_temp_path(path)` - Delete file or directory
- `with_buffer(test_fn, lines, filetype)` - Run test with auto-cleanup
- `with_temp_file(test_fn, content, extension)` - Run test with temp file

### Testing Utilities
- `check_keymap(mode, lhs, expected_desc)` - Verify keymap exists
- `wait_for(condition, timeout_ms, interval_ms)` - Wait for condition
- `wait_for_lsp(bufnr, timeout_ms)` - Wait for LSP attachment
- `check_autocmd(event, pattern, callback_check)` - Verify autocmd
- `is_plugin_loaded(plugin_name)` - Check if plugin loaded
- `feed_keys(keys)` - Execute keys in normal mode

### Assertions
- `assert_equals(actual, expected, msg)` - Assert equality
- `assert_true(condition, msg)` - Assert true
- `assert_false(condition, msg)` - Assert false
- `assert_contains(tbl, value, msg)` - Assert table contains value
- `assert_not_nil(value, msg)` - Assert value is not nil

## Test Coverage

### LSP Features ✓
- Built-in completion enabled
- Root markers configured
- Language servers enabled (gopls, lua_ls, pyright, ts_ls)
- Custom keymaps set on LspAttach
- Diagnostics integration
- LSP navigation functions
- Signature help plugin
- nvim-lint integration
- Trouble integration

### mini.pick ✓
- Module loads and configures
- Builtin pickers available (buffers, files, grep, help, etc.)
- Custom movement keys (Ctrl-j/k)
- Keymaps for file/buffer navigation
- LSP navigation keymaps
- Visual grep functionality
- Trouble integration for diagnostics

### mini.statusline ✓
- Module loads with custom configuration
- All sections work (mode, git, diagnostics, filename, etc.)
- Icons integration via mini.icons
- Lint progress integration
- Custom active content function
- vim-illuminate integration

### mini.comment ✓
- Comment/uncomment functionality
- Multiple filetypes (Lua, Python, JavaScript, etc.)
- Visual mode commenting
- Operators (gc with motions)
- Correct commentstring for each filetype
- Replaces ts-comments.nvim

### mini.ai ✓
- Enhanced text objects
- Standard objects (words, parentheses, brackets, quotes)
- Around (a) vs inside (i) behavior
- Works without treesitter
- Compatible with operators (delete, change, yank)
- Nested structures support
- Multi-line text objects

### Other Plugins ✓
- mini.files, mini.deps, mini.move, mini.surround, mini.trailspace
- conform.nvim (formatting)
- gitsigns.nvim (git integration)
- nvim-treesitter
- which-key.nvim
- flash.nvim (motion)
- todo-comments.nvim
- toggleterm.nvim
- And more...

### Integration Tests ✓
- Complete Lua/Python development workflows
- LSP + formatting integration
- LSP + diagnostics + Trouble workflow
- Buffer and file navigation
- Git integration
- Terminal integration
- Text manipulation workflows
- Statusline integration
- Search and navigation
- UI and color themes
- Help and keybinding discovery

## Best Practices

### DRY (Don't Repeat Yourself)
- All common operations extracted to `helpers.lua`
- Reusable test patterns for similar tests
- Parameterized tests where applicable

### Maintainability
- Clear test names describing what is tested
- Consistent structure across all test files
- Good separation between setup, test, and cleanup
- Comprehensive comments

### Performance
- Lazy loading of plugins in hooks
- Proper cleanup to avoid memory leaks
- Efficient use of wait conditions
- Tests run independently

### Configurability
- Timeout values can be adjusted
- Test helpers accept optional parameters
- Easy to extend with new test cases

## Adding New Tests

1. Create a new test file in `lua/tests/`
2. Use the standard MiniTest structure
3. Import and use helpers from `helpers.lua`
4. Add appropriate hooks for setup/cleanup
5. Return the test set at the end
6. Update this README with coverage information

## Troubleshooting

### Tests Fail Due to Missing LSP
Some tests require language servers (lua_ls, pyright, etc.) to be installed. Install them:

```bash
# Using Mason or your preferred method
:Mason
```

### Tests Timeout
Increase timeout values in `helpers.lua` or individual tests if your system is slow.

### Plugin Not Loaded
Ensure the plugin is configured correctly in the deps files and that mini.deps successfully installed it.

## Notes

- Tests are designed to run in a clean neovim instance
- Some tests may behave differently if LSP servers are not installed
- Visual mode tests use key simulation which may behave differently in headless mode
- Integration tests validate workflows work together, not exhaustive testing of each feature
