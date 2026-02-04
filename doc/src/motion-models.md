# Motion Models: Helix vs Vim with Flash.nvim

## Overview

This document compares Helix's select-then-act model with Vim's action-target model enhanced by flash.nvim, and explains why the current configuration provides the best of both worlds.

## The Two Models

### Helix: Select-Then-Act

Helix uses a selection-first paradigm where you:

1. **Select** what you want to change (visual selection becomes primary)
2. **Act** on the selection with a command

**Example workflow:**
```
# Delete a function
1. Navigate to function: ]f
2. Select function: mf (select function text object)
3. Delete: d

# Change text in quotes
1. Navigate near quotes: w w w
2. Select inside quotes: mi"
3. Change: c
```

**Key insight**: Every operation starts with a selection, making the visual mode the primary interface. Commands act on whatever is selected.

### Vim: Action-Target (with Flash.nvim)

Vim uses an action-first paradigm where you:

1. **Specify action** (delete, change, yank, etc.)
2. **Specify target** (motion, text object, or search)

Flash.nvim enhances this by making the target specification instant and visual.

**Example workflow:**
```
# Delete a function
1. d<Alt-s>  (delete + flash jump)
2. Type function name characters
3. Select label to delete from cursor to that point
   OR: d]m (delete to next method start via treesitter)
   OR: daf (delete around function via mini.ai/treesitter)

# Change text in quotes
1. ci"  (change inside quotes)
   OR: c<Alt-s> then select quote position
```

**Key insight**: Action and target are composed. You can combine any action (d/c/y/v) with any target (motion/text-object/flash-jump).

## Trade-offs

| Aspect | Helix Select-Then-Act | Vim Action-Target + Flash |
|--------|----------------------|---------------------------|
| **Visual feedback** | Selection shown before action | Flash labels show targets, selection happens simultaneously with action |
| **Cognitive load** | Lower - see before you act | Slightly higher - must visualize result |
| **Composability** | Limited - commands work on selection | High - any action × any target |
| **Efficiency** | 3 steps (select, refine, act) | 2 steps (action+target) or 1 (single motion) |
| **Discoverability** | Better - see what will change | Requires understanding operators |
| **Precision** | Requires correct selection first | Can iterate with `.` or `u` |
| **Muscle memory** | Differs from Vim/Kakoune | Builds on Vim fundamentals |

## Current Configuration: Hybrid Approach

This config uses Vim's action-target model as the foundation but incorporates Helix-inspired features:

### Vim Foundation
- **Operators**: `d`, `c`, `y`, `v` compose with all targets
- **Text objects**: mini.ai provides extensive a/i text objects
- **Motions**: Standard Vim motions plus treesitter navigation
- **Repeat**: `.` repeats the last action+target combination

### Helix-Inspired Enhancements
- **Flash.nvim** (`<Alt-s>`): Jump to visible locations instantly
- **Flash Treesitter** (`<Alt-S>`): Select syntax nodes visually first
- **Treesitter textobjects**: Navigate code structure (]m, ]z, ]k)
- **mini.clue**: Show available operations and targets
- **Extended text objects**: mini.ai's function calls, assignments, key-value pairs, numbers, etc.

### Why This Is Optimal

1. **Best of both worlds**: Use action-target for known operations (`ci"`, `daw`), use flash/treesitter-select for exploration
2. **Composability preserved**: All enhancements work with Vim operators
3. **Efficiency**: Quick operations are faster (ci" vs select-inside-quotes then delete)
4. **Exploratory power**: `<Alt-S>` provides Helix-like "explore then select" when needed
5. **Ecosystem compatibility**: Works with existing Vim plugins, workflows, and muscle memory

### Example: When to Use Each

**Use direct action-target (Vim style):**
- Known targets: `ci"`, `daw`, `yap`, `gUiw`
- Simple motions: `d$`, `c2w`, `y5j`
- Treesitter navigation: `]m`, `]z` + operators

**Use flash-enhanced (exploratory):**
- Distant targets: `d<Alt-s>` then jump to label
- Visual selection: `<Alt-S>` to select syntax node, then `d`/`c`/`y`
- Uncertain target: Flash to explore, then select

**Use mini.ai text objects (semantic):**
- Function calls: `dif` (delete inside function call)
- Assignments: `cia` (change inside assignment)
- Key-value pairs: `dak` (delete around key-value)

## Recommendation

**Keep the current flash.nvim + Vim model.** The configuration already provides:

- Helix's visual exploration through Flash Treesitter (`<Alt-S>`)
- Helix's code-aware navigation through treesitter textobjects
- Vim's composability and efficiency
- Extensive text objects through mini.ai
- Visual feedback through flash labels

Switching to pure Helix-style select-then-act would **lose**:
- Operator composition (can't create custom operators that work with all targets)
- Repeat with `.` (fundamental to Vim efficiency)
- Two-character operations like `ci"`, `daw`
- Ecosystem compatibility

The hybrid approach provides Helix's discoverability and visual feedback while preserving Vim's compositional power.
