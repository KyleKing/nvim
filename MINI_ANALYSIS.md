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

### Phase 1: Quick Wins ✅ COMPLETE
1. ✅ Enable `mini.surround`, remove `vim-sandwich`
2. ✅ Add `mini.extra` for sorting
3. ✅ Replace `which-key` with `mini.clue`
4. ✅ Consolidate URL openers (keep gx.nvim)
5. ✅ Add `mini.pairs` (auto-pairs)

**Result**: Removed 3 plugins, added 3 mini modules

### Phase 2: Git Integration ✅ COMPLETE
6. ✅ Replace `gitsigns` with `mini.diff` + `mini.git`

**Result**: Removed 1 plugin, added 2 mini modules

### Phase 3: Buffer/Navigation ✅ COMPLETE
7. ✅ Replace `nap.nvim` + `bufjump.nvim` with `mini.bracketed`
8. ✅ Add `mini.bufremove` for better buffer management

**Result**: Removed 2 plugins, added 2 mini modules

### Phase 4: Nice-to-Haves ✅ COMPLETE
9. ✅ Add `mini.notify` (notifications)
10. ✅ Add `mini.visits` (track file visits)
11. ✅ Add `mini.splitjoin` (split/join)

**Result**: Added 3 mini modules (pure additions for enhanced features)

### Phase 5: Performance Tracking ✅ COMPLETE
12. ✅ Add performance tracking module (`lua/kyleking/core/performance.lua`)
13. ✅ Add performance tests to mini.test suite
14. ✅ Create PERFORMANCE.md documentation

**Result**: Added custom performance infrastructure

### Phase 6: Documentation ✅ COMPLETE
15. ✅ Update PLUGINS.md with all new modules
16. ✅ Document all keymaps and usage patterns
17. ✅ Final cleanup and review

**Result**: Comprehensive documentation for all 22 external + 21 mini modules

## Implementation Summary

**Completed**: All 6 phases

**Plugins Removed**: 5 total
- vim-sandwich
- which-key.nvim
- gitsigns.nvim
- nap.nvim
- bufjump.nvim

**Mini Modules Added**: 7 new modules
- mini.bracketed
- mini.bufremove
- mini.clue
- mini.diff
- mini.git
- mini.notify
- mini.visits
- mini.splitjoin (also added mini.extra and mini.pairs in Phase 1)

**Custom Infrastructure**:
- Performance tracking module with Prometheus-style metrics
- Performance test suite
- Comprehensive documentation

## Mini.nvim Modules Now Using (26 total)

✅ mini.ai - Enhanced text objects
✅ mini.bracketed - Unified [] navigation
✅ mini.bufremove - Better buffer deletion
✅ mini.clue - Key clues (replaced which-key)
✅ mini.comment - Toggle comments
✅ mini.cursorword - Highlight word under cursor (NEW!)
✅ mini.deps - Package manager
✅ mini.diff - Git diff hunks (replaced gitsigns)
✅ mini.extra - Sorting and extra pickers
✅ mini.files - File explorer
✅ mini.git - Git integration
✅ mini.hipatterns - Highlight hex colors, TODOs, patterns (NEW!)
✅ mini.icons - Icon provider
✅ mini.indentscope - Indent scope visualization (NEW!)
✅ mini.move - Move lines/selections
✅ mini.notify - Notifications
✅ mini.operators - Text edit operators (NEW!)
✅ mini.pairs - Auto-pairs
✅ mini.pick - Fuzzy finder
✅ mini.sessions - Session management (NEW!)
✅ mini.splitjoin - Split/join arguments
✅ mini.statusline - Statusline
✅ mini.surround - Surround text (replaced vim-sandwich)
✅ mini.test - Testing framework
✅ mini.trailspace - Trailing whitespace
✅ mini.visits - Track file visits

## Final Plugin Count

**Before**: ~35 plugins total

**After All Phases + New Additions**:
- **External plugins**: 22 (down from ~35)
- **Mini modules**: 26 (up from 14)
- **Total**: 48 plugins (but mini modules are lighter and more integrated)

**Net Change**:
- Removed 5 external dependencies
- Added 12 mini modules total (Phases 1-4 + 5 new additions)
- Added custom performance infrastructure
- Result: Lighter, more integrated, feature-rich, better documented configuration

**New Mini Modules Added**:
- **Phase 1-4** (7): clue, diff, git, bracketed, bufremove, notify, visits, splitjoin, extra, pairs, surround
- **Latest Additions** (5): cursorword, hipatterns, indentscope, operators, sessions

## Notes

- **conform.nvim**: NO replacement - formatters need external tools anyway
- **nvim-lint**: NO replacement - linters need external tools anyway
- **trouble.nvim**: NO replacement - unique UI, very valuable
- **Built-in `gx`**: Works but limited compared to gx.nvim
- **Performance**: Can track with built-in tools + custom metrics
