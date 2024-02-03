-- Use gc for toggling comments. Examples:
--  gcip or gcc (line)
--  or dgc (delete commented section using gc text-object)
-- Additional configuration for nvim-ts-context-commentstring from  : https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#minicomment
-- And see: https://github.com/echasnovski/mini.comment/blob/67f00d3ebbeae15e84584d971d0c32aad4f4f3a4/doc/mini-comment.txt#L87-L101
return {
    "echasnovski/mini.comment",
    event = "BufReadPost",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
    opts = {
        custom_commentstring = function()
            return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
        end,
    },
}
