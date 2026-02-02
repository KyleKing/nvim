## Plugin Guides

Each subsection covers a plugin group: what it does, its operator grammar
or mental model, and upstream help references. Keymaps are discoverable
via `<leader>fk` and mini.clue.

## Fuzzy Finding (mini.pick)

Fuzzy finder for files, buffers, grep, help, keymaps, and more. Uses
mini.pick with mini.extra for additional pickers.

### Navigation

    <C-j>/<C-k>     Move down/up through matches
    <C-g>            Jump to first match
    <C-f>/<C-b>      Scroll page down/up (matches or preview)
    <C-h>/<C-l>      Scroll left/right (matches or preview)
    <CR>             Choose item
    <C-s>            Choose in horizontal split
    <C-v>            Choose in vertical split
    <C-t>            Choose in new tab
    <Esc>            Close picker

### Preview

    <Tab>            Toggle preview (replaces match list in same window)
    <S-Tab>          Toggle info (shows available mappings)

While preview is active, `<C-f>`/`<C-b>` scroll the preview content.
Moving between items (`<C-j>`/`<C-k>`) updates preview automatically.

### Query syntax

Queries are fuzzy by default. Prefix/suffix characters change matching:

    'text            Exact (substring) match
    ^text            Exact match anchored to start
    text$            Exact match anchored to end
    *text            Forced fuzzy match (override other modes)
    text1 text2      Grouped: each term matched independently

Respects `ignorecase` and `smartcase` settings.

Scoring sorts by narrowest match width first, then earliest start
position. No special preference for filename vs path -- matches are
scored uniformly on the full string.

### Marking and bulk actions

    <C-x>            Toggle mark on current item
    <C-a>            Toggle mark on all matches
    <M-CR>           Choose all marked items (e.g., open in quickfix)

### Refine (progressive narrowing)

    <C-Space>        Refine current matches (reset query, keep results)
    <M-Space>        Refine marked items only

Example: type `'hello`, press `<C-Space>`, then type `'world` to find
items containing both terms in any order.

### Paste into prompt

`<C-r>` followed by register key (like insert mode):

    <C-r>"           Paste from default register (last yank/delete)
    <C-r>+           Paste from system clipboard
    <C-r>*           Paste from selection clipboard
    <C-r>/           Paste last search pattern
    <C-r>:           Paste last command
    <C-r><C-w>       Paste word under cursor
    <C-r><C-a>       Paste WORD under cursor
    <C-r><C-l>       Paste current line

### Grep glob filtering

In live grep (`<leader>fw`), press `<C-o>` to add a glob pattern that
restricts results to matching files (e.g., `*.lua`, `tests/**`).
Multiple globs can be stacked. Only supported with rg and git tools.

### File picker and hidden files

`<leader>ff` uses rg which includes hidden/dotfiles (`.github/**`,
etc.) and respects `.gitignore`. `<leader>gf` uses `git ls-files` to
list only git-tracked files.

### Tips

- `<leader>fB` lists all built-in pickers -- useful for discovering
  what is available.
- `<leader><CR>` resumes the last picker with its previous query and
  matches intact.

Source: `lua/kyleking/deps/fuzzy-finder.lua`

See also: `MiniPick`, `MiniExtra`

## File Explorer (mini.files)

Miller-column file explorer with preview. Navigate, create, rename, and
delete files directly.

    <leader>e       Toggle explorer (opens at current file)

Inside the explorer: `h`/`l` navigate up/into directories, `=`
synchronizes (applies pending changes), `w` bookmarks to cwd.

Edit files by typing a new filename (create), deleting a line (delete),
or editing the name in place (rename). Press `=` to apply.

Filtered entries: `.git`, `.venv`, `node_modules`, `__pycache__`, and
other common non-project directories are hidden.

Source: `lua/kyleking/deps/file-explorer.lua`

See also: `MiniFiles`

## Surround (mini.surround)

Add, delete, find, and replace surrounding pairs.

Operator grammar:

    sa{motion}{char}  Add surrounding (e.g., saiw" wraps word in quotes)
    sd{char}          Delete surrounding (e.g., sd" removes quotes)
    sr{old}{new}      Replace surrounding (e.g., sr"' changes " to ')
    sf / sF           Find surrounding (right / left)
    sh                Highlight surrounding

Custom: `f` for function calls -- `saiwf` prompts for function name and
wraps with `func(...)`.

`s` is disabled in normal/visual mode to avoid conflict. Use `cl` instead.

Source: `lua/kyleking/deps/editing-support.lua`

See also: `MiniSurround`

## Comment (mini.comment)

Toggle comments using treesitter-aware commentstring.

    gc{motion}      Toggle comment (e.g., gcip comments paragraph)
    gcc             Toggle comment on current line
    gc (visual)     Toggle comment on selection

Supports embedded languages (e.g., JS inside HTML) via treesitter.

Source: `lua/kyleking/deps/editing-support.lua`

See also: `MiniComment`

## Move (mini.move)

Move lines or visual selections in any direction with `<leader>m{h,j,k,l}`.
Works in both Normal mode (current line) and Visual mode (selection).
Auto-indents when moving vertically.

Source: `lua/kyleking/deps/editing-support.lua`

See also: `MiniMove`

## Clue (mini.clue)

Displays available keybinding continuations after a 500ms delay. Triggers
on `<Leader>`, `g`, `'`, `` ` ``, `"`, `<C-r>`, `<C-w>`, `<C-x>`,
`z`, `[`, `]`.

Tips:

- Scroll the clue window with `<C-d>` / `<C-u>`.
- Register clue shows register contents inline.

Source: `lua/kyleking/deps/keybinding.lua`

See also: `MiniClue`

## Git (mini.diff, mini.git, diffview)

Inline diff signs in the sign column (mini.diff), statusline git branch
(mini.git), and side-by-side diff viewing (diffview.nvim).

    <leader>ugd     Toggle git diff overlay (full inline diff)
    :DiffviewOpen   Open side-by-side diff viewer
    :DiffviewClose  Close diffview

Source: `lua/kyleking/deps/git.lua`

See also: `MiniDiff`, `MiniGit`

## Flash (motion/jumping)

Jump to any visible location with minimal keystrokes.

    <Alt-s>         Flash jump (normal, visual, operator-pending)
    <Alt-S>         Flash Treesitter (select treesitter node)
    <C-s>           Toggle Flash Search (in command-line / search)

Flash labels visible matches so you can jump with 1-2 keystrokes.
Treesitter mode selects entire syntax nodes.

Source: `lua/kyleking/deps/motion.lua`

See also: <https://github.com/folke/flash.nvim>

## Navigation (nap.nvim, buffers, windows, tabs)

### nap.nvim

Bracket-pair navigation for buffers, quickfix, diagnostics, and more.
Press `]x` or `[x` to jump, then use `<C-n>`/`<C-p>` to repeat with a
single keystroke.

**Available operators** (`]` = next, `[` = previous):

    a, A        Tabs
    b, B        Buffers
    d           Diagnostics
    e           Change list / edit history
    f, F        Files
    l, L        Location list
    q, Q        Quickfix list
    s           Spelling errors
    t, T        Tags
    z           Folds
    '           Marks

**Repeat keys** (work after any `]x` or `[x`):

    <C-n>       Repeat last jump forward
    <C-p>       Repeat last jump backward

Example: `]b` (next buffer) → `<C-n><C-n><C-n>` (jump 3 more) → `<C-p>`
(oops, go back one).

Source: `lua/kyleking/deps/motion.lua`

See also: <https://github.com/liangxianzhe/nap.nvim>

### Buffer Management

**Navigation:**

    ]b / [b         Next/previous buffer (nap.nvim)
    <C-^>           Toggle between current and alternate buffer

**Closing:**

    <leader>bw      Wipeout current buffer (clears marks/history)
    <leader>bW      Wipeout all buffers
    :bdelete        Close buffer, keep window (preserves buffer index)
    :bwipeout       Close buffer, keep window, clear marks

Source: `lua/kyleking/core/keymaps.lua`

### Window (Split) Management

**Navigation:**

    <C-w>h/j/k/l    Move to split left/down/up/right
    <C-w>w          Cycle to next window
    <C-w>p          Jump to previous window

**Creation/closing:**

    <C-w>s          Horizontal split (:split)
    <C-w>v          Vertical split (:vsplit)
    <C-w>q          Close current window (:quit)
    <C-w>o          Close all other windows (:only)

**Resizing:**

    <C-w>=          Make all splits equal size
    <C-w>_          Maximize height
    <C-w>|          Maximize width
    <C-w>+/-        Increase/decrease height
    <C-w></>        Increase/decrease width
    :resize N       Set height to N lines
    :vertical resize N  Set width to N columns

**Smart layout toggle:**

    <leader>wf      Toggle focused/equal window layout

Toggle between two modes:

- **Focused mode:** Active window gets 60-70% of space (ratio decreases
  with more splits), others share remainder equally
- **Equal mode:** All windows equal size (equivalent to `<C-w>=`)

Respects minimum viable window sizes. Most useful with 2-5 splits.

Source: `lua/kyleking/core/keymaps.lua`, `lua/kyleking/utils.lua`

### Tab Management

**Navigation:**

    ]a / [a         Next/previous tab (nap.nvim)
    gt / gT         Next/previous tab
    Ngt             Go to tab N

**Creation/closing:**

    :tabnew         Create new tab
    :tabclose       Close current tab

Source: `lua/kyleking/core/keymaps.lua`

## Treesitter & Text Objects

Syntax-aware highlighting, folding, indentation, and incremental
selection.

Incremental selection:

    <C-Space>       Init selection / expand to larger node
    <C-s>           Expand to enclosing scope
    <M-,>           Shrink selection

Features: syntax highlighting (disabled for large buffers),
treesitter-based folding (see `kyleking-neovim-folds`), auto-indent,
language-aware commenting, 40+ parsers auto-installed.

Custom list editing provides markdown and djot list continuation, indentation,
and preview functionality:

- `<CR>` (insert mode): Continue list or stop on empty item
- `<Tab>` (insert mode): Indent list item (djot: auto-inserts blank line before sublists)
- `<S-Tab>` (insert mode): Dedent list item
- `<leader>cp`: Preview markdown/djot file in browser (requires pandoc or djot CLI)

Source: `lua/kyleking/utils/list_editing.lua`, `lua/kyleking/utils/preview.lua`

Source: `lua/kyleking/deps/syntax.lua`

See also: `nvim-treesitter`, `treesitter`

## LSP, Linting & Formatting

LSP servers (nvim 0.11 native config in `lsp/` directory): bashls, gopls,
jsonls (SchemaStore), lua_ls (nvim runtime), pyright, terraformls, ts_ls,
yamlls (SchemaStore).

Linting: nvim-lint, auto-triggers on BufEnter/BufWritePost/InsertLeave.
Project-local linters resolve via `tool_resolve.lua`.

Formatting: conform.nvim. Project-local formatters resolve via
`tool_resolve.lua`.

Diagnostic suppression:

    <leader>cn      Insert inline ignore comment for diagnostic at cursor
    <leader>cN      Insert file-wide ignore comment

Supports: golangcilint, oxlint, pyright, ruff, selene, shellcheck,
stylelint, yamllint.

Source: `lua/kyleking/deps/lsp.lua`, `lua/kyleking/deps/formatting.lua`,
`lua/kyleking/utils/tool_resolve.lua`, `lua/kyleking/utils/noqa.lua`

See also: `lspconfig`

## Codanna (semantic search)

Semantic code analysis beyond syntactic search. Uses `<leader>ls` prefix
to distinguish from LSP `<leader>lg` commands.

When to use: LSP for quick navigation (definitions, references); codanna
for cross-file impact analysis, call hierarchies, natural language queries.

Requires: `codanna` CLI (`cargo install codanna`).

Supported: Rust, Python, JS, TS, Go, Java, C, C++, C#, Swift, Kotlin,
PHP, GDScript. Limited value for Lua and Bash.

Source: `lua/kyleking/deps/fuzzy-finder.lua`

See also: <https://github.com/KyleKing/codanna.nvim>

## Terminal Integration

Shell terminal runs in a dedicated tab. TUI apps run in floating windows.

    <leader>tt      Toggle shell tab (normal and terminal mode)
    <C-'>           Toggle shell tab (alternative binding)
    <leader>gg      lazygit (respects git worktrees)
    <leader>gj      lazyjj
    <leader>td      lazydocker

The shell tab preserves its buffer across toggles. TUI floats use 90%
of the screen with rounded borders. When the TUI process exits, the
float closes and cleans up.

### Opening Files from Terminal

From within terminal mode, you can open files under the cursor:

    gf              Open file/path under cursor in new tab
    <C-w>gf         Peek file in new tab, then return to terminal

Supports both absolute and relative paths (resolved from terminal's cwd),
with optional `:line:col` suffixes (e.g., `src/file.lua:42:10`). Paths
are resolved relative to the terminal's working directory, not nvim's cwd.

Examples of supported formats:
- `README.md` (relative path)
- `/absolute/path/to/file.txt`
- `src/main.lua:123` (with line number)
- `lib/utils.py:45:12` (with line and column)

Source: `lua/kyleking/deps/terminal-integration.lua`,
`lua/kyleking/utils/file_opener.lua`

## Color & UI

Colorscheme: nightfox with custom highlights. `dim_inactive = true`.

Color tools (ccc.nvim): `<leader>uc{C,c,p}` for color
highlighting/conversion/picker.

vim-illuminate: `]r`/`[r` to jump between references of word under cursor.

Highlighted keywords (mini.hipatterns): FIXME, HACK, TODO, NOTE, FYI,
PLANNED, WARNING, PERF, TEST. Use `<leader>ft` to search.

highlight-undo.nvim: undo/redo changes are briefly highlighted.

Statusline (mini.statusline): mode, git branch, diagnostics, dynamic
filename, location. Disabled in temp sessions.

Column rulers (multicolumn.nvim): Lua 120, Python 80+120.

Source: `lua/kyleking/deps/colorscheme.lua`, `lua/kyleking/deps/color.lua`,
`lua/kyleking/deps/bars-and-lines.lua`, `lua/kyleking/deps/editing-support.lua`

## patch_it.nvim

Apply LLM-generated patches with fuzzy matching.

    <leader>paa     Apply patch -- prompts for target file
    <leader>pap     Preview patch -- dry-run showing what would change
    <leader>pab     Apply with auto-suggest -- suggests target from buffer name

Workflow: get an LLM-generated patch, paste into a buffer (`:enew`),
preview with `<leader>pap`, apply with `<leader>paa`, undo with `u`.

Features: fuzzy matching tolerates whitespace differences, accepts
patches with or without space-prefixed context lines, handles interleaved
additions and removals within a hunk.

Command: `:PatchApply path/to/target.lua`

Lua API:

```lua
local patch_it = require("patch_it")
patch_it.apply(patch_string, "target.lua")
patch_it.apply_buffer("target.lua")
patch_it.apply_buffer("target.lua", { preview = true })
```

Source: `lua/kyleking/deps/utility.lua`

See also: <https://github.com/KyleKing/patch_it.nvim>

## Other Utilities

`gx.nvim` -- `gx` opens URL or file path under cursor

`url-open` -- `<leader>uu` opens URL under cursor

`vim-dirtytalk` -- extends spell dictionary with programming terms.
`<leader>pzs` sorts the spell dictionary file

`vim-spellsync` -- automatically syncs spell files

Source: `lua/kyleking/deps/utility.lua`
