local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- PLANNED: Consider mini.cycle when released for bool/semver/custom cycling

later(function()
    add("tzachar/highlight-undo.nvim")
    require("highlight-undo").setup()
end)

later(
    function()
        require("mini.operators").setup({
            evaluate = { prefix = "g=" },
            exchange = { prefix = "" },
            multiply = { prefix = "gm" },
            replace = { prefix = "" },
            sort = { prefix = "gs" },
        })
    end
)

later(function()
    -- Defaults are Alt (Meta) + hjkl. Works in both Visual and Normal modes
    -- Alt: https://github.com/hinell/move.nvim
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
end)

later(function()
    -- Enhanced mini.surround configuration (replaces vim-sandwich)
    require("mini.surround").setup({
        -- Custom surroundings
        custom_surroundings = {
            -- Function call support
            f = {
                input = function()
                    local fn = vim.fn.input("Function name: ")
                    if fn == "" then return nil end
                    return { string.format("%%s*%s%%s*%(", vim.patt.escape(fn)), "%)" }
                end,
                output = function()
                    local fn = vim.fn.input("Function name: ")
                    if fn == "" then return nil end
                    return { left = fn .. "(", right = ")" }
                end,
            },
        },
        mappings = {
            add = "sa", -- Add surrounding (sandwich-like)
            delete = "sd", -- Delete surrounding (sandwich-like)
            find = "sf", -- Find surrounding (to right)
            find_left = "sF", -- Find surrounding (to left)
            highlight = "sh", -- Highlight surrounding
            replace = "sr", -- Replace surrounding (sandwich-like)
            update_n_lines = "sn", -- Update n_lines
        },
        -- Number of lines to search
        n_lines = 50,
        -- Whether to respect selection type
        respect_selection_type = false,
    })

    local K = vim.keymap.set
    -- Disable `s` in normal/visual mode (use `cl` instead)
    K({ "n", "x" }, "s", "<Nop>")
end)

later(function()
    -- Enhanced text objects with treesitter support
    -- Adds "around/inside next/last" intelligence: vaN (select around next argument), viL (inside last brackets)
    -- Works with: f (function), a (argument), b (brackets), q (quotes), t (tags), and more
    require("mini.ai").setup({
        n_lines = 500, -- Search within 500 lines
        search_method = "cover_or_next", -- Prefer covering current cursor, then next occurrence
        custom_textobjects = nil, -- Use defaults (can customize for project-specific text objects)
    })
end)

later(function() require("mini.trailspace").setup() end)

later(function()
    local hipatterns = require("mini.hipatterns")

    local word_pattern = function(word) return "%f[%w]()" .. word .. "()%f[%W]" end
    local paren_pattern = function(word) return "%f[%w]()" .. word .. "%(.-%):?()%s" end

    hipatterns.setup({
        highlighters = {
            fixme = { pattern = { word_pattern("FIXME"), paren_pattern("FIXME") }, group = "MiniHipatternsFixme" },
            hack = { pattern = { word_pattern("HACK"), paren_pattern("HACK") }, group = "MiniHipatternsHack" },
            todo = { pattern = { word_pattern("TODO"), paren_pattern("TODO") }, group = "MiniHipatternsTodo" },
            note = { pattern = { word_pattern("NOTE"), paren_pattern("NOTE") }, group = "MiniHipatternsNote" },
            fyi = { pattern = { word_pattern("FYI"), paren_pattern("FYI") }, group = "MiniHipatternsNote" },
            planned = {
                pattern = { word_pattern("PLANNED"), paren_pattern("PLANNED") },
                group = "MiniHipatternsPlanned",
            },
            warning = { pattern = { word_pattern("WARNING"), paren_pattern("WARNING") }, group = "MiniHipatternsFixme" },
            perf = { pattern = { word_pattern("PERF"), paren_pattern("PERF") }, group = "MiniHipatternsHack" },
            test = { pattern = { word_pattern("TEST"), paren_pattern("TEST") }, group = "MiniHipatternsTodo" },
        },
    })

    vim.api.nvim_set_hl(0, "MiniHipatternsPlanned", { bg = "#FCD7AD", fg = "#1c1c1c", bold = true })

    local K = vim.keymap.set
    K(
        "n",
        "<leader>ft",
        function() require("mini.pick").builtin.grep({ pattern = "TODO|FIXME|NOTE|PLANNED|FYI|HACK|WARNING|PERF|TEST" }) end,
        { desc = "Find in TODOs" }
    )
end)

later(function()
    -- Use mini.comment with native treesitter support (replaces ts-comments.nvim)
    require("mini.comment").setup({
        options = {
            -- Uses 'commentstring' option or treesitter for language-aware commenting
            custom_commentstring = nil,
        },
        mappings = {
            comment = "gc",
            comment_line = "gcc",
            comment_visual = "gc",
            textobject = "gc",
        },
    })
end)
