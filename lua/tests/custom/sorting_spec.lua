local MiniTest = require("mini.test")
local helpers = require("tests.helpers")
local sorting = require("kyleking.utils.sorting")

local T = MiniTest.new_set()

-- Helper to create buffer with content and test sorting
local function test_sort(content, expected, opts, start_row, end_row)
    local bufnr = helpers.create_test_buffer(content, "lua")
    start_row = start_row or 0
    end_row = end_row or #content - 1

    sorting.sort_range(bufnr, start_row, end_row, opts or {})

    local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    MiniTest.expect.equality(result, expected)

    helpers.delete_buffer(bufnr)
end

T["sort_range"] = MiniTest.new_set()

T["sort_range"]["sorts lua table"] = function()
    local content = {
        "local t = {",
        '    zebra = "z",',
        '    apple = "a",',
        '    mango = "m",',
        "}",
    }
    local expected = {
        "local t = {",
        '    apple = "a",',
        '    mango = "m",',
        '    zebra = "z",',
        "}",
    }
    test_sort(content, expected)
end

T["sort_range"]["preserves trailing comma in lua table"] = function()
    local content = {
        "local t = {",
        '    "zebra",',
        '    "apple",',
        '    "mango",',
        "}",
    }
    local expected = {
        "local t = {",
        '    "apple",',
        '    "mango",',
        '    "zebra",',
        "}",
    }
    test_sort(content, expected)
end

T["sort_range"]["sorts array elements"] = function()
    local content = {
        "local items = {",
        '    "zebra",',
        '    "apple",',
        '    "mango",',
        "}",
    }
    local expected = {
        "local items = {",
        '    "apple",',
        '    "mango",',
        '    "zebra",',
        "}",
    }
    test_sort(content, expected)
end

T["sort_range"]["sorts with indentation grouping"] = function()
    local content = {
        "zebra = 1",
        "apple = 2",
        "mango = 3",
    }
    local expected = {
        "apple = 2",
        "mango = 3",
        "zebra = 1",
    }
    test_sort(content, expected, { mode = "indent" })
end

T["sort_range"]["handles multiline values with indentation"] = function()
    local content = {
        "zebra = {",
        "    nested = true,",
        "}",
        "apple = 1",
    }
    local expected = {
        "apple = 1",
        "zebra = {",
        "    nested = true,",
        "}",
    }
    test_sort(content, expected, { mode = "indent" })
end

T["sort_range"]["sorts lines in line mode"] = function()
    local content = {
        "zebra",
        "apple",
        "mango",
    }
    local expected = {
        "apple",
        "mango",
        "zebra",
    }
    test_sort(content, expected, { mode = "line" })
end

T["sort_range"]["handles reverse sort"] = function()
    local content = {
        "apple",
        "mango",
        "zebra",
    }
    local expected = {
        "zebra",
        "mango",
        "apple",
    }
    test_sort(content, expected, { mode = "line", reverse = true })
end

T["sort_range"]["handles case insensitive (default)"] = function()
    local content = {
        "Zebra",
        "apple",
        "Mango",
    }
    local expected = {
        "apple",
        "Mango",
        "Zebra",
    }
    test_sort(content, expected, { mode = "line" })
end

T["sort_range"]["handles case sensitive"] = function()
    local content = {
        "Zebra",
        "apple",
        "Mango",
    }
    local expected = {
        "Mango",
        "Zebra",
        "apple",
    }
    test_sort(content, expected, { mode = "line", case_sensitive = true })
end

T["sort_range"]["handles numeric sort"] = function()
    local content = {
        "item10",
        "item2",
        "item1",
    }
    local expected = {
        "item1",
        "item2",
        "item10",
    }
    test_sort(content, expected, { mode = "line", numeric = true })
end

T["sort_range"]["returns false when no change"] = function()
    local content = {
        "apple",
        "mango",
        "zebra",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    local result = sorting.sort_range(bufnr, 0, #content - 1, { mode = "line" })

    MiniTest.expect.equality(result, false)
    helpers.delete_buffer(bufnr)
end

T["sort_range"]["returns true when changed"] = function()
    local content = {
        "zebra",
        "apple",
    }
    local bufnr = helpers.create_test_buffer(content, "lua")

    local result = sorting.sort_range(bufnr, 0, #content - 1, { mode = "line" })

    MiniTest.expect.equality(result, true)
    helpers.delete_buffer(bufnr)
end

T["sort_range"]["handles partial file range"] = function()
    local content = {
        "unchanged",
        "zebra",
        "apple",
        "unchanged",
    }
    local expected = {
        "unchanged",
        "apple",
        "zebra",
        "unchanged",
    }
    test_sort(content, expected, { mode = "line" }, 1, 2)
end

T["sort_range"]["handles single line (no-op)"] = function()
    local content = { "single line" }
    test_sort(content, content)
end

T["sort_range"]["handles empty buffer"] = function()
    local content = { "" }
    local bufnr = helpers.create_test_buffer(content, "lua")

    sorting.sort_range(bufnr, 0, 0, {})

    local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    MiniTest.expect.equality(result, { "" })

    helpers.delete_buffer(bufnr)
end

T["sort_file"] = MiniTest.new_set()

T["sort_file"]["sorts entire buffer"] = function()
    local content = {
        "zebra",
        "apple",
        "mango",
    }
    local expected = {
        "apple",
        "mango",
        "zebra",
    }

    local bufnr = helpers.create_test_buffer(content, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    sorting.sort_file({ mode = "line" })

    local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    MiniTest.expect.equality(result, expected)

    helpers.delete_buffer(bufnr)
end

T["auto mode"] = MiniTest.new_set()

T["auto mode"]["uses treesitter for lua tables"] = function()
    local content = {
        "local t = {",
        '    "zebra",',
        '    "apple",',
        "}",
    }
    local expected = {
        "local t = {",
        '    "apple",',
        '    "zebra",',
        "}",
    }
    test_sort(content, expected, { mode = "auto" })
end

T["auto mode"]["falls back to indent mode when treesitter not applicable"] = function()
    local content = {
        "zebra = 1",
        "apple = 2",
    }
    local expected = {
        "apple = 2",
        "zebra = 1",
    }
    test_sort(content, expected, { mode = "auto" })
end

T["indentation grouping"] = MiniTest.new_set()

T["indentation grouping"]["groups continued lines"] = function()
    -- Test with consistent indentation (no dedented closing brackets)
    local content = {
        "zebra_item:",
        "    nested1",
        "    nested2",
        "apple_item:",
        "    nested",
    }
    local expected = {
        "apple_item:",
        "    nested",
        "zebra_item:",
        "    nested1",
        "    nested2",
    }
    test_sort(content, expected, { mode = "indent" })
end

T["indentation grouping"]["handles blank lines"] = function()
    local content = {
        "zebra = 1",
        "",
        "apple = 2",
    }
    local expected = {
        "apple = 2",
        "zebra = 1",
        "",
    }
    test_sort(content, expected, { mode = "indent" })
end

T["indentation grouping"]["handles varying indentation"] = function()
    local content = {
        "zebra:",
        "    nested:",
        "        deep: value",
        "apple: simple",
    }
    local expected = {
        "apple: simple",
        "zebra:",
        "    nested:",
        "        deep: value",
    }
    test_sort(content, expected, { mode = "indent" })
end

-- Test with different filetypes
T["json sorting"] = MiniTest.new_set()

T["json sorting"]["sorts json array"] = function()
    local content = {
        "[",
        '    "zebra",',
        '    "apple",',
        "]",
    }
    local bufnr = helpers.create_test_buffer(content, "json")

    sorting.sort_range(bufnr, 0, #content - 1, { mode = "auto" })

    local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local expected = {
        "[",
        '    "apple",',
        '    "zebra",',
        "]",
    }

    MiniTest.expect.equality(result, expected)
    helpers.delete_buffer(bufnr)
end

T["python sorting"] = MiniTest.new_set()

T["python sorting"]["sorts python list"] = function()
    local content = {
        "items = [",
        '    "zebra",',
        '    "apple",',
        "]",
    }
    local bufnr = helpers.create_test_buffer(content, "python")

    sorting.sort_range(bufnr, 0, #content - 1, { mode = "auto" })

    local result = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local expected = {
        "items = [",
        '    "apple",',
        '    "zebra",',
        "]",
    }

    MiniTest.expect.equality(result, expected)
    helpers.delete_buffer(bufnr)
end

if vim.g.testing_mini_test == nil then MiniTest.run() end

return T
