-- Minimal configuration from: https://github.com/neovim/nvim-lspconfig?tab=readme-ov-file#suggested-configuration
-- PLANNED: see project-local guidance: https://github.com/neovim/nvim-lspconfig/wiki/Project-local-settings

local function config_lua()
    local lspconfig = require("lspconfig")
    lspconfig.lua_ls.setup({})
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

local function config()
    -- IMPORTANT: make sure to setup neodev BEFORE lspconfig
    require("neodev").setup()

    -- See logs with `:LspInfo` and `:LspLog`
    -- vim.lsp.set_log_level("debug")

    local python_path = require("kyleking.utils.system_utils").get_python_path()

    config_lua()
    config_pyright(python_path)
    config_typescript()

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

            -- Buffer local mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Go to Declaration" })
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to Defintion" })
            vim.keymap.set("n", "<leader>lK", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover" })
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = ev.buf, desc = "Go to Implementation" })
            vim.keymap.set("n", "<leader>lH", vim.lsp.buf.signature_help, { buffer = ev.buf, desc = "Signature Help" })
            vim.keymap.set(
                "n",
                "<leader>lwa",
                vim.lsp.buf.add_workspace_folder,
                { buffer = ev.buf, desc = "Add Folder" }
            )
            vim.keymap.set(
                "n",
                "<leader>lwr",
                vim.lsp.buf.remove_workspace_folder,
                { buffer = ev.buf, desc = "Remove Folder" }
            )
            vim.keymap.set(
                "n",
                "<leader>lwl",
                function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
                { buffer = ev.buf, desc = "Show Folders" }
            )
            vim.keymap.set(
                "n",
                "<leader>lD",
                vim.lsp.buf.type_definition,
                { buffer = ev.buf, desc = "Type Definition" }
            )
            vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { buffer = ev.buf, desc = "LSP Rename" })
            vim.keymap.set(
                { "n", "v" },
                "<leader>lc",
                vim.lsp.buf.code_action,
                { buffer = ev.buf, desc = "Code Action" }
            )
            vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = ev.buf, desc = "Buffer References" })
            vim.keymap.set(
                "n",
                "<leader>lf",
                function() vim.lsp.buf.format({ async = true }) end,
                { buffer = ev.buf, desc = "Format" }
            )
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
