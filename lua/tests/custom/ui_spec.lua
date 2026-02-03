local MiniTest = require("mini.test")
local ui = require("kyleking.utils.ui")

local T = MiniTest.new_set({ hooks = {} })

T["create_centered_window"] = MiniTest.new_set()

T["create_centered_window"]["creates window with default ratio"] = function()
    local config = ui.create_centered_window()

    MiniTest.expect.equality(type(config.width), "number")
    MiniTest.expect.equality(type(config.height), "number")
    MiniTest.expect.equality(type(config.row), "number")
    MiniTest.expect.equality(type(config.col), "number")
    MiniTest.expect.equality(config.border, "rounded")

    -- Verify dimensions are reasonable (not zero, not larger than screen)
    MiniTest.expect.equality(config.width > 0, true)
    MiniTest.expect.equality(config.height > 0, true)
    MiniTest.expect.equality(config.width <= vim.o.columns, true)
    MiniTest.expect.equality(config.height <= vim.o.lines, true)
end

T["create_centered_window"]["respects custom ratio"] = function()
    local small_config = ui.create_centered_window({ ratio = 0.5 })
    local large_config = ui.create_centered_window({ ratio = 0.9 })

    -- Smaller ratio should produce smaller dimensions
    MiniTest.expect.equality(small_config.width < large_config.width, true)
    MiniTest.expect.equality(small_config.height < large_config.height, true)

    -- Verify centering (row/col should position window in center)
    local expected_row_small = math.floor((vim.o.lines - small_config.height) / 2)
    local expected_col_small = math.floor((vim.o.columns - small_config.width) / 2)
    MiniTest.expect.equality(small_config.row, expected_row_small)
    MiniTest.expect.equality(small_config.col, expected_col_small)
end

T["create_centered_window"]["accepts custom border style"] = function()
    local config = ui.create_centered_window({ border = "single" })
    MiniTest.expect.equality(config.border, "single")
end

T["create_centered_window"]["accepts optional parameters"] = function()
    local config = ui.create_centered_window({
        relative = "cursor",
        style = "minimal",
        anchor = "NW",
    })

    MiniTest.expect.equality(config.relative, "cursor")
    MiniTest.expect.equality(config.style, "minimal")
    MiniTest.expect.equality(config.anchor, "NW")
end

T["create_centered_window"]["handles edge cases"] = function()
    -- Very small ratio
    local tiny = ui.create_centered_window({ ratio = 0.1 })
    MiniTest.expect.equality(tiny.width > 0, true)
    MiniTest.expect.equality(tiny.height > 0, true)

    -- Maximum ratio (0.99 to avoid rounding issues at 1.0)
    local huge = ui.create_centered_window({ ratio = 0.99 })
    MiniTest.expect.equality(huge.width <= vim.o.columns, true)
    MiniTest.expect.equality(huge.height <= vim.o.lines, true)
end

if ... == nil then MiniTest.run() end

return T
