# Workspace Diagnostics

Comprehensive solution for running project-local type checkers (mypy, pyright) across monorepos and reviewing results with batch operations.

## Architecture

**Two-phase approach:**

1. **Active work**: LSP workspace diagnostics while editing files
1. **On-demand**: Project-local tool execution for comprehensive checks

**Key features:**

- Detects project roots using `find-relative-executable`
- Resolves project-local tool versions (`.venv/bin/mypy`, `node_modules/.bin/prettier`)
- Monorepo support: auto-discovers sub-projects and runs appropriate tool version
- Batch quickfix operations: filter, dedupe, sort, stats, open all

## Usage

### LSP workspace diagnostics (while working)

Collect all LSP diagnostics from open buffers:

```vim
<leader>lwd    " LSP workspace diagnostics -> quickfix
```

### On-demand linting and type checking

Run project-local linters/type checkers using `<leader>lw{ecosystem}{tool}` pattern:

```vim
" Python (p)
<leader>lwpm    " mypy
<leader>lwpp    " pyright
<leader>lwpr    " ruff check
<leader>lwpt    " ty

" TypeScript/JavaScript (t)
<leader>lwte    " eslint
<leader>lwto    " oxlint

" Go (g)
<leader>lwgg    " golangci-lint

" Lua (l)
<leader>lwll    " selene
```

**Behavior:**

- Runs in all projects within VCS root if available (monorepo-aware)
- Falls back to current project if not in VCS
- Respects project-local tool versions (`.venv/bin/mypy` vs global `mypy`)
- Self-documenting keybindings encode both ecosystem and tool

**Supported tools:**

- **Python**: mypy, pyright, ty, ruff (project-local via `.venv/bin/`)
- **JavaScript/TypeScript**: oxlint, eslint (project-local via `node_modules/.bin/`)
- **Go**: golangci-lint (global, runs in project with `go.mod`)
- **Lua**: selene, stylua (global, runs in project with `selene.toml`)
- **Generic**: Any CLI tool that outputs diagnostics in parseable format

**Tool-specific configurations:**

Tools are invoked with optimized flags for diagnostics output:

```lua
mypy --show-column-numbers --no-error-summary .
pyright --outputjson .
ruff check --output-format text .
golangci-lint run .
selene --display-style quiet .
ty check .
```

### Quickfix batch operations

Navigate and manipulate quickfix results:

```vim
" Browse with mini.pick (enhanced preview with ±5 lines context)
<leader>fl    " Quickfix picker (flat view)
<leader>qg    " Quickfix picker (grouped by file)
<leader>fL    " Location list picker

" Statistics and cleanup
<leader>qs    " Show quickfix stats (count, by-file, by-type)
<leader>qd    " Remove duplicate entries
<leader>qS    " Sort by file + line number

" Filtering
<leader>qf    " Filter: keep matches (regex)
<leader>qF    " Filter: remove matches (regex)
<leader>qt    " Filter: by severity (interactive menu)

" Batch operations
<leader>qb    " Batch fix: auto mode (bulk apply with confirmation)
<leader>qB    " Batch fix: interactive mode (review each fix)
<leader>qn    " Batch fix: navigate mode (manual with open buffers)

" File operations
<leader>qo    " Open all quickfix files
<leader>qO    " Open all files (vsplit)

" Session management
<leader>qw    " Save quickfix list to file
<leader>qr    " Load quickfix list from file
```

## Examples

### Monorepo workflow

```vim
" 1. Check project structure
<leader>lwi
" Shows: 15 Python projects, 4 Node projects

" 2. Run mypy across all Python projects
<leader>lwpm

" 3. Run oxlint across all Node/TypeScript projects
<leader>lwto

" 4. Review stats
<leader>qs
" Output: Total items: 147 | Files: 23 | Errors: 89 | Warnings: 58

" 5. Filter to errors only
<leader>qf
" Input: error:

" 6. Browse with picker
<leader>fl

" 7. Open all affected files
<leader>qo
```

### Mixed-language monorepo

For repositories with multiple languages:

```vim
" Check what the system detects
<leader>lwi

" Run Python type checking across all Python projects
<leader>lwpm    " mypy (auto-detects 15 Python projects)

" Run TypeScript linting across all Node projects
<leader>lwto    " oxlint (auto-detects 4 Node projects)
<leader>lwte    " eslint (auto-detects 4 Node projects)
```

### Filtering examples

**Keep only type errors:**

```vim
<leader>qf
Input: error.*type
```

**Remove test files:**

```vim
<leader>qF
Input: test_.*\.py
```

**Keep specific modules:**

```vim
<leader>qf
Input: src/api/
```

**Filter by severity (interactive):**

```vim
<leader>qt
" Select from menu: Errors only (E), Warnings only (W), Info only (I), Notes only (N), All
```

### Batch operations

**Three modes for applying LSP code actions:**

#### Auto mode (fast, bulk apply)

```vim
<leader>qb    " Batch fix: auto-apply all fixes with confirmation
```

Automatically applies the first matching code action to each quickfix item. Fast but no per-item control.

#### Interactive mode (review each fix)

```vim
<leader>qB    " Batch fix: interactive review
```

Shows each fix one at a time with options:

- **Apply** - Apply this fix and continue
- **Skip** - Skip this fix and continue
- **Apply to all remaining** - Apply same action type to rest (when pattern detected)
- **Cancel** - Stop batch operation

**Example workflow:**

```vim
" 1. Run type checker
<leader>lwpm    " mypy

" 2. Start interactive batch fix
<leader>qB

" 3. Review each fix:
"    [1/15] src/api/users.py:42
"    Diagnostic: error: Missing return statement
"    Fix: Add explicit return None
"
"    > Apply | Skip | Apply to all remaining | Cancel

" 4. If you see the same fix repeatedly, choose "Apply to all remaining"
```

#### Navigate mode (manual control)

```vim
<leader>qn    " Navigate mode: open buffers with instructions
```

Opens all affected files and shows navigation instructions:

- Use `]q` / `[q` to jump between quickfix items
- Use `<leader>ca` to apply code action at cursor
- Review code in context before fixing
- Full manual control

**Best for:**

- Complex fixes requiring context
- Reviewing changes across multiple files
- Learning what the code actions do

**Grouped picker workflow:**

```vim
" Populate quickfix
<leader>lwpp

" Open grouped picker (file → items hierarchy)
<leader>qg

" Navigate:
" - Select file header to jump to file
" - Select item to jump to specific line
" - Preview shows ±5 lines context
```

### Session management

**Save/restore quickfix lists across sessions:**

```vim
" Save current quickfix to file
<leader>qw
Input: .qf_session

" Later, restore the same quickfix list
<leader>qr
Input: .qf_session
```

**Use cases:**

- Save diagnostic results before refactoring
- Share quickfix lists with team (commit `.qf_session` to repo)
- Archive results from different type checkers
- Compare diagnostic results over time

## API

### `workspace_diagnostics.run_workspace(tool, args)`

Run tool with project detection:

```lua
local wd = require("kyleking.utils.workspace_diagnostics")

-- Run mypy with custom args
wd.run_workspace("mypy", { "--strict" })

-- Run pyright
wd.run_workspace("pyright", { "--verbose" })
```

### `workspace_diagnostics.run_in_current_project(tool, args)`

Run tool in current project only (skip monorepo detection):

```lua
wd.run_in_current_project("mypy")
```

### `workspace_diagnostics.run_in_projects(tool, projects, args, callback)`

Run tool in specific projects:

```lua
local projects = { "/path/to/proj1", "/path/to/proj2" }
wd.run_in_projects("mypy", projects, nil, function(output)
    print("Complete: " .. vim.fn.getqflist({ size = 0 }).size .. " items")
end)
```

### Quickfix operations

```lua
local wd = require("kyleking.utils.workspace_diagnostics")

-- Filter by pattern
wd.qf.filter("error", true)  -- Keep matches
wd.qf.filter("warning", false)  -- Remove matches

-- Filter by severity
wd.qf.filter_severity("E")  -- Errors only
wd.qf.filter_severity("W")  -- Warnings only
wd.qf.filter_severity(nil)  -- All items
wd.qf.filter_severity_interactive()  -- Interactive menu

-- Statistics
wd.qf.stats()

-- Cleanup
wd.qf.dedupe()
wd.qf.sort()

-- Grouping
local by_file = wd.qf.group_by_file()
for filename, items in pairs(by_file) do
    print(filename .. ": " .. #items .. " items")
end

local by_type = wd.qf.group_by_type()
print("Errors: " .. #by_type.E)
print("Warnings: " .. #by_type.W)

-- Batch operations
wd.qf.batch_fix({ preview = true })  -- Apply LSP code actions
wd.qf.batch_fix({
    preview = false,
    filter = function(action)
        -- Custom filter for code actions
        return action.kind and action.kind:match("^quickfix")
    end
})

-- Pickers
wd.qf.picker_grouped()  -- Hierarchical picker (file → items)

-- File operations
wd.qf.open_all()  -- edit
wd.qf.open_all("vsplit")  -- vsplit
wd.qf.open_all("tabnew")  -- new tabs

-- Session management
wd.qf.save_session(".qf_mypy")
wd.qf.load_session(".qf_mypy")
```

## Integration

### With conform.nvim/nvim-lint

Tools are resolved via `find-relative-executable`:

```lua
local fre = require("find-relative-executable")

-- Conform formatter
require("conform").setup({
    formatters = {
        ruff_format = { command = fre.command_for("ruff") },
    },
})

-- nvim-lint linter
require("lint").linters.ruff.cmd = fre.cmd_for("ruff")
```

### With LSP

Generate root_dir functions:

```lua
local fre = require("find-relative-executable")

vim.lsp.config("pyright", {
    root_dir = fre.lsp_root_for({ "python" }),
})
```

### Custom picker actions

Add custom mini.pick actions for quickfix:

```lua
local MiniPick = require("mini.pick")

MiniPick.registry.qf_apply_fixes = function()
    -- Custom action to apply all quickfix code actions
    local qf = vim.fn.getqflist()
    for _, item in ipairs(qf) do
        vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
        vim.lsp.buf.code_action({ apply = true })
    end
end
```

## Implementation notes

**Project detection priority:**

1. Ecosystem markers: `pyproject.toml` (Python), `package.json` (Node), `go.mod` (Go)
1. VCS root: `.jj` (Jujutsu) > `.git`

**Caching:**

- Tool resolution: Cached per `tool:project_root`
- Project root: 5-second TTL
- VCS root: 5-second TTL

**Monorepo discovery:**

- Detects projects by ecosystem: Python (`pyproject.toml`), Node (`package.json`), Go (`go.mod`)
- Scans up to depth 3 for nested projects
- Skips: `node_modules`, `.venv`, `__pycache__`
- Tool-aware: Python tools scan for Python projects, Node tools scan for Node projects
- Supports mixed-language monorepos with multiple ecosystems

**Error format:**

- Uses vim's native errorformat parsing
- Preserves tool-specific output format
- Supports multi-line error messages

## Adding new tools

### 1. Add to ecosystems mapping

Edit `lua/find-relative-executable/init.lua`:

```lua
local ecosystems = {
    mytool = "python",  -- or "node", "go", "rust", "lua"
}
```

### 2. (Optional) Add custom command builder

If the tool needs subcommands or special flags, edit `lua/kyleking/utils/workspace_diagnostics.lua`:

```lua
local tool_commands = {
    mytool = function(tool_path)
        return { tool_path, "check", "--format", "json" }
    end,
}
```

### 3. Add keybinding

Edit `lua/kyleking/deps/lsp.lua` under the appropriate ecosystem section.

Use pattern `<leader>lw{ecosystem}{tool}`:

```lua
-- Example: mytool in Python ecosystem (p) with key 'm'
K("n", "<leader>lwpm", function()
    require("kyleking.utils.workspace_diagnostics").run_workspace("mytool")
end, { desc = "Python: mytool" })
```

### Example: Adding shellcheck

```lua
-- 1. In find-relative-executable/init.lua
shellcheck = "shell",  -- Add to ecosystems

-- 2. In strategies (if project-local installation exists)
shell = { marker = ".shellcheckrc", bin_dir = nil },

-- 3. In workspace_diagnostics.lua (if special flags needed)
shellcheck = function(tool_path)
    return { tool_path, "--format", "gcc" }  -- GCC format for vim quickfix
end,

-- 4. Add keybinding (use 's' ecosystem, 'h' for shellcheck)
K("n", "<leader>lwsh", function() wd.run_workspace("shellcheck") end, { desc = "Shell: shellcheck" })
```

## Testing

Run test suite:

```bash
mise run test:file FILE=lua/tests/custom/workspace_diagnostics_spec.lua
```

Test coverage:

- Filter (keep/remove matches)
- Deduplication
- Sorting (by buffer + line)
- Grouping by file
