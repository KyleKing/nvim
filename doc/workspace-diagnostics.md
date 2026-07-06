# Workspace Diagnostics (Developer Reference)

Lua API and extension guide for `lua/kyleking/utils/workspace_diagnostics/`. User-facing workflows are documented in `:h kyleking-neovim-diagnostics-workflows` (source: `doc/src/diagnostics-workflows.md`).

## Architecture

Two-phase approach: LSP workspace diagnostics while editing (`<leader>lwd`), plus on-demand project-local tool execution for comprehensive checks (`<leader>lw{ecosystem}{tool}`).

Project detection priority:

1. Ecosystem markers: `pyproject.toml` (Python), `package.json` (Node), `go.mod` (Go)
1. VCS root: `.jj` (Jujutsu) > `.git`

Monorepo discovery scans up to depth 3 for nested projects (skipping `node_modules`, `.venv`, `__pycache__`), is tool-aware (Python tools scan for Python projects), and supports mixed-language repos. Tool resolution is cached per `tool:project_root`; project and VCS roots have a 5-second TTL. Output is parsed with vim's native errorformat.

Tools are invoked with diagnostics-optimized flags, e.g.:

```lua
mypy --show-column-numbers --no-error-summary .
pyright --outputjson .
ruff check --output-format text .
selene --display-style quiet .
```

## Running Tools

```lua
local wd = require("kyleking.utils.workspace_diagnostics")

wd.run_workspace("mypy", { "--strict" })  -- monorepo-aware
wd.run_in_current_project("mypy")          -- skip monorepo detection
wd.run_in_projects("mypy", { "/path/proj1", "/path/proj2" }, nil, function(output)
    print("Complete: " .. vim.fn.getqflist({ size = 0 }).size .. " items")
end)
```

## Quickfix Operations

```lua
wd.qf.filter("error", true)          -- keep matches
wd.qf.filter("warning", false)       -- remove matches
wd.qf.filter_severity("E")           -- E/W/I/N or nil for all
wd.qf.filter_severity_interactive()
wd.qf.stats()
wd.qf.dedupe()
wd.qf.sort()
wd.qf.group_by_file()                -- { [filename] = items }
wd.qf.group_by_type()                -- { E = items, W = items, ... }
wd.qf.picker_grouped()
wd.qf.open_all("vsplit")             -- edit / vsplit / tabnew
wd.qf.save_session(".qf_mypy")
wd.qf.load_session(".qf_mypy")
```

## Batch Fix

```lua
wd.qf.batch_fix({ mode = "auto" })         -- default; single confirmation
wd.qf.batch_fix({ mode = "interactive" })  -- per-item Apply/Skip/All/Cancel
wd.qf.batch_fix({ mode = "navigate" })     -- open buffers + instructions
```

All modes accept a `filter` to control which code actions apply:

```lua
wd.qf.batch_fix({
    mode = "interactive",
    filter = function(action)
        return action.title and action.title:match("^Add import:")
    end,
})

wd.qf.batch_fix({
    filter = function(action)
        return action.kind and (
            action.kind == "quickfix.add.import" or
            action.kind == "quickfix.add.type.annotation"
        )
    end,
})
```

Interactive mode tracks action titles; after the same action type is applied twice it offers "Apply to all remaining" for that pattern.

## Integration with find-relative-executable

```lua
local fre = require("find-relative-executable")

require("conform").setup({
    formatters = { ruff_format = { command = fre.command_for("ruff") } },
})
require("lint").linters.ruff.cmd = fre.cmd_for("ruff")
vim.lsp.config("pyright", { root_dir = fre.lsp_root_for({ "python" }) })
```

## Adding New Tools

1. Add to the ecosystems mapping in `lua/find-relative-executable/init.lua`:

    ```lua
    local ecosystems = {
        mytool = "python",  -- or "node", "go", "rust", "lua"
    }
    ```

1. (Optional) Add a command builder in `workspace_diagnostics` if the tool needs subcommands or special flags:

    ```lua
    local tool_commands = {
        mytool = function(tool_path)
            return { tool_path, "check", "--format", "json" }
        end,
    }
    ```

1. Add a keybinding in `lua/kyleking/deps/lsp.lua` using the `<leader>lw{ecosystem}{tool}` pattern:

    ```lua
    K("n", "<leader>lwpm", function()
        require("kyleking.utils.workspace_diagnostics").run_workspace("mytool")
    end, { desc = "Python: mytool" })
    ```

Example (shellcheck): ecosystem `shellcheck = "shell"`, strategy `shell = { marker = ".shellcheckrc", bin_dir = nil }`, command builder returning `{ tool_path, "--format", "gcc" }`, keybinding `<leader>lwsh`.

## Testing

```bash
FILE=lua/tests/custom/workspace_diagnostics_spec.lua mise run test:file
```

Covers filtering, deduplication, sorting, and grouping by file.
