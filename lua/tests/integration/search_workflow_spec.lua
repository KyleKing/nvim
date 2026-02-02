-- Test search and navigation workflow
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["search workflow"] = MiniTest.new_set()

T["search workflow"]["mini.pick is available"] = function()
    vim.wait(1000)

    local MiniPick = require("mini.pick")
    MiniTest.expect.equality(type(MiniPick.builtin), "table", "mini.pick builtin should be available")
end

T["search workflow"]["file search is configured"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>ff", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>ff should be mapped")
end

T["search workflow"]["live grep is configured"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>fw", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>fw should be mapped")
end

T["search workflow"]["buffer search is configured"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>;", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>; should be mapped")
end

T["search workflow"]["help search is configured"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>fh", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>fh should be mapped")
end

T["search workflow"]["flash motion is available"] = function()
    vim.wait(1000)

    local flash = require("flash")
    MiniTest.expect.equality(type(flash.jump), "function", "flash.jump should be available")
end

T["search workflow"]["illuminate is available"] = function()
    vim.wait(1000)

    local illuminate = require("illuminate")
    MiniTest.expect.equality(type(illuminate.toggle), "function", "illuminate should be available")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
