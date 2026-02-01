-- :h lsp-config

-- Enable built-in LSP completion (nvim 0.11+)
-- Adapted from: https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            -- Enable completion with manual trigger
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })

            -- Keymaps for completion (buffer-local)
            local opts = { buffer = ev.buf, silent = true }

            -- Trigger completion manually
            vim.keymap.set("i", "<C-Space>", vim.lsp.completion.trigger, opts)

            -- Navigate completion menu
            vim.keymap.set("i", "<C-j>", function()
                if vim.fn.pumvisible() == 1 then
                    return "<C-n>"
                else
                    return "<C-j>"
                end
            end, vim.tbl_extend("force", opts, { expr = true, desc = "Next completion or insert C-j" }))

            vim.keymap.set("i", "<C-k>", function()
                if vim.fn.pumvisible() == 1 then
                    return "<C-p>"
                else
                    return "<C-k>"
                end
            end, vim.tbl_extend("force", opts, { expr = true, desc = "Prev completion or insert C-k" }))

            -- Accept completion with Ctrl-Enter
            vim.keymap.set("i", "<C-CR>", function()
                if vim.fn.pumvisible() == 1 then
                    return "<C-y>"
                else
                    return "<C-CR>"
                end
            end, vim.tbl_extend("force", opts, { expr = true, desc = "Accept completion or insert C-CR" }))

            -- Abort completion with Enter
            vim.keymap.set("i", "<CR>", function()
                if vim.fn.pumvisible() == 1 then
                    return "<C-e><CR>"
                else
                    return "<CR>"
                end
            end, vim.tbl_extend("force", opts, { expr = true, desc = "Abort completion or insert newline" }))
        end
    end,
})

-- Configurations are loaded from `neovim/nvim-lspconfig`
