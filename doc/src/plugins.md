## Plugin Guides

Each subsection covers a plugin group: what it does, its operator grammar
or mental model, and upstream help references. Keymaps are discoverable
via `<leader>fk` and mini.clue.

## Fuzzy Finding (mini.pick)

Fuzzy finder for files, buffers, grep, help, keymaps, and more. Uses
mini.pick with mini.extra for additional pickers.

Picker navigation: `<C-j>`/`<C-k>` to move, `<C-Space>` to refine
(narrow), `<CR>` to accept, `<Esc>` to close.

Tips:

- `<C-Space>` refines: type a query, refine, type another to
  progressively narrow results.
- `<leader>fB` lists all built-in pickers -- useful for discovering what
  is available.

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

nap.nvim provides `[`/`]` bracket navigation pairs for buffers, quickfix,
diagnostics, etc. See `:h nap.nvim`.

Source: `lua/kyleking/deps/motion.lua`

See also: <https://github.com/folke/flash.nvim>

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

mkdx is loaded for additional markdown editing support.

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

Source: `lua/kyleking/deps/terminal-integration.lua`

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

`nap.nvim` -- `[`/`]` bracket-pair navigation. See `:h nap.nvim`

Source: `lua/kyleking/deps/utility.lua`, `lua/kyleking/deps/motion.lua`
