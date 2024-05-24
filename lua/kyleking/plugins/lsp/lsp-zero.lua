local function customize_lsp_ui()
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

        -- FYI: I'm not using the default keybindings because they don't have desc for Which-Key
        --  and I prefer to namespace them in '<leader>l'
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
        map("n", "<leader>lh", vim.lsp.buf.signature_help, { desc = "Signature Help" })
        map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename" })
        map({ "n", "v" }, "<leader>la", function() vim.lsp.buf.code_action() end, { desc = "Code Action" })
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

local function config_telescope_integrations()
    local K = vim.keymap.set
    local tele = require("telescope.builtin")
    K("n", "<leader>lzd", tele.lsp_definitions, { desc = "Telescope LSP Definintions" })
    K("n", "<leader>lzr", tele.lsp_references, { desc = "Telescope References" })
    K("n", "<leader>lzI", tele.lsp_implementations, { desc = "Telescope Implementations" })
    K("n", "<leader>lzD", tele.lsp_type_definitions, { desc = "Telescope Type Definition" })
    K("n", "<leader>lzs", tele.lsp_document_symbols, { desc = "Telescope Document Symbols" })
    K("n", "<leader>lzw", tele.lsp_dynamic_workspace_symbols, { desc = "Telescope Workspace Symbols" })
end

-- Based on: https://lsp-zero.netlify.app/v3.x/blog/you-might-not-need-lsp-zero.html
return {
    "VonHeikemen/lsp-zero.nvim",
    event = { "BufRead", "InsertEnter", "CmdlineEnter" },
    dependencies = {
        { "williamboman/mason-lspconfig.nvim" }, -- Configured in plugins.lsp.mason-lspconfig
        { "b0o/schemastore.nvim" }, -- JSON and YAML Schemas
        { "j-hui/fidget.nvim", opts = {} }, -- Useful status updates for LSP
        { "onsails/lspkind.nvim" }, -- For symbols
        { "nvim-telescope/telescope.nvim" },
    },
    config = function()
        -- See logs with `:LspInfo` and `:LspLog`
        -- vim.lsp.set_log_level("debug")
        customize_lsp_ui()
        config_lsp()
        config_telescope_integrations()
    end,
}
