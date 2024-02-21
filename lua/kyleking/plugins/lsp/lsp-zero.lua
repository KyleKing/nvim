local function customize_lsp_ui()
    -- PLANNED: this is redundant to the lsp-zero config
    local signs = {
        { name = "DiagnosticSignError", text = "", texthl = "DiagnosticSignError" },
        { name = "DiagnosticSignWarn", text = "", texthl = "DiagnosticSignWarn" },
        { name = "DiagnosticSignHint", text = "󰌵", texthl = "DiagnosticSignHint" },
        { name = "DiagnosticSignInfo", text = "󰋼", texthl = "DiagnosticSignInfo" },
    }
    for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, sign)
    end

    -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
end

local function config_lsp()
    local lsp_zero = require("lsp-zero")

    -- Full list of keymaps added from default:
    --   https://github.com/VonHeikemen/lsp-zero.nvim?tab=readme-ov-file#keybindings
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    local K = vim.keymap.set
    -- Diagnostics are not exclusive to lsp servers, so they can be global
    -- -- These are set by lsp-zero automatically
    -- K("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to Previous" })
    -- K("n", "]d", vim.diagnostic.goto_next, { desc = "Go to Next" })
    K("n", "gl", vim.diagnostic.open_float, { desc = "Open LSP hover diagnostics" })
    K("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Open LSP diagnostics list" })

    -- Otherwise, limit mappings to attached buffer
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    ---@diagnostic disable-next-line: unused-local
    lsp_zero.on_attach(function(_client, bufnr)
        -- -- PLANNED: (Investigate) Enable completion triggered by <c-x><c-o> (note: lsp-zero has some logic for this internally that this may duplicate)
        -- vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

        -- FYI: I'm not using the default keybindings becayse they don't have desc for Which-Key
        --  and I prefer to namespace them in '<leader>l'
        --
        -- -- To learn the available actions see :help lsp-zero-keybindings
        -- lsp_zero.default_keymaps({ buffer = bufnr })

        local function map(mode, lhs, rhs, opts)
            opts = opts or {}
            opts.silent = true
            opts.buffer = bufnr
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
        map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Defintion" })
        map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
        map("n", "<leader>li", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
        map("n", "<leader>lo", vim.lsp.buf.type_definition, { desc = "Type Definition" })
        map("n", "<leader>lr", vim.lsp.buf.references, { desc = "Buffer References" })
        map("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "Signature Help" })
        map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename" })
        map(
            { "n", "v" },
            "<leader>la",
            function() vim.lsp.buf.code_action({ context = { only = { "quickfix", "refactor", "source" } } }) end,
            { desc = "Code Action" }
        )
        -- Uses 'server_capabilities.documentFormattingProvider'
        map(
            { "n", "x" },
            "<leader>lF",
            function() vim.lsp.buf.format({ async = true }) end,
            { desc = "(Old) LSP Format" }
        )
        -- -- Workspace
        -- -- PLANNED: consider using the LSP-Zero variants (LspZeroWorkspaceRemove, etc.)
        -- map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "Add Folder" })
        -- map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove Folder" })
        -- map(
        --     "n",
        --     "<leader>lwl",
        --     function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
        --     { desc = "Show Folders" }
        -- )
    end)

    lsp_zero.set_sign_icons({ error = "", warn = "", hint = "󰌵", info = "󰋼" })
end

local function config_telescope()
    local K = vim.keymap.set
    local tele = require("telescope.builtin")
    K("n", "<leader>lzd", tele.lsp_definitions, { desc = "Telescope LSP Definintions" })
    K("n", "<leader>lzr", tele.lsp_references, { desc = "Telescope References" })
    K("n", "<leader>lzI", tele.lsp_implementations, { desc = "Telescope Implementations" })
    K("n", "<leader>lzD", tele.lsp_type_definitions, { desc = "Telescope Type Definition" })
    K("n", "<leader>lzs", tele.lsp_document_symbols, { desc = "Telescope Document Symbols" })
    K("n", "<leader>lzw", tele.lsp_dynamic_workspace_symbols, { desc = "Telescope Workspace Symbols" })
end

local function config_mason()
    local python_path = require("kyleking.utils.system_utils").get_python_path()
    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    require("mason").setup({})
    -- FIXME: support python!
    require("mason-lspconfig").setup({
        ensure_installed = {
            "bashls",
            -- "docker_compose_language_service",
            -- "dockerls",
            -- "jedi_language_server",
            "jsonls",
            "lua_ls",
            -- "marksman",
            -- "ruff_lsp",
            -- "tailwindcss",
            -- "taplo",
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
                                pylint = { enabled = false, executable = "pylint" },
                                ruff = { enabled = false },
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
                                jedi_completion = { fuzzy = false },
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

-- Based on: https://lsp-zero.netlify.app/v3.x/blog/you-might-not-need-lsp-zero.html
return {
    "VonHeikemen/lsp-zero.nvim",
    event = { "BufRead", "InsertEnter", "CmdlineEnter" },
    dependencies = {
        { "williamboman/mason-lspconfig.nvim", dependencies = { "williamboman/mason.nvim" } }, -- PLANNED: see configuration in mason.lua
        { "neovim/nvim-lspconfig" },
        { "b0o/schemastore.nvim" }, -- JSON and Yaml Schemas
        { "j-hui/fidget.nvim", opts = {} }, -- Useful status updates for LSP
        { "folke/neodev.nvim", opts = {} }, -- Additional lua configuration
        { "onsails/lspkind.nvim" }, -- For symbols
        { "nvim-telescope/telescope.nvim" },
    },
    config = function()
        -- FIXME: Split these back up into separate files
        -- See logs with `:LspInfo` and `:LspLog`
        -- vim.lsp.set_log_level("debug")
        customize_lsp_ui()
        config_lsp()
        config_telescope()
        config_mason()
    end,
}
