# Quickfix Batch Fix Modes

Three modes for applying LSP code actions to quickfix items, each with different levels of control and interaction.

## Mode Comparison

| Mode        | Control Level | Speed  | Best For                                  | Keybinding   |
| ----------- | ------------- | ------ | ----------------------------------------- | ------------ |
| Auto        | Low           | Fast   | Bulk fixes, trusted actions               | `<leader>qb` |
| Interactive | High          | Medium | Reviewing each fix, learning patterns     | `<leader>qB` |
| Navigate    | Full          | Slow   | Complex changes, manual review in context | `<leader>qn` |

## 1. Auto Mode (Default)

**Use when:** You trust the code actions and want to apply them all quickly.

```vim
" Example: Fix all missing type annotations
<leader>lwm          " Run mypy
<leader>qt           " Filter to errors only (optional)
<leader>qb           " Auto-apply fixes

" Prompt: "Apply code actions to 47 quickfix items?"
" > Yes / No
```

**Behavior:**

- Shows single confirmation prompt
- Applies first matching code action to each item
- No per-item interaction
- Reports: "Batch fix complete: 42 fixed, 5 skipped"

**API:**

```lua
local wd = require("kyleking.utils.workspace_diagnostics")

-- Auto mode with preview
wd.qf.batch_fix({ preview = true })

-- Auto mode without preview
wd.qf.batch_fix({ preview = false })

-- Custom filter
wd.qf.batch_fix({
    filter = function(action)
        return action.kind and action.kind == "quickfix.add.type.annotation"
    end
})
```

## 2. Interactive Mode

**Use when:** You want to review each fix before applying, with option to "apply to all similar".

```vim
" Example: Fix import errors with review
<leader>lwp          " Run pyright
<leader>qB           " Interactive batch fix
```

**Workflow:**

Each item shows a prompt like:

```
[1/15] src/api/users.py:42
Diagnostic: error: Import "Optional" could not be resolved
Fix: Add import: from typing import Optional

> Apply | Skip | Apply to all remaining | Cancel
```

**Interaction:**

- **Apply** - Apply this fix, move to next item
- **Skip** - Skip this fix, move to next item
- **Apply to all remaining** - Apply same action type automatically to rest of items
    - Appears when the same fix type is detected multiple times
    - Example: After manually applying 2 "Add import" fixes, choose this to auto-apply remaining import fixes
- **Cancel** - Stop and report what's been done so far

**Pattern Detection:**

The mode tracks action titles. When you apply the same action type twice, it offers "Apply to all remaining":

```
[1/20] Fix: Add import: from typing import Optional
> Apply

[2/20] Fix: Add import: from typing import Dict
> Apply

[3/20] Fix: Add import: from typing import List
> Apply | Skip | Apply to all remaining | Cancel
       ^
       Now available because same pattern detected
```

**API:**

```lua
local wd = require("kyleking.utils.workspace_diagnostics")

wd.qf.batch_fix({ mode = "interactive" })

-- With custom filter
wd.qf.batch_fix({
    mode = "interactive",
    filter = function(action)
        return action.kind and action.kind:match("^quickfix")
    end
})
```

## 3. Navigate Mode

**Use when:** You want full manual control with all affected files open.

```vim
" Example: Review and fix complex type errors
<leader>lwr          " Run ruff
<leader>qn           " Navigate mode
```

**What it does:**

1. Opens all unique buffers from quickfix list
1. Jumps to first quickfix item
1. Opens split window with instructions:

```
Batch Fix Navigation Mode

Total items: 23 | Files: 8

Navigate:
  ]q / [q     - Next/previous quickfix item
  <leader>ca  - Apply code action at cursor
  :copen      - Show full quickfix list

Batch:
  :lua require('kyleking.utils.workspace_diagnostics').qf.batch_fix({ mode = 'auto' })

Close this window when done: :q
```

**Workflow:**

```vim
" 1. You're now at first error location in buffer
" 2. Review the code in context
" 3. Decide what to do:

]q              " Jump to next error
[q              " Jump to previous error
<leader>ca      " Apply code action at cursor
:copen          " See all errors in quickfix

" 4. When done reviewing, optionally batch-apply remaining:
:lua require('kyleking.utils.workspace_diagnostics').qf.batch_fix({ mode = 'auto' })

" 5. Close instruction window
:q
```

**API:**

```lua
local wd = require("kyleking.utils.workspace_diagnostics")

wd.qf.batch_fix({ mode = "navigate" })
```

## Real-World Examples

### Example 1: Type Checker Cleanup (Auto Mode)

```vim
" Scenario: 100 missing type hints in a well-tested codebase
<leader>lwm          " mypy
<leader>qf           " Filter to "type hint" errors
<leader>qb           " Auto-apply all
" Done in 2 seconds
```

### Example 2: Import Organization (Interactive Mode)

```vim
" Scenario: 30 import errors, want to review each module
<leader>lwp          " pyright
<leader>qt           " Filter to errors only
<leader>qB           " Interactive mode

" Review first few imports:
[1/30] Fix: Add import: from collections import defaultdict
> Apply

[2/30] Fix: Add import: from pathlib import Path
> Apply

[3/30] Fix: Add import: from typing import Optional
> Apply to all remaining    " Auto-apply rest of imports
```

### Example 3: Complex Refactoring (Navigate Mode)

```vim
" Scenario: 15 errors across 3 files, need to understand context
<leader>lwr          " ruff
<leader>qn           " Navigate mode

" Now at first error, read surrounding code
]q                   " Next error
]q                   " Next error
<leader>ca           " Fix this one manually
[q                   " Back to review previous

" After manual review, batch-apply safe fixes:
:lua require('kyleking.utils.workspace_diagnostics').qf.batch_fix({ mode = 'auto' })
```

### Example 4: Learning Mode (Interactive)

```vim
" Scenario: New to codebase, want to see what fixes are available
<leader>lwo          " oxlint
<leader>qB           " Interactive to learn

" Review each fix suggestion:
[1/50] Fix: Use const instead of let
> Apply    " Learn that this tool suggests const

[2/50] Fix: Remove unused variable
> Skip     " Keep for debugging

[3/50] Fix: Use const instead of let
> Apply to all remaining    " Now I trust this pattern
```

## Combining with Other Features

### Filter then Fix

```vim
<leader>lwm          " mypy
<leader>qt           " Filter to errors only (skip warnings)
<leader>qB           " Interactive fix errors
```

### Group then Navigate

```vim
<leader>lwp          " pyright
<leader>qg           " Grouped picker
" Select a specific file group
<leader>qn           " Navigate mode for that file
```

### Session-based Workflows

```vim
" Day 1: Run checks, save results
<leader>lwm
<leader>qw           " Save to .qf_mypy

" Day 2: Resume fixing
<leader>qr           " Load .qf_mypy
<leader>qB           " Interactive fix
<leader>qw           " Save progress
```

## Tips

**For Auto Mode:**

- Filter first to ensure you're only fixing what you want
- Use `<leader>qs` to see stats before applying
- Can always undo with `u` in each buffer

**For Interactive Mode:**

- Let it show a few items before using "Apply to all remaining"
- Use "Skip" liberally - you can always come back
- Cancel at any time and progress is preserved

**For Navigate Mode:**

- Use `:copen` to see all items in context
- Combine with `<leader>qg` (grouped picker) for better navigation
- Keep instruction window open as reference

## Custom Filters

All modes support custom filters to control which code actions are applied:

```lua
local wd = require("kyleking.utils.workspace_diagnostics")

-- Only auto-import fixes
wd.qf.batch_fix({
    mode = "interactive",
    filter = function(action)
        return action.title and action.title:match("^Add import:")
    end
})

-- Only specific code action kinds
wd.qf.batch_fix({
    filter = function(action)
        return action.kind and (
            action.kind == "quickfix.add.import" or
            action.kind == "quickfix.add.type.annotation"
        )
    end
})
```
