# Plugin Documentation (TLDR)

Quick reference for all configured plugins.

## Mini.nvim Ecosystem

### ✅ Currently Using

| Plugin | Purpose | Key Mappings | Doc |
|--------|---------|--------------|-----|
| **mini.deps** | Package manager | N/A | `:h mini.deps` |
| **mini.ai** | Enhanced text objects (a/i) | `via(`, `di"`, etc. | `:h mini.ai` |
| **mini.clue** | Show next key clues | Auto on `<leader>`, `g`, etc. | `:h mini.clue` |
| **mini.comment** | Toggle comments | `gcc`, `gc` (visual) | `:h mini.comment` |
| **mini.extra** | Sorting, extra pickers | `<leader>ss` (visual sort) | `:h mini.extra` |
| **mini.files** | File explorer | TBD | `:h mini.files` |
| **mini.icons** | Icon provider | N/A (auto) | `:h mini.icons` |
| **mini.move** | Move lines/selections | TBD | `:h mini.move` |
| **mini.pairs** | Auto-pair brackets/quotes | Auto in insert mode | `:h mini.pairs` |
| **mini.pick** | Fuzzy finder | `<leader>ff`, `<leader>fw` | `:h mini.pick` |
| **mini.statusline** | Statusline | N/A (auto) | `:h mini.statusline` |
| **mini.surround** | Surround text | `sa`, `sd`, `sr`, `sf`, `sh` | `:h mini.surround` |
| **mini.trailspace** | Trailing whitespace | Auto | `:h mini.trailspace` |
| **mini.test** | Testing framework | TBD | `:h mini.test` |

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
| **gitsigns.nvim** | Git signs in gutter | `<leader>ugd` | `:h gitsigns` |
| **diffview.nvim** | Git diff viewer | TBD | `:h diffview` |

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
| **flash.nvim** | Enhanced motion | TBD | `:h flash` |
| **dial.nvim** | Enhanced increment/decrement | `<C-a>`, `<C-x>` | [GitHub](https://github.com/monaqa/dial.nvim) |
| **highlight-undo.nvim** | Highlight undo regions | Auto on undo | [GitHub](https://github.com/tzachar/highlight-undo.nvim) |
| **text-case.nvim** | Case conversion | TBD | [GitHub](https://github.com/johmsalas/text-case.nvim) |
| **nap.nvim** | Buffer/tab navigation | TBD | [GitHub](https://github.com/liangxianzhe/nap.nvim) |
| **bufjump.nvim** | Jump between buffers | TBD | [GitHub](https://github.com/kwkarlwang/bufjump.nvim) |

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

## Plugin Counts

**Total External Plugins**: ~25 (down from ~35)

**Mini.nvim Modules**: 14
- deps, ai, clue, comment, extra, files, icons, move, pairs, pick, statusline, surround, trailspace, test

**Categories:**
- LSP & Completion: 3
- Formatting & Linting: 2
- Git: 2
- Diagnostics: 1
- Syntax: 2
- Editing & Motion: 6
- UI & Appearance: 7
- Utilities: 5
- Language-Specific: 3

## Quick Start

### Most Used Keymaps

```
Fuzzy Finding:
  <leader>ff - Find files
  <leader>fw - Search in files
  <leader>;  - Switch buffers

LSP:
  K          - Hover docs
  gd         - Go to definition
  <leader>ca - Code actions
  <leader>cr - Rename

Git:
  <leader>ugd - Toggle git deleted lines

Terminal:
  <C-'>       - Toggle terminal

Editing:
  sa          - Add surrounding
  sd          - Delete surrounding
  gcc         - Toggle comment
  <leader>ss  - Sort lines (visual)
```

### Getting Help

For any plugin, use `:h <plugin-name>` or check the linked documentation.

Most plugins also support `:PluginName<Tab>` to see available commands.
