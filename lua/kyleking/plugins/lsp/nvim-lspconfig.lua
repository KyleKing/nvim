-- Minimal configuration from: https://github.com/neovim/nvim-lspconfig?tab=readme-ov-file#suggested-configuration
-- PLANNED: see project-local guidance: https://github.com/neovim/nvim-lspconfig/wiki/Project-local-settings

local function config_bash()
    local lspconfig = require("lspconfig")
    lspconfig.bashls.setup({})
end

local function config_lua()
    local lspconfig = require("lspconfig")
    lspconfig.lua_ls.setup({})
end

local function config_pylsp(python_path)
    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    lspconfig.pylsp.setup({
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
        flags = {
            debounce_text_changes = 200,
        },
        capabilities = capabilities,
    })
end

local function config_pyright(python_path)
    local lspconfig = require("lspconfig")
    lspconfig.pyright.setup({
        settings = {
            python = {
                pythonPath = python_path,
            },
        },
    })
end

local function config_typescript()
    local lspconfig = require("lspconfig")
    lspconfig.tsserver.setup({})
end

local function customize_lsp_ui()
    local icons = require("kyleking.utils.icons")
    local signs = {
        { name = "DiagnosticSignError", text = icons.get_icon("DiagnosticError"), texthl = "DiagnosticSignError" },
        { name = "DiagnosticSignWarn", text = icons.get_icon("DiagnosticWarn"), texthl = "DiagnosticSignWarn" },
        { name = "DiagnosticSignHint", text = icons.get_icon("DiagnosticHint"), texthl = "DiagnosticSignHint" },
        { name = "DiagnosticSignInfo", text = icons.get_icon("DiagnosticInfo"), texthl = "DiagnosticSignInfo" },
    }
    for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, sign)
    end

    -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
end

local function config()
    -- IMPORTANT: make sure to setup neodev BEFORE lspconfig
    require("neodev").setup()

    -- See logs with `:LspInfo` and `:LspLog`
    -- vim.lsp.set_log_level("debug")

    local python_path = require("kyleking.utils.system_utils").get_python_path()

    config_bash()
    config_lua()
    config_pylsp(python_path)
    config_pyright(python_path)
    config_typescript()

    customize_lsp_ui()

    -- Global mappings.
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    vim.keymap.set("n", "<leader>le", vim.diagnostic.open_float, { desc = "Open Float" })
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to Previous" })
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to Next" })
    vim.keymap.set("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Set Loc List" })

    -- Use LspAttach autocommand to only map the following keys
    -- after the language server attaches to the current buffer
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
            -- Enable completion triggered by <c-x><c-o>
            vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

            local function map(mode, lhs, rhs, opts)
                opts = opts or {}
                opts.silent = true
                opts.buffer = ev.buf
                vim.keymap.set(mode, lhs, rhs, opts)
            end

            -- Buffer local mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
            map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Defintion" })
            map("n", "<leader>lK", vim.lsp.buf.hover, { desc = "Hover" })
            map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
            map("n", "<leader>lH", vim.lsp.buf.signature_help, { desc = "Signature Help" })
            map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "Add Folder" })
            map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove Folder" })
            map(
                "n",
                "<leader>lwl",
                function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
                { desc = "Show Folders" }
            )
            map("n", "<leader>lD", vim.lsp.buf.type_definition, { desc = "Type Definition" })
            map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename" })
            map({ "n", "v" }, "<leader>lc", vim.lsp.buf.code_action, { desc = "Code Action" })
            map("n", "gr", vim.lsp.buf.references, { desc = "Buffer References" })
            -- Uses 'server_capabilities.documentFormattingProvider'
            map("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, { desc = "Format" })
        end,
    })
end

return {
    "neovim/nvim-lspconfig",
    dependencies = {
        -- {
        --   "AstroNvim/astrolsp",
        --   opts = function(_, opts)
        --     local maps = opts.mappings
        --     maps.n["<leader>li"] =
        --       { "<Cmd>LspInfo<CR>", desc = "LSP information", cond = function() return vim.fn.exists ":LspInfo" > 0 end }
        --   end,
        -- },

        -- -- Automatically install LSPs to stdpath for neovim
        -- {
        --   "williamboman/mason-lspconfig.nvim",
        --   dependencies = { "williamboman/mason.nvim" },
        --   cmd = { "LspInstall", "LspUninstall" },
        --   init = function(plugin) require("astrocore").on_load("mason.nvim", plugin.name) end,
        --   opts = function(_, opts)
        --     if not opts.handlers then opts.handlers = {} end
        --     opts.handlers[1] = function(server) require("astrolsp").lsp_setup(server) end
        --   end,
        -- },

        -- Useful status updates for LSP
        { "j-hui/fidget.nvim", opts = {} },

        -- Additional lua configuration, makes nvim stuff amazing!
        {
            "folke/neodev.nvim",
            config = false, -- Defer setup to config script
        },
    },
    init = function()
        -- Source: https://vi.stackexchange.com/a/39075/44707
        local border = "single"
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border })
        vim.lsp.handlers["textDocument/signatureHelp"] =
            vim.lsp.with(vim.lsp.handlers.signature_help, { border = border })
        vim.diagnostic.config({ float = { border = border } })
        require("lspconfig.ui.windows").default_options = { border = border }
    end,
    config = config,
}
