local function _config()
    -- Adapted from: https://github.com/Wesley-AlvesRolim/Neovim-configs/blob/6d55696e909ee4240b828ac2832789eedc895618/lua/config/buffer-manager.lua
    local utils = require("utils")

    local function map(modes, keys, cb)
        local opts = {
            silent = true,
            noremap = true,
        }
        vim.keymap.set(modes, keys, cb, opts)
    end
    vim.api.nvim_set_hl(0, "BufferManagerModified", { fg = "#fECDD3" })

    local bmui = require("buffer_manager.ui")
    local tmp_dir = "/tmp/buffer_manager"
    local project_dir = vim.fn.fnamemodify(".", ":p:h:gs?/?_?:gs?\\.??")
    local path = tmp_dir .. "/bm" .. project_dir
    map({ "n" }, "BL", function() bmui.load_menu_from_file(path) end)
    map({ "n" }, "BS", function()
        utils.create_folder(tmp_dir)
        bmui.save_menu_to_file(path)
        vim.notify("Saved " .. path)
    end)
    map({ "n" }, "BO", bmui.toggle_quick_menu)
    map({ "n" }, "H", bmui.nav_prev)
    map({ "n" }, "L", bmui.nav_next)
end

return {
    "j-morano/buffer_manager.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufReadPost",
    opts = {
        focus_alternate_buffer = false,
        short_file_names = false,
        short_term_names = false,
        loop_nav = false,
        order_buffers = "filename",
        show_indicators = "before",
        width = 120,
        height = 0.5,
        select_menu_item_commands = {
            v = {
                key = "<C-v>",
                command = "vsplit",
            },
            h = {
                key = "<C-h>",
                command = "split",
            },
        },
    },
    keys = {
        {
            "<leader>bm",
            [[<cmd>lua require("buffer_manager.ui").toggle_quick_menu()<cr>]],
            desc = "Toggle buffer manager",
        },
    },
}
