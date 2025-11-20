-- :h lsp-config

-- Enable lsp completion. Adapted from:
--  https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client ~= nil and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
    end,
})

-- Configurations are loaded from `neovim/nvim-lspconfig`
