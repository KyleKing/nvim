# patch_it.nvim Usage Guide

## Overview

patch_it.nvim applies LLM-generated patches with fuzzy matching, ideal for integrating code suggestions from AI tools.

**Configuration:** `lua/kyleking/deps/utility.lua:39-59`

## Keybindings

| Key           | Action                | Description                                             |
| ------------- | --------------------- | ------------------------------------------------------- |
| `<leader>paa` | Apply patch           | Prompts for target file, applies buffer as patch        |
| `<leader>pap` | Preview patch         | Dry-run mode - shows what would change without applying |
| `<leader>pab` | Apply with suggestion | Auto-suggests target file based on buffer name          |

## Typical Workflow

### 1. Get LLM-Generated Patch

From Claude, Code Rabbit, or other AI tools:

```diff
function calculate_total(items)
-    return sum(items)
+    return sum(items) + tax
end
```

### 2. Copy to Neovim Buffer

1. Create new buffer: `:enew`
1. Paste patch content
1. No need to save

### 3. Apply Patch

**Option A: Manual target selection**

- Press `<leader>paa`
- Enter target file path: `src/calculator.lua`
- Patch applied with fuzzy matching

**Option B: Preview first (recommended)**

- Press `<leader>pap`
- Enter target file path
- Review changes, then use `<leader>paa` if satisfied

**Option C: Auto-suggest target**

- Name buffer matching target: `:file calculator.lua`
- Press `<leader>pab`
- Confirms suggested target automatically

### 4. Verify & Undo if Needed

- Review applied changes
- Undo with `u` if incorrect (standard Vim undo)

## Features

### Fuzzy Matching

Tolerates whitespace differences between patch context and actual file:

```diff
# Patch has extra spaces
-    def    foo():

# Still matches actual file
-  def foo():
```

### Forgiving Format

Accepts patches with or without space-prefixed context lines:

```diff
# Standard format (with spaces)
 def foo():
-    return 1
+    return 2

# Also works (without spaces)
def foo():
-    return 1
+    return 2
```

### Interleaved Changes

Handles additions and removals in any order within a hunk.

## Command-Line Alternative

```vim
:PatchApply path/to/target.lua
```

## Lua API

```lua
local patch_it = require("patch_it")

-- Apply directly from string
patch_it.apply(patch_string, "target.lua")

-- Apply from buffer
patch_it.apply_buffer("target.lua")

-- Preview mode
patch_it.apply_buffer("target.lua", { preview = true })
```

## Limitations

- **Single hunk, single file** per patch
- Files with literal `+` or `-` at line start need proper context formatting
- No multi-file diff support (apply patches one at a time)

## Troubleshooting

### Patch fails to apply

**Cause:** Context doesn't match target file

**Solutions:**

1. Use `<leader>pap` (preview) to see matching issues
1. Ensure patch context is from the actual file
1. Check whitespace in patch matches file indentation
1. Manually apply if fuzzy matching fails

### Wrong file modified

**Cause:** Incorrect target path entered

**Solutions:**

1. Undo with `u` immediately
1. Use `<leader>pab` for auto-suggestion to avoid typos
1. Use absolute paths: `/full/path/to/file.lua`

## Integration with AI Workflows

### Claude Code

1. Ask Claude for specific patch
1. Copy suggested diff
1. Apply with `<leader>paa`

### Code Rabbit

1. Copy PR review suggestions
1. Paste into buffer
1. Preview with `<leader>pap`
1. Apply with `<leader>paa`

### Custom Scripts

```lua
-- Programmatic patch application
local patch = get_llm_response()
require("patch_it").apply(patch, "src/file.lua")
```

## Tips

- **Preview always:** Use `<leader>pap` before `<leader>paa` for safety
- **Small patches:** Break large diffs into single-hunk patches
- **Context lines:** Include 2-3 context lines for reliable fuzzy matching
- **Undo friendly:** Patches create single undo points
