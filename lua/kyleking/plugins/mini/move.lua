-- Defaults are Alt (Meta) + hjkl. Works in both Visual and Normal modes
-- Alt: https://github.com/hinell/move.nvim
return {
    "echasnovski/mini.move",
    opts = {
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
    },
}
