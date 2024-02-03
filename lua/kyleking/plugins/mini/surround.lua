local prefix = "gz"
-- local icon = vim.g.icons_enabled and "󰑤 " or ""
-- local maps = { n = {} }
-- maps.n[prefix] = { desc = icon .. "Surround" }
return {
    "echasnovski/mini.surround",
    keys = function(plugin, keys)
        -- Populate the keys based on the user's options
        local mappings = {
            { plugin.opts.mappings.add, desc = "Add surrounding", mode = { "n", "v" } },
            { plugin.opts.mappings.delete, desc = "Delete surrounding" },
            { plugin.opts.mappings.find, desc = "Find right surrounding" },
            { plugin.opts.mappings.find_left, desc = "Find left surrounding" },
            { plugin.opts.mappings.highlight, desc = "Highlight surrounding" },
            { plugin.opts.mappings.replace, desc = "Replace surrounding" },
            { plugin.opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
        }
        mappings = vim.tbl_filter(function(m) return m[1] and #m[1] > 0 end, mappings)
        return vim.list_extend(mappings, keys)
    end,
    opts = {
        mappings = {
            add = prefix .. "a", -- Add surrounding in Normal and Visual modes
            delete = prefix .. "d", -- Delete surrounding
            find = prefix .. "f", -- Find surrounding (to the right)
            find_left = prefix .. "F", -- Find surrounding (to the left)
            highlight = prefix .. "h", -- Highlight surrounding
            replace = prefix .. "r", -- Replace surrounding
            update_n_lines = prefix .. "n", -- Update `n_lines`
        },
    },
}

-- return {
--   'echasnovski/mini.surround',
--   keys = [ '<leader>s' ],
--   opts = {
--     mappings = {
--       add = '<leader>sa',
--       delete = '<leader>sd',
--       replace = '<leader>sr',
--       find = '',
--       find_left = '',
--       highlight = '',
--       update_n_lines = '',
--     },
--   },
-- }
--
--   -- Module mappings. Use `''` (empty string) to disable one.
--   mappings = {
--     add = 'sa', -- Add surrounding in Normal and Visual modes
--     delete = 'sd', -- Delete surrounding
--     find = 'sf', -- Find surrounding (to the right)
--     find_left = 'sF', -- Find surrounding (to the left)
--     highlight = 'sh', -- Highlight surrounding
--     replace = 'sr', -- Replace surrounding
--     update_n_lines = 'sn', -- Update `n_lines`
--
--     suffix_last = 'l', -- Suffix to search with "prev" method
--     suffix_next = 'n', -- Suffix to search with "next" method
--   },
