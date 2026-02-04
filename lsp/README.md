# LSP Configuration Files

Each LSP server has a configuration file in this directory that specifies:

- `filetypes` - File types this LSP should attach to
- `root_markers` - Files/directories to search for project root (or a function)
- `settings` - LSP-specific settings (optional)

## Basic Example

```lua
-- lsp/pyright.lua
return {
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", ".git" },
}
```

## Advanced: Workspace-Aware Root Detection

For monorepos or when you need more control over root detection, use `project-tools`:

```lua
-- lsp/pyright.lua
local project_tools = require("find-relative-executable")

return {
    filetypes = { "python" },
    -- Use function for dynamic root detection
    root_markers = project_tools.lsp_root_for({ "python" }),
    -- Or custom logic:
    -- root_markers = function(fname)
    --     return project_tools.get_project_root(fname, "python")
    --         or vim.fs.root(fname, ".git")
    -- end,
}
```

This searches for `pyproject.toml` upward and uses that as the LSP root, useful when you have nested projects but want a single LSP instance for the workspace.

## Available Ecosystems

- `python` - Searches for `pyproject.toml`
- `node` - Searches for `package.json`
- `go` - Searches for `go.mod`
- `rust` - Searches for `Cargo.toml`
- `ruby` - Searches for `Gemfile`
- `terraform` - Searches for `.terraform`

Fallback: `.git` directory if no ecosystem marker found.
