local languages = {
    "bash",
    "lua",
}
for _, language in ipairs(languages) do
    vim.lsp.enable(language)
end
