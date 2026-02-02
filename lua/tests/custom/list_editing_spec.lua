-- Tests for list_editing utility
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Create a test buffer with markdown filetype
            vim.cmd("enew")
            vim.bo.filetype = "markdown"
        end,
        post_case = function()
            if vim.api.nvim_buf_is_valid(0) then vim.api.nvim_buf_delete(0, { force = true }) end
        end,
    },
})

-- Helper to set line and get cursor position
local function set_line_and_cursor(line_text, col)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { line_text })
    vim.api.nvim_win_set_cursor(0, { 1, col or 0 })
end

-- Helper to trigger handle_return and get result
local function simulate_return()
    local list_editing = require("kyleking.utils.list_editing")
    local result = list_editing.handle_return()
    return result
end

T["list detection"] = MiniTest.new_set()

T["list detection"]["detects unordered lists"] = function()
    local patterns = { "- item", "* item", "+ item", "  - indented" }
    for _, pattern in ipairs(patterns) do
        set_line_and_cursor(pattern .. " one")
        local line = vim.api.nvim_get_current_line()
        MiniTest.expect.no_equality(line:match("^%s*[%-%*%+]%s+"), nil, "Should match: " .. pattern)
    end
end

T["list detection"]["detects ordered lists"] = function()
    local patterns = { "1. item", "2) item", "10. item", "  1. indented" }
    for _, pattern in ipairs(patterns) do
        set_line_and_cursor(pattern)
        local line = vim.api.nvim_get_current_line()
        MiniTest.expect.no_equality(line:match("^%s*%d+[%.%)]%s+"), nil, "Should match: " .. pattern)
    end
end

T["list detection"]["ignores non-list lines"] = function()
    local non_lists = { "regular text", "1 not a list", "" }
    for _, text in ipairs(non_lists) do
        set_line_and_cursor(text)
        local result = simulate_return()
        MiniTest.expect.equality(result, "<CR>", "Should return default for: " .. text)
    end
end

T["handle_return"] = MiniTest.new_set()

T["handle_return"]["continues unordered list"] = function()
    set_line_and_cursor("- item one")
    local result = simulate_return()
    MiniTest.expect.no_equality(result:match("^<CR>"), nil, "Should contain CR")
    MiniTest.expect.no_equality(result:match("%-"), nil, "Should contain dash marker")
end

T["handle_return"]["continues ordered list"] = function()
    set_line_and_cursor("1. item one")
    local result = simulate_return()
    -- Result should be a string
    MiniTest.expect.equality(type(result), "string", "Should return a string")
    -- Should not be just the default <CR>
    MiniTest.expect.no_equality(result, "<CR>", "Should not be default behavior")
    -- Should be longer than just <CR> (includes list continuation)
    MiniTest.expect.equality(#result > 4, true, "Result should include list marker")
end

T["handle_return"]["stops list on empty item"] = function()
    set_line_and_cursor("- ")
    local result = simulate_return()
    -- Empty list items should delete marker and end at cursor position
    MiniTest.expect.no_equality(result:match("<End>"), nil, "Should end cursor positioning")
end

T["handle_return"]["preserves indentation"] = function()
    set_line_and_cursor("  - indented item")
    local result = simulate_return()
    -- Result should maintain indentation
    MiniTest.expect.no_equality(result:match("  "), nil, "Should preserve indent")
end

T["handle_tab"] = MiniTest.new_set()

T["handle_tab"]["indents list item"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    set_line_and_cursor("- item", 0)

    list_editing.handle_tab()

    local line = vim.api.nvim_get_current_line()
    MiniTest.expect.no_equality(line:match("^  %-"), nil, "Should be indented by 2 spaces")
end

T["handle_tab"]["returns tab for non-list"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    set_line_and_cursor("not a list", 0)

    local result = list_editing.handle_tab()

    MiniTest.expect.equality(result, "<Tab>", "Should return default tab")
end

T["handle_tab"]["inserts blank line for djot"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    vim.bo.filetype = "djot"

    -- Set up two lines: non-blank parent and list item
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- parent", "- child" })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    list_editing.handle_tab()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    MiniTest.expect.equality(#lines, 3, "Should insert blank line")
    MiniTest.expect.equality(lines[2], "", "Second line should be blank")
end

T["handle_shift_tab"] = MiniTest.new_set()

T["handle_shift_tab"]["dedents list item"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    set_line_and_cursor("    - item", 0)

    list_editing.handle_shift_tab()

    local line = vim.api.nvim_get_current_line()
    MiniTest.expect.no_equality(line:match("^  %-"), nil, "Should be dedented by 2 spaces")
end

T["handle_shift_tab"]["stops at zero indent"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    set_line_and_cursor("- item", 0)

    list_editing.handle_shift_tab()

    local line = vim.api.nvim_get_current_line()
    MiniTest.expect.no_equality(line:match("^%-"), nil, "Should remain at zero indent")
end

T["handle_shift_tab"]["returns default for non-list"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    set_line_and_cursor("not a list", 0)

    local result = list_editing.handle_shift_tab()

    MiniTest.expect.equality(result, "<S-Tab>", "Should return default shift-tab")
end

T["setup"] = MiniTest.new_set()

T["setup"]["creates autocmd for markdown"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    list_editing.setup()

    local autocmds = vim.api.nvim_get_autocmds({ group = "kyleking_list_editing", event = "FileType" })
    MiniTest.expect.no_equality(#autocmds, 0, "Should create FileType autocmd")

    -- Check pattern includes markdown
    local has_markdown = false
    for _, cmd in ipairs(autocmds) do
        if cmd.pattern and vim.tbl_contains(vim.split(cmd.pattern, ","), "markdown") then has_markdown = true end
    end
    MiniTest.expect.equality(has_markdown, true, "Should include markdown pattern")
end

T["setup"]["creates autocmd for djot"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    list_editing.setup()

    local autocmds = vim.api.nvim_get_autocmds({ group = "kyleking_list_editing", event = "FileType" })

    -- Check pattern includes djot
    local has_djot = false
    for _, cmd in ipairs(autocmds) do
        if cmd.pattern and vim.tbl_contains(vim.split(cmd.pattern, ","), "djot") then has_djot = true end
    end
    MiniTest.expect.equality(has_djot, true, "Should include djot pattern")
end

T["setup"]["creates keymaps in autocmd"] = function()
    local list_editing = require("kyleking.utils.list_editing")
    list_editing.setup()

    -- Trigger the autocmd by setting filetype
    vim.bo.filetype = "markdown"
    vim.cmd("doautocmd FileType markdown")

    -- Check that keymaps exist
    local mappings = vim.api.nvim_buf_get_keymap(0, "i")
    local has_cr = false
    local has_tab = false
    local has_shift_tab = false

    for _, map in ipairs(mappings) do
        if map.lhs == "<CR>" then has_cr = true end
        if map.lhs == "<Tab>" then has_tab = true end
        if map.lhs == "<S-Tab>" then has_shift_tab = true end
    end

    MiniTest.expect.equality(has_cr, true, "Should map <CR>")
    MiniTest.expect.equality(has_tab, true, "Should map <Tab>")
    MiniTest.expect.equality(has_shift_tab, true, "Should map <S-Tab>")
end

-- Allow running this file directly
if ... == nil then MiniTest.run() end

return T
