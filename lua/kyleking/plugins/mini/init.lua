-- Use gc for toggling comments. Examples:
--  gcip or gcc (line)
--  or dgc (delete commented section using gc text-object)
-- Additional configuration for nvim-ts-context-commentstring from  : https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#minicomment
-- And see: https://github.com/echasnovski/mini.comment/blob/67f00d3ebbeae15e84584d971d0c32aad4f4f3a4/doc/mini-comment.txt#L87-L101
local function mini_comment()
    require("mini.comment").setup({
        custom_commentstring = function()
            return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
        end,
    })
end

-- Adapted from: https://github.com/mrjones2014/dotfiles/blob/9914556e4cb346de44d486df90a0410b463998e4/nvim/lua/my/configure/mini_files.lua
local function mini_files()
    require("mini.files").setup({
        content = {
            filter = function(entry)
                return entry.name ~= ".DS_Store"
                    and entry.name ~= ".git"
                    and entry.name ~= ".venv"
                    and entry.name ~= "node_modules"
            end,
        },
        windows = {
            -- Whether to show preview of file/directory under cursor
            preview = true,
            width_preview = 80,
        },
    })
end

-- Defaults are Alt (Meta) + hjkl. Works in both Visual and Normal modes
-- Alt: https://github.com/hinell/move.nvim
local function mini_move()
    require("mini.move").setup({
        mappings = {
            -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
            left = "<leader>mh",
            right = "<leader>ml",
            down = "<leader>mj",
            up = "<leader>mk",
            -- Move current line in Normal mode
            line_left = "<leader>mh",
            line_right = "<leader>ml",
            line_down = "<leader>mj",
            line_up = "<leader>mk",
        },
    })
end

return {
    "echasnovski/mini.nvim",
    dependencies = {
        { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } }, -- For mini.comment
        { "nvim-tree/nvim-web-devicons" }, -- Required for mini.files
    },
    keys = {
        -- Bindings for mini.bracketed
        { "[c", desc = "Jump to previous comment block" },
        { "]c", desc = "Jump to next comment block" },
        { "[x", desc = "Jump to previous conflict marker" },
        { "]x", desc = "Jump to next conflict marker" },
        { "[d", desc = "Jump to previous diagnostic" },
        { "]d", desc = "Jump to next diagnostic" },
        { "[q", desc = "Jump to previous Quickfix list entry" },
        { "]q", desc = "Jump to next Quickfix list entry" },
        { "[t", desc = "Jump to previous Treesitter node" },
        { "]t", desc = "Jump to next Treesitter node" },
        -- Bindings for mini.files
        {
            "<leader>e",
            function()
                local minifiles = require("mini.files")
                if vim.bo.ft == "minifiles" then
                    minifiles.close()
                else
                    local file = vim.api.nvim_buf_get_name(0)
                    local file_exists = vim.fn.filereadable(file) ~= 0
                    minifiles.open(file_exists and file or nil)
                    minifiles.reveal_cwd()
                end
            end,
            desc = "Explorer",
        },
    },
    init = function()
        -- Hide trailing spaces in Lazy plugin buffer. Required for mini.trailspace
        -- Tip: check FileType with `:set filetype?`
        vim.cmd(
            "autocmd FileType lazy lua vim.b.minitrailspace_disable = true; if MiniTrailspace then MiniTrailspace.unhighlight() end"
        )
    end,
    config = function()
        require("mini.trailspace").setup({})

        require("mini.animate").setup({})
        require("mini.bracketed").setup({})
        mini_comment()
        mini_files()
        mini_move()
    end,
}
