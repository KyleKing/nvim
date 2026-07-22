local pack = require("kyleking.pack")
local add, later = pack.add, pack.later

-- Setup markdown/djot list editing and preview now (not later): both just register a
-- FileType autocmd, and later() defers past the point where nvim fires FileType for a
-- buffer opened via command-line argument (e.g. `nvim README.md`), so the buffer-local
-- keymaps would never attach to that first buffer.
pack.now(function()
    require("kyleking.utils.list_editing").setup()
    require("kyleking.utils.preview").setup()
end)

-- PLANNED: Consider mini.cycle when released for bool/semver/custom cycling

later(function()
    -- Purely visual (flashes undo/redo regions). Skip in UI-less (headless/test) runs where its
    -- deferred vim.hl.range callbacks fire on already-deleted buffers ("Invalid buffer id: N").
    if #vim.api.nvim_list_uis() == 0 then return end
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
    -- Adds "around/inside next/last" intelligence: vana (around next argument), vilb (inside last brackets)
    -- Works with: f (function call), a (argument), b (brackets), q (quotes), t (tags), and more
    --
    -- Treesitter-backed structural text objects (replaces nvim-treesitter-textobjects `select`).
    -- These gain dot-repeat and next/last (`n`/`l`) targeting that the classic select module lacked.
    -- Identifiers preserve the previous scheme: k=block, c=class, ?=conditional, m=method/function,
    -- o=loop, z=argument. Note: overriding `?` replaces mini.ai's default interactive user-prompt
    -- text object with conditional, matching the prior `a?`/`i?` binding.
    local ts = require("mini.ai").gen_spec.treesitter
    require("mini.ai").setup({
        n_lines = 500, -- Search within 500 lines
        search_method = "cover_or_next", -- Prefer covering current cursor, then next occurrence
        custom_textobjects = {
            k = ts({ a = "@block.outer", i = "@block.inner" }),
            c = ts({ a = "@class.outer", i = "@class.inner" }),
            ["?"] = ts({ a = "@conditional.outer", i = "@conditional.inner" }),
            m = ts({ a = "@function.outer", i = "@function.inner" }),
            o = ts({ a = "@loop.outer", i = "@loop.inner" }),
            z = ts({ a = "@parameter.outer", i = "@parameter.inner" }),
        },
    })
end)

later(function()
    local MiniTrailspace = require("mini.trailspace")
    MiniTrailspace.setup()

    -- Toggle trailspace highlighting
    local K = vim.keymap.set
    K("n", "<leader>ut", function()
        -- Safely check if augroup exists (returns empty table if not)
        local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "MiniTrailspace" })
        if ok and #autocmds > 0 then
            -- Disable: clear autocmds and unhighlight
            vim.api.nvim_del_augroup_by_name("MiniTrailspace")
            MiniTrailspace.unhighlight()
            vim.notify("Trailspace highlighting disabled", vim.log.levels.INFO)
        else
            -- Re-enable: recreate autocmds and highlight
            MiniTrailspace.setup()
            MiniTrailspace.highlight()
            vim.notify("Trailspace highlighting enabled", vim.log.levels.INFO)
        end
    end, { desc = "Toggle trailing whitespace highlighting" })
end)

later(function()
    local hipatterns = require("mini.hipatterns")
    local link_patterns = require("kyleking.utils.link_open").patterns

    local word_pattern = function(word) return "%f[%w]()" .. word .. "()%f[%W]" end
    local paren_pattern = function(word) return "%f[%w]()" .. word .. "%(.-%):?()%s" end

    -- Highlight only the "[text]" span of a markdown link (not the "(url)" part,
    -- which the `url` highlighter below already covers) so the two look distinct
    -- instead of stacking the same group over the whole "[text](url)".
    local md_link_text_pattern = "%[().-()%]%b()"

    -- `link_patterns.url`'s character class allows `(` `)` (so URLs like Wikipedia's
    -- "...Lua_(programming_language)" survive open-url); link_open.lua compensates by
    -- trimming an unbalanced trailing ")" after matching. Highlighting can't run that
    -- same post-match trim, so mirror it with two alternatives instead: one that only
    -- consumes a balanced "(...)" suffix, and one with no parens in the class at all,
    -- so a URL wrapped in prose parens -- "(see https://example.com)" -- doesn't pull
    -- the closing ")" into the highlight.
    local url_body = "[%w_.~:/?#%[%]@!$&'*+,;=%%-]+"
    local url_patterns = {
        "()https?://" .. url_body .. "%b()()",
        "()https?://" .. url_body .. "()",
    }

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
            -- Link to the built-in treesitter markup groups so link colors stay
            -- theme-aware instead of hardcoding hex (three distinct looks: url is
            -- italic+underlined, md_link text is Special-linked, plugin_ref is bold).
            url = { pattern = url_patterns, group = "@markup.link.url" },
            md_link = { pattern = md_link_text_pattern, group = "@markup.link.label" },
            plugin_ref = { pattern = link_patterns.plugin, group = "@markup.link" },
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

later(function()
    -- Smart sorting with treesitter awareness and indentation fallback
    local sorting = require("kyleking.utils.sorting")
    local K = vim.keymap.set

    -- Visual selection sorting (gS in visual mode)
    K("x", "gS", function() sorting.sort_visual() end, { desc = "Sort selection (smart)" })

    -- Operator mode sorting (gSS for line, gS{motion} for motion)
    K("n", "gS", function() sorting.sort_operator() end, { desc = "Sort operator (smart)" })

    -- Sort entire file
    K("n", "gSF", function() sorting.sort_file() end, { desc = "Sort file (smart)" })
end)
