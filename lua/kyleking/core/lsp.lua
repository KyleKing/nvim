-- :h lsp-config

-- enable lsp completion
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
    callback = function(ev) vim.lsp.completion.enable(true, ev.data.client_id, ev.buf) end,
})

-- enable configuration from lsp/*.lua files
local languages = {
    "bash",
    "lua",
}
for _, language in ipairs(languages) do
    vim.lsp.enable(language)
end
