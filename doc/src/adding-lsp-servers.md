# Adding LSP Servers

This guide explains how to add new Language Server Protocol (LSP) servers to your Neovim configuration.

## Overview

LSP configuration is split across three locations:

1. **Server Configs** (`lsp/*.lua`) - Per-server settings and filetypes
2. **Core Setup** (`lua/kyleking/core/lsp.lua`) - Built-in completion and keymaps
3. **Plugin Integration** (`lua/kyleking/deps/lsp.lua`) - Linters and formatters

## Adding a New LSP Server

### Step 1: Create Server Configuration File

Create a new file in `lsp/<server_name>.lua`:

```lua
-- lsp/example_ls.lua
return {
    -- File types this server should attach to
    filetypes = { "example", "examplescript" },
    
    -- Project root markers (LSP looks for these files to determine project root)
    root_markers = { "example.config", "package.json", ".git" },
    
    -- Server-specific settings (passed to the LSP server)
    settings = {
        exampleLsp = {
            -- Enable/disable features
            diagnostics = {
                enable = true,
            },
            -- Customize server behavior
            format = {
                enable = true,
            },
        },
    },
}
```

**Note:** The file is automatically loaded by Neovim 0.11+ native LSP system when you open a file matching one of the specified filetypes.

### Step 2: (Optional) Add Formatter

If your language has a dedicated formatter, add it to `lua/kyleking/deps/formatting.lua`:

```lua
local formatters_by_ft = {
    -- ... existing formatters ...
    
    -- Add your language
    example = { "example_formatter" },
    examplescript = { "example_formatter" },
}
```

For project-local formatters (installed in `.venv/bin/` or `node_modules/.bin/`):

```lua
-- If the formatter needs to be resolved from project directories
local fre = require("find-relative-executable")
formatters.example_formatter = {
    command = fre.command_for("example_formatter"),
}
```

### Step 3: (Optional) Add Linter

If your language has a dedicated linter, add it to `lua/kyleking/deps/lsp.lua`:

```lua
lint.linters_by_ft = {
    -- ... existing linters ...
    
    -- Add your language
    example = { "example_linter" },
}

-- If the linter needs project-local resolution
local function _override_linter_cmd(linter_name, tool_name)
    local linter = lint.linters[linter_name]
    if not linter then return end
    linter.cmd = fre.cmd_for(tool_name)
end

_override_linter_cmd("example_linter", "example_linter")
```

### Step 4: Test the Configuration

1. Open a file with the appropriate filetype:
   ```bash
   nvim test.example
   ```

2. Verify the LSP server attached:
   ```vim
   :LspInfo
   ```

3. Check that diagnostics are working:
   - Introduce a syntax error
   - Verify the error is highlighted
   - Check `:lua vim.diagnostic.get()` shows diagnostics

4. Test formatting (if configured):
   ```vim
   :lua vim.lsp.buf.format()
   ```

5. Test linting (if configured):
   - Save the file (`:w`)
   - Check for lint diagnostics

## Real-World Examples

### Example 1: Lua Language Server (lua_ls)

```lua
-- lsp/lua_ls.lua
return {
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", "stylua.toml", "selene.toml", ".git" },
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT", -- Neovim uses LuaJIT
            },
            diagnostics = {
                globals = { "vim" }, -- Recognize 'vim' global
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            telemetry = {
                enable = false,
            },
        },
    },
}
```

**Formatter:** StyLua (in `formatting.lua`)
```lua
formatters_by_ft = {
    lua = { "stylua" },
}
```

**Linter:** Selene (in `lsp.lua`)
```lua
lint.linters_by_ft = {
    lua = { "selene" },
}
```

### Example 2: Python (Pyright)

```lua
-- lsp/pyright.lua
return {
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" },
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
                typeCheckingMode = "basic",
            },
        },
    },
}
```

**Formatter:** Black (in `formatting.lua`)
```lua
formatters_by_ft = {
    python = { "black" },
}

-- Use project-local black if available
formatters.black = {
    command = require("find-relative-executable").command_for("black"),
}
```

**Linter:** Ruff (in `lsp.lua`)
```lua
lint.linters_by_ft = {
    python = { "ruff" },
}

_override_linter_cmd("ruff", "ruff")
```

### Example 3: TypeScript/JavaScript (ts_ls)

```lua
-- lsp/ts_ls.lua
return {
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
    settings = {
        typescript = {
            inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
            },
        },
        javascript = {
            inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
            },
        },
    },
}
```

**Formatter:** Prettier (in `formatting.lua`)
```lua
local prettier = { "prettier" }
formatters_by_ft = {
    javascript = prettier,
    javascriptreact = prettier,
    typescript = prettier,
    typescriptreact = prettier,
}
```

**Linter:** oxlint (in `lsp.lua`)
```lua
lint.linters_by_ft = {
    javascript = { "oxlint" },
    javascriptreact = { "oxlint" },
    typescript = { "oxlint" },
    typescriptreact = { "oxlint" },
}

_override_linter_cmd("oxlint", "oxlint")
```

## Advanced Configuration

### Schema-Based Servers (JSON/YAML)

For JSON and YAML, use SchemaStore for automatic schema detection:

```lua
-- In lua/kyleking/deps/lsp.lua
add("b0o/SchemaStore.nvim")

-- JSON/YAML servers require plugin integration
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end
        
        if client.name == "yamlls" then
            client.server_capabilities.documentFormattingProvider = true
            require("yaml-companion").setup({
                builtin_matchers = {
                    kubernetes = { enabled = true },
                },
                schemas = require("schemastore").yaml.schemas(),
            })
        elseif client.name == "jsonls" then
            client.server_capabilities.documentFormattingProvider = true
            require("lspconfig").jsonls.setup({
                settings = {
                    json = {
                        schemas = require("schemastore").json.schemas(),
                        validate = { enable = true },
                    },
                },
            })
        end
    end,
})
```

### Custom Root Directory Detection

For complex projects, you may need custom root detection logic:

```lua
-- lsp/custom_ls.lua
return {
    filetypes = { "custom" },
    root_markers = { "custom.config" },
    
    -- Override root directory detection
    root_dir = function(fname)
        -- Custom logic to find project root
        local util = require("lspconfig.util")
        return util.root_pattern("custom.config", ".git")(fname)
            or util.find_git_ancestor(fname)
    end,
    
    settings = { ... },
}
```

### Disabling Specific Features

Disable formatting if you prefer a dedicated formatter:

```lua
return {
    filetypes = { "example" },
    root_markers = { ".git" },
    settings = { ... },
    
    -- Disable LSP formatting (use conform.nvim instead)
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
    end,
}
```

## Troubleshooting

### Server Not Starting

1. Check if the server is installed:
   ```bash
   which example-language-server
   ```

2. Verify LSP log for errors:
   ```vim
   :lua vim.cmd.edit(vim.lsp.get_log_path())
   ```

3. Check LSP status:
   ```vim
   :LspInfo
   :LspLog
   ```

### Formatting Not Working

1. Verify formatter is installed:
   ```bash
   which example_formatter
   ```

2. Check conform.nvim status:
   ```lua
   :lua print(vim.inspect(require("conform").list_formatters(0)))
   ```

3. Try manual formatting:
   ```vim
   :lua require("conform").format({ bufnr = 0 })
   ```

### Linting Not Working

1. Verify linter is installed:
   ```bash
   which example_linter
   ```

2. Check nvim-lint status:
   ```lua
   :lua print(vim.inspect(require("lint").linters_by_ft))
   ```

3. Try manual linting:
   ```vim
   :lua require("lint").try_lint()
   ```

## Best Practices

1. **Root Markers:** Include `.git` as a fallback root marker
2. **Settings:** Only configure settings that differ from defaults
3. **Performance:** Disable expensive features for large files
4. **Documentation:** Add comments explaining non-obvious settings
5. **Testing:** Test with real projects, not just test files
6. **Project-Local Tools:** Use `find-relative-executable` for tools in virtual environments

## Resources

- [LSP Server List](https://microsoft.github.io/language-server-protocol/implementors/servers/)
- [Neovim LSP Documentation](https://neovim.io/doc/user/lsp.html)
- [nvim-lspconfig Server Configurations](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)
- [SchemaStore](https://www.schemastore.org/) - JSON/YAML schemas

## See Also

- `CLAUDE.md` - General development guide
- `doc/src/config.md` - Configuration overview
- `lua/kyleking/core/lsp.lua` - Core LSP setup
- `lua/kyleking/deps/lsp.lua` - Linter configuration
- `lua/kyleking/deps/formatting.lua` - Formatter configuration
