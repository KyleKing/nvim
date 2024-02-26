local function config_mason()
    require("neodev").setup({}) -- IMPORTANT: make sure to setup neodev BEFORE lspconfig

    local python_path = require("kyleking.utils.fs_utils").get_python_path()
    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    require("mason").setup({})
    require("mason-lspconfig").setup({
        -- FYI: See mapping of server names here: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
        --  ruff, pyright, and others should be installed globally with pipx
        ensure_installed = {
            "bashls",
            -- "docker_compose_language_service",
            -- "dockerls",
            "jsonls",
            "lua_ls",
            -- "marksman",
            "pylsp", -- Or: jedi_language_server
            -- "tailwindcss",
            "taplo",
            "terraformls",
            "tsserver",
            "yamlls",
        },
        handlers = {
            require("lsp-zero").default_setup,
            lua_ls = function()
                require("lspconfig").lua_ls.setup({
                    capabilities = lsp_capabilities,
                    format = { enable = false }, -- The builtin formatter is CppCXY/EmmyLuaCodeStyle (https://luals.github.io/wiki/formatter)
                })
            end,
            jsonls = function()
                require("lspconfig").jsonls.setup({
                    capabilities = lsp_capabilities,
                    settings = {
                        json = {
                            schemas = require("schemastore").json.schemas(),
                            validate = { enable = true }, -- See: https://github.com/b0o/SchemaStore.nvim/issues/8
                        },
                    },
                })
            end,
            yamlls = function()
                require("lspconfig").yamlls.setup({
                    capabilities = lsp_capabilities,
                    settings = {
                        yaml = {
                            schemaStore = {
                                enable = false, -- You must disable built-in schemaStore support if you want to use schemastore and its advanced options like `ignore`.
                                url = "", -- Avoids a TypeError: Cannot read properties of undefined (reading 'length')
                            },
                            schemas = require("schemastore").yaml.schemas(),
                        },
                    },
                })
            end,
            pylsp = function()
                require("lspconfig").pylsp.setup({
                    capabilities = lsp_capabilities,
                    settings = {
                        pylsp = {
                            plugins = {
                                -- formatter options
                                black = { enabled = false },
                                autopep8 = { enabled = false },
                                yapf = { enabled = false },
                                -- linter options
                                pylint = { enabled = true, executable = "pylint" },
                                ruff = { enabled = true },
                                pyflakes = { enabled = false },
                                pycodestyle = { enabled = false },
                                -- type checker
                                pylsp_mypy = {
                                    enabled = true,
                                    overrides = { "--python-executable", python_path, true },
                                    report_progress = true,
                                    live_mode = false,
                                },
                                -- auto-completion options
                                jedi_completion = { fuzzy = true },
                                -- import sorting
                                isort = { enabled = false },
                            },
                        },
                    },
                    flags = { debounce_text_changes = 200 },
                })
            end,
            pyright = function()
                require("lspconfig").pyright.setup({
                    capabilities = lsp_capabilities,
                    settings = { python = { pythonPath = python_path } },
                })
            end,
        },
    })
end

return {
    "williamboman/mason-lspconfig.nvim",
    cmd = { "Mason", "MasonUpdate" },
    build = ":MasonUpdate",
    dependencies = {
        { "williamboman/mason.nvim" },
        { "neovim/nvim-lspconfig" },
        { "folke/neodev.nvim" }, -- Additional lua configuration
    },
    keys = {
        { "<leader>lmo", "<cmd>Mason<cr>", desc = "Open Mason" },
        { "<leader>lmu", "<cmd>MasonUpdate<cr>", desc = "Update Mason" },
    },
    config = config_mason,
}
