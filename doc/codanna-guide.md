# Codanna Semantic Search Guide

## Overview

Codanna provides semantic code understanding that complements existing syntactic search tools.

**Configuration:** `lua/kyleking/deps/fuzzy-finder.lua:132-150`

### Syntactic vs Semantic Search

**Current Syntactic Tools:**

- Grep/ripgrep: text pattern matching
- LSP: symbol definitions, references (single file/project scope)
- Treesitter: syntax-aware navigation

**Codanna Semantic Capabilities:**

- Cross-file impact analysis
- Call hierarchy traversal
- Natural language code queries
- Symbol relationships beyond LSP scope

## Installation

### 1. Install codanna CLI

```bash
# Option A: Cargo (Rust toolchain)
cargo install codanna

# Option B: Download binary
# https://github.com/codanna-ai/codanna/releases
```

Verify installation:

```bash
codanna --version
```

### 2. Restart Neovim

The plugin is already configured and will load automatically.

## Keybinding Structure

### LSP vs Semantic Search

**LSP (syntactic):** `<leader>lg*` (go to)

- `<leader>lgd` - Definitions
- `<leader>lgi` - Implementations
- `<leader>lgr` - References
- `<leader>lgs` - Document symbols
- `<leader>lgt` - Type definitions

**Codanna (semantic):** `<leader>ls*` (semantic)

- `<leader>lsc` - Calls FROM symbol (lowercase)
- `<leader>lsC` - Callers OF symbol (uppercase)
- `<leader>lsd` - Search documentation
- `<leader>lsi` - Impact analysis
- `<leader>lss` - Semantic search
- `<leader>lsS` - Browse symbols (uppercase)

Capital letters distinguish semantic operations from LSP equivalents.

## When to Use Each

**Use LSP (`<leader>lg*`) for:**

- Quick navigation to definitions
- Finding references in current project
- Symbol lookup in open buffers

**Use Codanna (`<leader>ls*`) for:**

- Cross-file impact analysis (`<leader>lsi`)
- Understanding call hierarchies (`<leader>lsc`, `<leader>lsC`)
- Natural language queries (`<leader>lss`)
- Large-scale refactoring planning

## Configuration

Current settings:

```lua
require("codanna").setup({
    picker = "mini.pick",
    timeout = 5000,          -- 5s timeout for queries
    cache_results = true,    -- Cache for faster repeat queries
})
```

### Adjust if Needed

```lua
-- Increase timeout for large codebases
timeout = 10000  -- 10 seconds

-- Disable caching if memory constrained
cache_results = false
```

## Usage Examples

### Impact Analysis

Position cursor on function/class, press `<leader>lsi` → Shows all code affected if you modify this symbol

### Call Hierarchy

- `<leader>lsc` - "What does this function call?"
- `<leader>lsC` - "What calls this function?"

### Semantic Search

`<leader>lss` → Enter natural language query:

- "authentication functions"
- "error handling code"
- "database queries"

### Documentation Search

`<leader>lsd` → Search across code documentation/comments

## Language Support

**Supported languages:** Rust, Python, JS, TS, Go, Java, C, C++, C#, Swift, Kotlin, PHP, GDScript

**Best results:**

- Python: semantic analysis beyond LSP
- TypeScript/JavaScript: cross-module impact
- Rust: trait/impl relationships

**Limited value:**

- Lua: simpler codebases, LSP sufficient
- Bash: limited semantic meaning

## Troubleshooting

### Plugin fails to load

```bash
# Check if codanna CLI is installed
which codanna

# Check if plugin loaded
:lua print(vim.inspect(require('codanna')))
```

### Slow queries

1. Increase timeout in setup configuration
1. Check codebase size (very large repos may be slow)
1. Try building codanna index: `codanna index` (if supported)

### No results

- Codanna requires indexed/analyzed code
- May not work in non-code files
- Verify language is supported (see Language Support section)

## Trial Evaluation

After 2 weeks, assess value:

- [ ] Used `<leader>lsi` for impact analysis
- [ ] Used `<leader>lsc/C` for call hierarchies
- [ ] Tried semantic search (`<leader>lss`)
- [ ] Found cases where codanna > LSP
- [ ] Performance acceptable (\<5s queries)
- [ ] Worth keeping vs. removal

**Decision:** If 3+ checkboxes remain empty, consider removing the codanna block from fuzzy-finder.lua.

## Removal Instructions

If codanna doesn't provide value, remove lines 132-150 from `lua/kyleking/deps/fuzzy-finder.lua`:

```lua
-- Delete this entire block:
-- Semantic code search via codanna
later(function()
    _add({
        source = "KyleKing/codanna.nvim",
        ...
    })
    ...
end)
```
