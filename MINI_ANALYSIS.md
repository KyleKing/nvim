# Mini.nvim Analysis & Replacement Strategy

## Current Plugins → Mini.nvim Replacements

### ✅ CAN REPLACE

| Current Plugin | Mini Alternative | Notes |
|---------------|------------------|-------|
| **vim-sandwich** | `mini.surround` | Already installed but 's' key disabled |
| **which-key.nvim** | `mini.clue` | Lighter, shows next key clues |
| **gitsigns.nvim** | `mini.diff` + `mini.git` | Git hunks + git integration |
| **nap.nvim** | `mini.bracketed` | Navigate with `[` and `]` |
| **bufjump.nvim** | Built-in + `mini.bracketed` | Use `[b` `]b` for buffers |
| **url-open + gx.nvim** | Built-in `gx` or keep one | Consolidate to single solution |

### ❌ NO MINI EQUIVALENT (KEEP THESE)

| Plugin | Reason to Keep |
|--------|---------------|
| **conform.nvim** | NO mini formatter - conform is excellent |
| **nvim-lint** | NO mini linter - use LSP diagnostics |
| **trouble.nvim** | NO mini quickfix/diagnostics UI - very useful |
| **nvim-treesitter** | NO mini syntax/parsing - essential |
| **flash.nvim** | mini.jump2d exists but flash is more powerful |
| **nvim-lspconfig** | LSP client configuration - keep |
| **lsp_signature.nvim** | Signature help - keep |

### 🆕 NEW MINI MODULES TO ADD

| Module | Purpose | Value |
|--------|---------|-------|
| **mini.extra** | **SORTING** + extra pickers/text objects | Solves sorting request! |
| **mini.clue** | Replace which-key | Lighter, native feeling |
| **mini.diff** | Git diff hunks | Replace gitsigns |
| **mini.git** | Git integration | Complement mini.diff |
| **mini.bracketed** | Navigate with `[]` | Replace nap/bufjump |
| **mini.bufremove** | Better buffer deletion | Avoid layout issues |
| **mini.pairs** | Auto-pairs | Don't have this currently |
| **mini.notify** | Notifications | Better UX |
| **mini.visits** | Track file visits | Smart file navigation |
| **mini.splitjoin** | Split/join arguments | Useful for refactoring |

### 🤔 CONSIDER

| Module | Purpose | Notes |
|--------|---------|-------|
| **mini.sessions** | Session management | If you use sessions |
| **mini.jump2d** | 2D jumping | Alternative to flash.nvim |
| **mini.animate** | Animate actions | Visual polish (optional) |
| **mini.hipatterns** | Highlight patterns | Color codes, TODOs, etc. |
| **mini.indentscope** | Indent scope visualization | See current scope |

## Specific Solutions

### 1. Sorting Lists (mini.extra)

`mini.extra` provides sorting functionality:

```lua
-- Sort lines
MiniExtra.pickers.list({ items = lines, sort = true })

-- Or use mini.operators for sorting text objects
```

### 2. URL Opening

**Options:**
- Keep just `gx.nvim` (better than url-open)
- Use built-in `gx` (opens URL under cursor)
- **Recommended**: Keep gx.nvim, remove url-open

### 3. Buffer Navigation

Replace `nap.nvim` + `bufjump.nvim` with:
- `mini.bracketed` - `[b` `]b` for buffer navigation
- Built-in `:bnext` `:bprevious`
- `mini.pick.builtin.buffers()` for fuzzy buffer finding

### 4. Performance Tracking

**Built-in Options:**
```lua
-- Startup time
vim.cmd('!nvim --startuptime /tmp/nvim-startuptime.txt +q')

-- Runtime profiling
vim.cmd('profile start /tmp/nvim-profile.txt')
vim.cmd('profile func *')
vim.cmd('profile file *')

-- Lua profiling
local start = vim.loop.hrtime()
-- ... code ...
local elapsed = (vim.loop.hrtime() - start) / 1e6 -- milliseconds
```

**Custom performance tracker:**
```lua
-- Track key operations
local perf = require('mini.misc').setup_auto_root()
-- Or create custom metrics collector
```

## Implementation Priority

### Phase 1: Quick Wins (Do Now)
1. ✅ Enable `mini.surround`, remove `vim-sandwich`
2. ✅ Add `mini.extra` for sorting
3. ✅ Replace `which-key` with `mini.clue`
4. ✅ Consolidate URL openers (keep gx.nvim)

### Phase 2: Git Integration
5. Replace `gitsigns` with `mini.diff` + `mini.git`

### Phase 3: Buffer/Navigation
6. Replace `nap.nvim` + `bufjump.nvim` with `mini.bracketed`
7. Add `mini.bufremove` for better buffer management

### Phase 4: Nice-to-Haves
8. Add `mini.pairs` (auto-pairs)
9. Add `mini.notify` (notifications)
10. Add `mini.visits` (track file visits)
11. Add `mini.splitjoin` (split/join)

### Phase 5: Documentation & Performance
12. Create TLDR docs for all plugins
13. Add performance tracking
14. Add performance tests to mini.test

## Mini.nvim Modules Already Using

✅ mini.deps
✅ mini.files
✅ mini.pick
✅ mini.statusline
✅ mini.comment
✅ mini.ai
✅ mini.icons
✅ mini.move
✅ mini.surround (disabled)
✅ mini.trailspace
✅ mini.test

## Final Plugin Count Estimate

**Current**: ~35 plugins
**After Phase 1**: ~31 plugins (-4)
**After Phase 2**: ~30 plugins (-1)
**After Phase 3**: ~28 plugins (-2)
**After Phase 4**: ~28 plugins (adding mini modules)

**Net**: Remove 7 external plugins, add 11 mini modules (lighter, more integrated)

## Notes

- **conform.nvim**: NO replacement - formatters need external tools anyway
- **nvim-lint**: NO replacement - linters need external tools anyway
- **trouble.nvim**: NO replacement - unique UI, very valuable
- **Built-in `gx`**: Works but limited compared to gx.nvim
- **Performance**: Can track with built-in tools + custom metrics
