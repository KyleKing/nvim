-- Tests for mini.pick configuration, custom rg command, and query matching
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

-- -- Configuration verification -- --

T["config"] = MiniTest.new_set()

T["config"]["custom mappings are applied"] = function()
    local MiniPick = require("mini.pick")
    local mappings = MiniPick.config.mappings

    MiniTest.expect.equality(mappings.move_down, "<C-j>")
    MiniTest.expect.equality(mappings.move_up, "<C-k>")
    MiniTest.expect.equality(mappings.refine, "<C-Space>")
end

T["config"]["default mappings are preserved"] = function()
    local MiniPick = require("mini.pick")
    local mappings = MiniPick.config.mappings

    MiniTest.expect.equality(mappings.toggle_preview, "<Tab>")
    MiniTest.expect.equality(mappings.toggle_info, "<S-Tab>")
    MiniTest.expect.equality(mappings.choose, "<CR>")
    MiniTest.expect.equality(mappings.choose_in_split, "<C-s>")
    MiniTest.expect.equality(mappings.choose_in_vsplit, "<C-v>")
    MiniTest.expect.equality(mappings.choose_in_tabpage, "<C-t>")
    MiniTest.expect.equality(mappings.choose_marked, "<M-CR>")
    MiniTest.expect.equality(mappings.mark, "<C-x>")
    MiniTest.expect.equality(mappings.mark_all, "<C-a>")
    MiniTest.expect.equality(mappings.paste, "<C-r>")
    MiniTest.expect.equality(mappings.scroll_down, "<C-f>")
    MiniTest.expect.equality(mappings.scroll_up, "<C-b>")
    MiniTest.expect.equality(mappings.stop, "<Esc>")
end

T["config"]["window config returns valid floating window table"] = function()
    local MiniPick = require("mini.pick")
    local win_config = MiniPick.config.window.config

    MiniTest.expect.equality(type(win_config), "function")

    local result = win_config()
    MiniTest.expect.equality(type(result.width), "number")
    MiniTest.expect.equality(type(result.height), "number")
    MiniTest.expect.equality(type(result.row), "number")
    MiniTest.expect.equality(type(result.col), "number")
    MiniTest.expect.equality(result.border, "rounded")
    MiniTest.expect.equality(result.anchor, "NW")
    MiniTest.expect.equality(result.width > 0, true)
    MiniTest.expect.equality(result.height > 0, true)
end

-- -- Query matching -- --

T["query matching"] = MiniTest.new_set()

T["query matching"]["fuzzy match finds non-contiguous characters"] = function()
    local MiniPick = require("mini.pick")
    local stritems = { "fuzzy-finder.lua", "formatting.lua", "flash_spec.lua", "README.md" }
    local inds = { 1, 2, 3, 4 }

    local result = MiniPick.default_match(stritems, inds, { "f", "z" }, { sync = true })

    local found = {}
    for _, idx in ipairs(result) do
        found[stritems[idx]] = true
    end
    MiniTest.expect.equality(found["fuzzy-finder.lua"], true, "Should match 'fz' in fuzzy-finder.lua")
end

T["query matching"]["exact match with apostrophe prefix"] = function()
    local MiniPick = require("mini.pick")
    local stritems = { "fuzzy-finder.lua", "formatting.lua", "flash_spec.lua" }
    local inds = { 1, 2, 3 }

    local result = MiniPick.default_match(stritems, inds, { "'", "f", "l", "a", "s", "h" }, { sync = true })

    local found = {}
    for _, idx in ipairs(result) do
        found[stritems[idx]] = true
    end
    MiniTest.expect.equality(found["flash_spec.lua"], true, "Exact match should find flash_spec.lua")
    MiniTest.expect.equality(found["fuzzy-finder.lua"], nil, "Exact match should not find fuzzy-finder.lua")
end

T["query matching"]["start-anchored match with caret prefix"] = function()
    local MiniPick = require("mini.pick")
    local stritems = { "init.lua", "inline.lua", "setup.lua" }
    local inds = { 1, 2, 3 }

    local result = MiniPick.default_match(stritems, inds, { "^", "i", "n" }, { sync = true })

    local found = {}
    for _, idx in ipairs(result) do
        found[stritems[idx]] = true
    end
    MiniTest.expect.equality(found["init.lua"], true, "^in should match init.lua")
    MiniTest.expect.equality(found["inline.lua"], true, "^in should match inline.lua")
    MiniTest.expect.equality(found["setup.lua"], nil, "^in should not match setup.lua")
end

T["query matching"]["end-anchored match with dollar suffix"] = function()
    local MiniPick = require("mini.pick")
    local stritems = { "test.lua", "test.md", "test.txt" }
    local inds = { 1, 2, 3 }

    local result = MiniPick.default_match(stritems, inds, { ".", "l", "u", "a", "$" }, { sync = true })

    local found = {}
    for _, idx in ipairs(result) do
        found[stritems[idx]] = true
    end
    MiniTest.expect.equality(found["test.lua"], true, ".lua$ should match test.lua")
    MiniTest.expect.equality(found["test.md"], nil, ".lua$ should not match test.md")
end

T["query matching"]["empty query returns all items"] = function()
    local MiniPick = require("mini.pick")
    local stritems = { "a.lua", "b.lua", "c.lua" }
    local inds = { 1, 2, 3 }

    local result = MiniPick.default_match(stritems, inds, {}, { sync = true })

    MiniTest.expect.equality(#result, 3, "Empty query should return all items")
end

T["query matching"]["respects smartcase"] = function()
    local MiniPick = require("mini.pick")
    local stritems = { "MiniPick", "minipick", "MINIPICK" }
    local inds = { 1, 2, 3 }

    local saved_ic = vim.o.ignorecase
    local saved_sc = vim.o.smartcase
    vim.o.ignorecase = true
    vim.o.smartcase = true

    local result_lower = MiniPick.default_match(stritems, inds, { "m", "i", "n", "i" }, { sync = true })
    local result_upper = MiniPick.default_match(stritems, inds, { "M", "i", "n", "i" }, { sync = true })

    vim.o.ignorecase = saved_ic
    vim.o.smartcase = saved_sc

    MiniTest.expect.equality(#result_lower, 3, "Lowercase query with smartcase should match all cases")
    MiniTest.expect.equality(#result_upper < 3, true, "Mixed-case query with smartcase should be case-sensitive")
end

-- -- Keymap descriptions -- --

T["keymap descriptions"] = MiniTest.new_set()

T["keymap descriptions"]["all picker keymaps have descriptive desc fields"] = function()
    local expected = {
        { "<leader><CR>", "n", "Resume" },
        { "<leader>;", "n", "buffer" },
        { "<leader>bb", "n", "buffer" },
        { "<leader>bL", "n", "lines" },
        { "<leader>br", "n", "recent" },
        { "<leader>gf", "n", "Git" },
        { "<leader>ld", "n", "diagnostic" },
        { "<leader>ff", "n", "files" },
        { "<leader>fw", "n", "grep" },
        { "<leader>fh", "n", "help" },
        { "<leader>fk", "n", "keymap" },
        { "<leader>fr", "n", "register" },
        { "<leader>fC", "n", "command" },
        { "<leader>fB", "n", "picker" },
        { "<leader>fe", "n", "xplore" },
        { "<leader>fH", "n", "history" },
        { "<leader>fl", "n", "list" },
        { "<leader>f'", "n", "mark" },
        { "<leader>f*", "v", "visual" },
    }

    for _, entry in ipairs(expected) do
        local lhs, mode, desc_pattern = entry[1], entry[2], entry[3]
        local keymap = vim.fn.maparg(lhs, mode, false, true)
        MiniTest.expect.equality(keymap.lhs ~= nil, true, "Missing keymap: " .. lhs)
        local has_desc = keymap.desc and keymap.desc:lower():find(desc_pattern:lower()) ~= nil
        MiniTest.expect.equality(
            has_desc,
            true,
            lhs .. " desc should contain '" .. desc_pattern .. "', got: " .. (keymap.desc or "nil")
        )
    end
end

if ... == nil then MiniTest.run() end

return T
