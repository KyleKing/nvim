-- :h lsp-config

-- enable lsp completion
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
    callback = function(ev) vim.lsp.completion.enable(true, ev.data.client_id, ev.buf) end,
})

-- enable configuration from lsp/*.lua files
vim.lsp.enable({
    "bash",
    "lua",
})
