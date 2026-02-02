# Keymap nil Error Fixes - Complete Resolution

## Issue
**Error:** `vim/keymap.lua:0: rhs: expected string|function, got nil`

**Root Cause:** Keymaps referenced plugin module functions directly instead of wrapping them in anonymous functions. When the keymap was set during plugin loading, the function might not exist yet, causing nil to be passed as the rhs (right-hand side).

## All Files Fixed

### Round 1: Initial Fixes
1. **lua/kyleking/deps/bars-and-lines.lua** (lines 15-16)
   - `require("illuminate").toggle` → `function() require("illuminate").toggle() end`
   - `require("illuminate").toggle_buf` → `function() require("illuminate").toggle_buf() end`

2. **lua/kyleking/deps/buffer.lua** (lines 14-17)
   - `require("bufjump").forward` → `function() require("bufjump").forward() end`
   - `require("bufjump").backward` → `function() require("bufjump").backward() end`
   - `require("bufjump").forward_same_buf` → `function() require("bufjump").forward_same_buf() end`
   - `require("bufjump").backward_same_buf` → `function() require("bufjump").backward_same_buf() end`

3. **lua/kyleking/deps/motion.lua** (lines 21-22, 25)
   - `require("flash").jump` → `function() require("flash").jump() end`
   - `require("flash").treesitter` → `function() require("flash").treesitter() end`
   - `require("flash").toggle` → `function() require("flash").toggle() end`

### Round 2: Remaining Fixes
4. **lua/kyleking/deps/lsp.lua** (line 116)
   - `require("lint").try_lint` → `function() require("lint").try_lint() end`

5. **lua/kyleking/deps/git.lua** (line 12)
   - `require("gitsigns").toggle_deleted` → `function() require("gitsigns").toggle_deleted() end`

## Pattern

**Broken Pattern:**
```lua
vim.keymap.set("n", "<leader>key", require("plugin").function_name, { desc = "..." })
-- OR
K("n", "<leader>key", require("plugin").function_name, { desc = "..." })
```

**Fixed Pattern:**
```lua
vim.keymap.set("n", "<leader>key", function() require("plugin").function_name() end, { desc = "..." })
-- OR
K("n", "<leader>key", function() require("plugin").function_name() end, { desc = "..." })
```

## Why This Works

**Direct Reference (BROKEN):**
- Evaluates `require("plugin").function_name` when the keymap is SET
- If plugin isn't fully loaded, function doesn't exist → nil
- Keymap set with `rhs = nil` → ERROR

**Function Wrapper (FIXED):**
- Stores anonymous function as keymap rhs when keymap is SET
- Function contains the require() and function call
- When keymap is TRIGGERED, function executes and calls plugin function
- Plugin is fully loaded by the time user triggers keymap → SUCCESS

## Test Coverage

All fixed keymaps are now validated by tests:
- `tests/plugins/motion_spec.lua` - validates flash, illuminate, bufjump keymaps
- `tests/plugins/git_spec.lua` - validates gitsigns keymap
- `tests/plugins/lsp_plugins_spec.lua` - validates lint keymap

Tests verify:
1. Keymap exists (`keymap.lhs ~= nil`)
2. Keymap has callable rhs (`type(keymap.callback) == "function"`)

## Verification

```bash
# No startup errors
nvim --headless +'echo ""' +qa

# All tests pass
nvim --headless -c "lua MiniTest.run()" -c "q"

# Check specific keymaps work
nvim -c "verbose nmap <leader>ur"  # illuminate
nvim -c "verbose nmap <leader>bn"  # bufjump
nvim -c "verbose nmap <a-s>"       # flash
nvim -c "verbose nmap <leader>ll"  # lint
nvim -c "verbose nmap <leader>ugd" # gitsigns
```

## Prevention

Tests now validate ALL keymaps have callable functions, preventing this issue in future:
```lua
local has_callable = (type(keymap.callback) == "function")
    or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
MiniTest.expect.equality(has_callable, true, "Keymap should have callable rhs")
```

## Commits

1. `0f6db96` - fix: wrap plugin functions in keymaps to prevent nil errors (Round 1)
2. `add78ca` - fix: wrap remaining plugin functions in keymaps (Round 2)
3. Latest - test: add keymap validation for lint and gitsigns

## Status

**RESOLVED** - All instances fixed and tested.
