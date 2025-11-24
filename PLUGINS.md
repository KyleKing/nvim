# Plugin Documentation (TLDR)

Quick reference for all configured plugins.

## Mini.nvim Ecosystem

### ✅ Currently Using

| Plugin | Purpose | Key Mappings | Doc |
|--------|---------|--------------|-----|
| **mini.deps** | Package manager | N/A | `:h mini.deps` |
| **mini.ai** | Enhanced text objects (a/i) | `via(`, `di"`, etc. | `:h mini.ai` |
| **mini.bracketed** | Navigate with [] | `[b` `]b`, `[d` `]d`, etc. | `:h mini.bracketed` |
| **mini.bufremove** | Delete buffers gracefully | `<leader>bc`, `<leader>bw` | `:h mini.bufremove` |
| **mini.clue** | Show next key clues | Auto on `<leader>`, `g`, etc. | `:h mini.clue` |
| **mini.comment** | Toggle comments | `gcc`, `gc` (visual) | `:h mini.comment` |
| **mini.cursorword** | Highlight word under cursor | Auto | `:h mini.cursorword` |
| **mini.diff** | Git diff hunks in gutter | `]h`, `[h`, `gh`, `gH` | `:h mini.diff` |
| **mini.extra** | Sorting, extra pickers | `<leader>ss` (visual sort) | `:h mini.extra` |
| **mini.files** | File explorer | TBD | `:h mini.files` |
| **mini.git** | Git integration | `<leader>gc` | `:h mini.git` |
| **mini.hipatterns** | Highlight patterns | Auto (colors, TODOs) | `:h mini.hipatterns` |
| **mini.icons** | Icon provider | N/A (auto) | `:h mini.icons` |
| **mini.indentscope** | Indent scope visual | `ii`, `ai`, `[i`, `]i` | `:h mini.indentscope` |
| **mini.move** | Move lines/selections | `<leader>m{h,j,k,l}` | `:h mini.move` |
| **mini.notify** | Notifications | `<leader>un`, `<leader>uN` | `:h mini.notify` |
| **mini.operators** | Text operators | `g=`, `gx`, `gm`, `gr`, `gs` | `:h mini.operators` |
| **mini.pairs** | Auto-pair brackets/quotes | Auto in insert mode | `:h mini.pairs` |
| **mini.pick** | Fuzzy finder | `<leader>ff`, `<leader>fw` | `:h mini.pick` |
| **mini.sessions** | Session management | `<leader>S{s,r,d,l,w}` | `:h mini.sessions` |
| **mini.splitjoin** | Split/join arguments | `gS` | `:h mini.splitjoin` |
| **mini.statusline** | Statusline | N/A (auto) | `:h mini.statusline` |
| **mini.surround** | Surround text | `sa`, `sd`, `sr`, `sf`, `sh` | `:h mini.surround` |
| **mini.trailspace** | Trailing whitespace | Auto | `:h mini.trailspace` |
| **mini.test** | Testing framework | `<leader>ta`, `<leader>tf` | `:h mini.test` |
| **mini.visits** | Track file visits | `<leader>fv`, `<leader>fr` | `:h mini.visits` |

### 🎯 mini.surround Usage

```
sa<motion><char>   - Add surrounding (e.g., saiw" adds quotes around word)
sd<char>           - Delete surrounding (e.g., sd" removes quotes)
sr<old><new>       - Replace surrounding (e.g., sr"' changes " to ')
sf<char>           - Find next surrounding
sF<char>           - Find previous surrounding
sh<char>           - Highlight surrounding
```

**Examples:**
- `saiw"` - Add quotes around word
- `sd(` - Delete surrounding parentheses
- `sr"'` - Replace double quotes with single quotes

### 🔍 mini.pick Usage

```
<leader>ff - Find files
<leader>fw - Live grep (search in files)
<leader>;  - Find buffers
<leader>br - Recently opened files
<leader>fh - Help tags
<leader>fk - Keymaps
```

### 📋 mini.extra Sorting

```
Visual mode: Select lines
<leader>ss - Sort selected lines
```

### 🔔 mini.notify - Notifications

```
<leader>un - Show notification history
<leader>uN - Clear notifications
```

Automatically shows:
- LSP progress notifications
- Plugin messages
- Command outputs

### 📂 mini.visits - File Visit Tracking

Smart file navigation based on visit patterns:

```
<leader>fv  - Visit paths (all tracked files)
<leader>fV  - Visit paths (current directory only)
<leader>fr  - Jump to most recently visited file
```

Automatically tracks:
- File visit frequency
- Visit recency
- Directory context

### 🔀 mini.diff & mini.git - Git Integration

```
]h, [h     - Navigate hunks
]H, [H     - Jump to first/last hunk
gh         - Apply hunk (stage changes)
gH         - Reset hunk (discard changes)
<leader>ugd - Toggle diff overlay (inline diff view)
<leader>gc  - Show git info at cursor (blame, commit info)
```

### ⬜ mini.bracketed - Unified Navigation

One navigation pattern for everything with `[` and `]`:

```
Capital letters = first/last
Lowercase = next/previous

Buffers:     [b ]b  [B ]B
Diagnostics: [d ]d  [D ]D
Files:       [f ]f  [F ]F
Git hunks:   [h ]h  [H ]H (via mini.diff)
Jumps:       [j ]j  [J ]J
Quickfix:    [q ]q  [Q ]Q
Windows:     [w ]w  [W ]W
And more: comments, indent, treesitter, undo, yank
```

### 🎨 mini.hipatterns - Highlight Patterns

Automatically highlights:
- **Hex colors**: `#ff0000`, `#f00` (shown in their actual color!)
- **TODO keywords**: TODO, FIXME, HACK, NOTE, PERF
- Can add custom patterns for your workflow

No keymaps needed - works automatically as you type!

### 📐 mini.indentscope - Indent Scope Visualization

Visual guide for current indent scope:

```
Text objects:
  ii  - Inside indent scope (current indentation level)
  ai  - Around indent scope (includes borders)

Motions:
  [i  - Jump to top of indent scope
  ]i  - Jump to bottom of indent scope
```

Perfect for Python, Lua, YAML, and any indent-based code!

### 💡 mini.cursorword - Auto-highlight Current Word

Automatically highlights all instances of the word under cursor.

No configuration needed - just move your cursor!

### 🔧 mini.operators - Text Edit Operators

Five powerful text operators with the `g` prefix:

```
g={motion}  - Evaluate text as Lua/Vim expression and replace
              Example: g=ip on "2 + 2" → "4"

gx{motion}  - Exchange two text regions
              Example: gxiw on first word, then gxiw on second word
              Swaps the two words!

gm{motion}  - Multiply (duplicate) text
              Example: 3gmiw duplicates word 3 times

gr{motion}  - Replace text with register content
              Example: yank word, then griw on another word

gs{motion}  - Sort text lines/items
              Example: gsip sorts lines in paragraph
```

### 💾 mini.sessions - Session Management

Save and restore your workspace state:

```
<leader>Ss  - Save session (prompts for name)
<leader>Sr  - Read/restore session (shows picker)
<leader>Sd  - Delete session (shows picker)
<leader>Sl  - Load latest session
<leader>Sw  - Write to current session
<leader>SL  - Load local session (.nvim-session in cwd)
<leader>SW  - Write local session (.nvim-session in cwd)
```

**Session storage**:
- Global sessions: `~/.local/share/nvim/sessions/`
- Local sessions: `.nvim-session` in project root
- Auto-saves on exit if a session is active

**Use cases**:
- Save different project states
- Quick workspace switching
- Team-shared sessions (commit `.nvim-session` to git)

## LSP & Completion

| Plugin | Purpose | Key Mappings | Doc |
|--------|---------|--------------|-----|
| **nvim-lspconfig** | LSP client configs | N/A | `:h lspconfig` |
| **Built-in LSP completion** | Auto-complete | `<C-x><C-o>`, auto-trigger | `:h lsp-completion` |
| **lsp_signature.nvim** | Function signatures | `<leader>ks` | [GitHub](https://github.com/ray-x/lsp_signature.nvim) |

### LSP Keymaps (on attach)

```
<leader>ca - Code actions
<leader>cr - Rename symbol
<leader>cR - Show references
<leader>cf - Format buffer
<leader>cd - Line diagnostics
<leader>cD - Diagnostics to loclist

Built-in (nvim 0.11+):
K          - Hover documentation
gra        - Code actions (Alt: <leader>ca)
grr        - References (Alt: <leader>cR)
grn        - Rename (Alt: <leader>cr)
gd         - Go to definition
gD         - Go to declaration
<C-w>gd    - Definition in split
```

## Formatting & Linting

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **conform.nvim** | Formatter manager | `<leader>cf` (LSP format) | `:h conform` |
| **nvim-lint** | Linter integration | Auto on save/change | [GitHub](https://github.com/mfussenegger/nvim-lint) |

**Configured Formatters** (via conform):
- Python: ruff, black
- JavaScript/TypeScript: prettier, oxlint
- Lua: stylua
- Go: gofmt
- And more...

**Configured Linters** (via nvim-lint):
- Python: ruff
- JavaScript/TypeScript: oxlint
- Lua: selene
- Shell: shellcheck
- YAML: yamllint

## Git Integration

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **mini.diff** | Git diff hunks in gutter | `]h`, `[h`, `gh`, `gH`, `<leader>ugd` | `:h mini.diff` |
| **mini.git** | Git integration | `<leader>gc` | `:h mini.git` |
| **diffview.nvim** | Git diff viewer | TBD | `:h diffview` |

### Git Keymaps (mini.diff + mini.git)

```
]h  - Next hunk
[h  - Previous hunk
]H  - Last hunk
[H  - First hunk
gh  - Apply hunk (stage)
gH  - Reset hunk (discard)
<leader>ugd - Toggle diff overlay
<leader>gc  - Show git info at cursor
```

## Diagnostics & Navigation

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **trouble.nvim** | Diagnostics UI | `<leader>xx`, `<leader>cs` | `:h trouble` |

```
<leader>xx  - Toggle diagnostics
<leader>xX  - Buffer diagnostics
<leader>cs  - Document symbols
<leader>cl  - LSP definitions/references
<leader>xL  - Location list
<leader>xQ  - Quickfix list
```

## Syntax & Treesitter

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **nvim-treesitter** | Syntax parsing | N/A (auto) | `:h nvim-treesitter` |
| **nvim-treesitter-textobjects** | TS text objects | TBD | [GitHub](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) |

## Editing & Motion

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **flash.nvim** | Enhanced motion | `<a-s>`, `<a-S>` | `:h flash` |
| **dial.nvim** | Enhanced increment/decrement | `<C-a>`, `<C-x>` | [GitHub](https://github.com/monaqa/dial.nvim) |
| **highlight-undo.nvim** | Highlight undo regions | Auto on undo | [GitHub](https://github.com/tzachar/highlight-undo.nvim) |
| **text-case.nvim** | Case conversion | TBD | [GitHub](https://github.com/johmsalas/text-case.nvim) |

### Navigation with mini.bracketed

All bracket navigation (replaces nap.nvim and bufjump.nvim):

```
[b ]b - Buffers
[c ]c - Comments
[d ]d - Diagnostics
[f ]f - Files
[h ]h - Git hunks (via mini.diff)
[i ]i - Indent scope
[j ]j - Jumps
[l ]l - Location list
[o ]o - Oldfiles
[q ]q - Quickfix
[t ]t - Treesitter
[u ]u - Undo
[w ]w - Windows
[y ]y - Yank history
```

### Buffer Management with mini.bufremove

Better buffer deletion (preserves window layout):

```
<leader>bc  - Close buffer
<leader>bC  - Force close buffer
<leader>bw  - Wipeout buffer
<leader>bW  - Force wipeout buffer
<leader>bWA - Wipeout all buffers
```

### Split/Join with mini.splitjoin

```
gS - Toggle between split and joined arguments
```

Examples:
- Function calls: `foo(a, b, c)` ↔ `foo(\n  a,\n  b,\n  c\n)`
- Arrays: `[1, 2, 3]` ↔ `[\n  1,\n  2,\n  3\n]`
- Objects: Language-aware formatting

## UI & Appearance

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **nightfox.nvim** | Colorscheme | `:colorscheme nightfox` | `:h nightfox` |
| **colorful-winsep.nvim** | Colored window separators | Auto | [GitHub](https://github.com/nvim-zh/colorful-winsep.nvim) |
| **nvim-hlslens** | Enhanced search | Auto on `/` `?` | [GitHub](https://github.com/kevinhwang91/nvim-hlslens) |
| **vim-illuminate** | Highlight word under cursor | `<leader>ur`, `<leader>uR` | `:h illuminate` |
| **multicolumn.nvim** | Smart colorcolumn | Auto | [GitHub](https://github.com/fmbarina/multicolumn.nvim) |
| **ccc.nvim** | Color picker/highlighter | `<leader>ucp`, `<leader>ucc` | [GitHub](https://github.com/uga-rosa/ccc.nvim) |

```
<leader>ucC - Toggle colorizer
<leader>ucc - Convert color
<leader>ucp - Pick color
```

## Terminal

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **Built-in terminal** | Terminal emulator | `<C-'>`, `<leader>tf/h/v` | `:h terminal` |

```
<C-'>       - Toggle floating terminal
<leader>tf  - Floating terminal
<leader>th  - Horizontal split terminal (15 rows)
<leader>tv  - Vertical split terminal (80 cols)
<Esc><Esc>  - Exit terminal mode

Terminal mode navigation:
<C-h/j/k/l> - Navigate to adjacent windows
```

## Utilities

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **gx.nvim** | Open URLs/files | `gx`, `<leader>uu` | [GitHub](https://github.com/chrishrb/gx.nvim) |
| **todo-comments.nvim** | Highlight TODOs | `<leader>ft` | [GitHub](https://github.com/folke/todo-comments.nvim) |
| **vim-dirtytalk** | Programming spell dict | Auto | [GitHub](https://github.com/psliwka/vim-dirtytalk) |
| **vim-spellsync** | Spell file sync | Auto | [GitHub](https://github.com/micarmst/vim-spellsync) |
| **preview.nvim** | Preview PlantUML | TBD | [GitLab](https://gitlab.com/itaranto/preview.nvim) |

## Language-Specific

| Plugin | Purpose | Keymaps | Doc |
|--------|---------|---------|-----|
| **pkl-neovim** | PKL language support | Auto | [GitHub](https://github.com/apple/pkl-neovim) |
| **plantuml-syntax** | PlantUML syntax | Auto | [GitHub](https://github.com/aklt/plantuml-syntax) |
| **mkdx** | Markdown extras | TBD | [GitHub](https://github.com/SidOfc/mkdx) |

## Performance Tracking

Built-in Prometheus-style metrics for monitoring Neovim performance.

### Commands

```
:PerfMetrics  - Show performance summary
:PerfExport   - Export metrics as JSON
:PerfReset    - Reset runtime metrics
<leader>up    - Show performance metrics
```

### Tracked Metrics

- **Startup time**: Total initialization time
- **Plugin load times**: Individual plugin loading duration
- **Operation counts**: Buffer reads/writes, LSP attachments
- **Operation durations**: Avg, Min, Max, P95 statistics

See [PERFORMANCE.md](./PERFORMANCE.md) for detailed documentation.

## Plugin Counts

**Total External Plugins**: ~22 (down from ~35)
- Removed: vim-sandwich, which-key, gitsigns, nap.nvim, bufjump.nvim (5 plugins)
- Still external: conform, nvim-lint, trouble, treesitter, flash, etc. (22 plugins)

**Mini.nvim Modules**: 26 (up from 14)
- **Core** (9): deps, ai, comment, files, icons, pick, statusline, test, trailspace
- **Phase 1-4** (12): bracketed, bufremove, clue, diff, extra, git, move, notify, pairs, splitjoin, surround, visits
- **New Additions** (5): cursorword, hipatterns, indentscope, operators, sessions

**All 26 Modules**:
ai, bracketed, bufremove, clue, comment, cursorword, deps, diff, extra, files, git, hipatterns, icons, indentscope, move, notify, operators, pairs, pick, sessions, splitjoin, statusline, surround, test, trailspace, visits

**Categories:**
- LSP & Completion: 3
- Formatting & Linting: 2
- Git: 2 (mini.diff, mini.git)
- Diagnostics: 1
- Syntax: 2
- Editing & Motion: 5 (operators, indentscope, cursorword, hipatterns)
- UI & Appearance: 6
- Utilities: 6 (added sessions)
- Language-Specific: 3
- Performance: 1

## Quick Start

### Most Used Keymaps

```
Fuzzy Finding:
  <leader>ff - Find files
  <leader>fw - Search in files
  <leader>;  - Switch buffers
  <leader>fv - Visit paths (smart file navigation)

Navigation ([] pattern):
  [b ]b      - Next/previous buffer
  [d ]d      - Next/previous diagnostic
  [h ]h      - Next/previous git hunk
  [j ]j      - Next/previous jump

LSP:
  K          - Hover docs
  gd         - Go to definition
  <leader>ca - Code actions
  <leader>cr - Rename

Git:
  ]h [h      - Navigate hunks
  gh         - Apply hunk
  gH         - Reset hunk
  <leader>ugd - Toggle diff overlay
  <leader>gc  - Show git info

Terminal:
  <C-'>      - Toggle terminal

Editing:
  sa         - Add surrounding
  sd         - Delete surrounding
  sr         - Replace surrounding
  gcc        - Toggle comment
  gS         - Split/join arguments
  <leader>ss - Sort lines (visual)

Text Operators (mini.operators):
  g={motion} - Evaluate expression
  gx{motion} - Exchange regions (press twice)
  gm{motion} - Multiply/duplicate
  gr{motion} - Replace with register
  gs{motion} - Sort

Indent Scope:
  ii / ai    - Inside/around indent scope
  [i ]i      - Jump to scope borders

Buffers:
  <leader>bc - Close buffer (keep window)
  <leader>bw - Wipeout buffer (keep window)

Sessions:
  <leader>Ss - Save session
  <leader>Sr - Restore session
  <leader>Sl - Load latest session

Notifications & Performance:
  <leader>un - Show notification history
  <leader>up - Show performance metrics
```

### Getting Help

For any plugin, use `:h <plugin-name>` or check the linked documentation.

Most plugins also support `:PluginName<Tab>` to see available commands.
