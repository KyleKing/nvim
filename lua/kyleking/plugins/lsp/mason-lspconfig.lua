local function config_mason()
    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    require("mason").setup({})
    require("mason-lspconfig").setup({
        -- FYI: See mapping of server names here: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
        --  ruff (ruff_lsp?), pyright, and others should be installed globally with pipx
        ensure_installed = {
            "bashls",
            -- "docker_compose_language_service",
            -- "dockerls",
            "jsonls",
            "lua_ls",
            -- "marksman",
            "taplo",
            "terraformls",
            "tsserver",
            "yamlls",

            -- Python
            "pyright", -- Alternatives: pylsp, jedi_language_server, pylyzer, basedpyright, pyright
        },
        handlers = {
            require("lsp-zero").default_setup,
            bashls = function()
                require("lspconfig").bashls.setup({
                    capabilities = lsp_capabilities,
                })
            end,
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
            taplo = function()
                require("lspconfig").taplo.setup({
                    capabilities = lsp_capabilities,
                })
            end,
            terraformls = function()
                require("lspconfig").terraformls.setup({
                    capabilities = lsp_capabilities,
                })
            end,
            tsserver = function()
                require("lspconfig").tsserver.setup({
                    capabilities = lsp_capabilities,
                    -- PLANNED: use with typescript-tools or alternative (see below)
                    --  Alt: https://github.com/yioneko/nvim-vtsls
                    --   and see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#vtsls
                    -- on_attach = function() require("typescript-tools").setup({}) end,
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

            -- Python
            -- pylsp = function()
            --     require("lspconfig").pylsp.setup({
            --         capabilities = lsp_capabilities,
            --         settings = {
            --             -- Options: https://github.com/python-lsp/python-lsp-server/blob/ed00eac389e5bdd46816dd6ff4ffbb4db6766199/CONFIGURATION.md
            --             pylsp = {
            --                 plugins = {
            --                     -- formatter options (*Update: using conform for formatting instead)
            --                     autopep8 = { enabled = false },
            --                     black = { enabled = false },
            --                     flake8 = { enabled = false },
            --                     isort = { enabled = false },
            --                     yapf = { enabled = false },
            --                     -- linter options (*Update: using nvim-lint for these instead)
            --                     mccabe = { enabled = false },
            --                     preload = { enabled = false },
            --                     pycodestyle = { enabled = false },
            --                     pydocstyle = { enabled = false },
            --                     pyflakes = { enabled = false },
            --                     pylint = { enabled = false },
            --                     ruff = { enabled = false },
            --                     -- type checker
            --                     pylsp_mypy = {
            --                         enabled = true,
            --                         overrides = { "--python-executable", python_path, true },
            --                         report_progress = true,
            --                         live_mode = false,
            --                     },
            --                     -- auto-completion customization
            --                     rope_autoimport = { enabled = false },
            --                     rope_completion = { enabled = true },
            --                     jedi_completion = { fuzzy = true },
            --                 },
            --             },
            --         },
            --         flags = { debounce_text_changes = 200 },
            --     })
            -- end,
            -- pylyzer = function()
            --     require("lspconfig").pylyzer.setup({
            --         capabilities = lsp_capabilities,
            --     })
            -- end,
            -- basedpyright = function()
            --     require("lspconfig").basedpyright.setup({
            --         capabilities = lsp_capabilities,
            --     })
            -- end,
            pyright = function()
                -- -- NOTE: both are set when run with `poetry run nvim *`
                -- print(vim.env.VIRTUAL_ENV)
                -- print(vim.env.VIRTUAL_ENV)
                require("lspconfig").pyright.setup({
                    capabilities = lsp_capabilities,
                    -- settings = {
                    --     pyright = {
                    --         -- https://github.com/microsoft/pyright/blob/59b896368470bd7dcda4c4ad034756cc5f8fabcc/docs/configuration.md
                    --         typeCheckingMode = "strict",
                    --         diagnosticSeverityOverrides = {
                    --             reportUnusedVariable = "off",
                    --         },
                    --     },
                    -- },

                    -- Neither works? Still reported missing imports
                    -- -- Adapted from: https://www.reddit.com/r/neovim/comments/16ij4az/comment/k0jz32s
                    -- settings = {
                    --     python = {
                    --         analysis = {
                    --             diagnosticMode = "workspace",
                    --             -- typeCheckingMode = "off",
                    --         },
                    --         -- PYENV_ROOT=/Users/kyleking/Developer/roaminsight/reviewer/reviewer-api/.venv nvim ...py
                    --         venvPath = vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV or vim.env.PYENV_ROOT,
                    --     },
                    -- },
                    -- -- Adapted from: https://github.com/Kapocsi/dotfiles/blob/a197050297a359168bd3c7c636bf64317bf8a89a/dot-config/nvim/after/plugin/mason.lua#L41C1-L56C6
                    -- settings = {
                    --     pyright = {
                    --         autoImportCompletion = true,
                    --     },
                    --     python = {
                    --         analysis = {
                    --             autoSearchPaths = true,
                    --             diagnosticMode = "openFilesOnly",
                    --             useLibraryCodeForTypes = true,
                    --             typeCheckingMode = "off",
                    --         },
                    --         -- -- Does this need to be set?
                    --         -- pythonPath = python_path,
                    --     },
                    -- },
                })
            end,
        },
    })
end

---@class LazyPluginSpec
return {
    "williamboman/mason-lspconfig.nvim",
    cmd = { "Mason", "MasonUpdate" },
    build = ":MasonUpdate",
    dependencies = {
        { "williamboman/mason.nvim", dependencies = { { "zapling/mason-lock.nvim", opts = {} } } },
        { "neovim/nvim-lspconfig" },
        {
            "folke/lazydev.nvim", -- Replaces folke/neodev.nvim
            ft = "lua",
            opts = {
                library = {
                    { path = "luvit-meta/library", words = { "vim%.uv" } },
                },
            },
            dependencies = {
                { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
            },
        },
        -- { -- See: https://github.com/jose-elias-alvarez/typescript.nvim/issues/80#issuecomment-1633216963
        --     "pmizio/typescript-tools.nvim",
        --     opts = {},
        --     dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
        -- },
    },
    keys = {
        { "<leader>lmo", "<cmd>Mason<cr>", desc = "Open Mason" },
        { "<leader>lmu", "<cmd>MasonUpdate<cr>", desc = "Update Mason" },
    },
    config = config_mason,
}
