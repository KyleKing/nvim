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

`root_markers` only takes a list. Dynamic detection goes through `root_dir`, which native `vim.lsp` calls as `root_dir(bufnr, on_dir)` and which reports its answer by calling `on_dir` rather than returning:

```lua
-- lsp/pyright.lua
local project_tools = require("find-relative-executable")

return {
    filetypes = { "python" },
    root_dir = function(bufnr, on_dir)
        local path = vim.api.nvim_buf_get_name(bufnr)
        on_dir(project_tools.get_project_root(path, "python") or vim.fs.root(bufnr, ".git"))
    end,
}
```

This searches for `pyproject.toml` upward and uses that as the LSP root, useful when you have nested projects but want a single LSP instance for the workspace.

Two things to know before reaching for it. A function `root_dir` must always call `on_dir`, because skipping the call is how a config declines to start, so a function that returns a value instead leaves the server silently unstarted. It also puts the start behind a `vim.schedule`, and nvim does not recheck the buffer before that runs, so closing the file in the same tick prints an `Invalid buffer id` traceback (see `UPSTREAM_nvim_lsp_buffer_validity.md`). Prefer a plain `root_markers` list when it can express what you need.

## Available Ecosystems

- `python` - Searches for `pyproject.toml`
- `node` - Searches for `package.json`
- `go` - Searches for `go.mod`
- `rust` - Searches for `Cargo.toml`
- `ruby` - Searches for `Gemfile`
- `terraform` - Searches for `.terraform`

Fallback: `.git` directory if no ecosystem marker found.
