-- Test motion plugins (flash.nvim, nap.nvim, illuminate, bufjump)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["motion plugins"] = MiniTest.new_set()

T["motion plugins"]["motion module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.deps.motion") end)
end

T["flash.nvim"] = MiniTest.new_set()

T["flash.nvim"]["flash is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("flash"), true, "flash should be loaded")
end

T["flash.nvim"]["flash keymaps are set"] = function()
    vim.wait(1000)

    -- Check flash keymaps exist and have callable functions
    local check_flash_keymap = function(lhs, modes)
        for _, mode in ipairs(modes) do
            local keymap = vim.fn.maparg(lhs, mode, false, true)
            MiniTest.expect.equality(
                keymap ~= nil and keymap.lhs ~= nil,
                true,
                lhs .. " mapping should exist in " .. mode
            )

            -- Verify the mapping has a callable rhs (function or string)
            local has_callable = (type(keymap.callback) == "function")
                or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
            MiniTest.expect.equality(has_callable, true, lhs .. " should have callable rhs in " .. mode)
        end
    end

    check_flash_keymap("<a-s>", { "n", "x", "o" })
    check_flash_keymap("<a-S>", { "n" })
    check_flash_keymap("<c-s>", { "c" })
end

T["flash.nvim"]["flash jump is callable"] = function()
    vim.wait(1000)

    -- Verify flash.jump exists and is callable
    local flash = require("flash")
    MiniTest.expect.equality(type(flash.jump), "function", "flash.jump should be a function")
    MiniTest.expect.equality(type(flash.treesitter), "function", "flash.treesitter should be a function")
    MiniTest.expect.equality(type(flash.toggle), "function", "flash.toggle should be a function")
end

T["nap.nvim"] = MiniTest.new_set()

T["nap.nvim"]["nap is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("nap"), true, "nap should be loaded")
end

T["illuminate"] = MiniTest.new_set()

T["illuminate"]["illuminate is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("illuminate"), true, "illuminate should be loaded")
end

T["illuminate"]["illuminate keymaps are set"] = function()
    vim.wait(1000)

    local check_keymap = function(lhs, mode)
        local keymap = vim.fn.maparg(lhs, mode, false, true)
        MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, lhs .. " mapping should exist")

        -- Verify callable
        local has_callable = (type(keymap.callback) == "function")
            or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
        MiniTest.expect.equality(has_callable, true, lhs .. " should have callable rhs")
    end

    check_keymap("]r", "n") -- Next reference
    check_keymap("[r", "n") -- Previous reference
    check_keymap("<leader>ur", "n") -- Toggle
    check_keymap("<leader>uR", "n") -- Toggle buffer
end

T["illuminate"]["illuminate functions are callable"] = function()
    vim.wait(1000)

    local illuminate = require("illuminate")
    MiniTest.expect.equality(type(illuminate.toggle), "function", "illuminate.toggle should be a function")
    MiniTest.expect.equality(type(illuminate.toggle_buf), "function", "illuminate.toggle_buf should be a function")
    MiniTest.expect.equality(
        type(illuminate.goto_next_reference),
        "function",
        "illuminate.goto_next_reference should be a function"
    )
    MiniTest.expect.equality(
        type(illuminate.goto_prev_reference),
        "function",
        "illuminate.goto_prev_reference should be a function"
    )
end

T["bufjump"] = MiniTest.new_set()

T["bufjump"]["bufjump is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("bufjump"), true, "bufjump should be loaded")
end

T["bufjump"]["bufjump keymaps are set"] = function()
    vim.wait(1000)

    local check_keymap = function(lhs)
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, lhs .. " mapping should exist")

        -- Verify callable
        local has_callable = (type(keymap.callback) == "function")
            or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
        MiniTest.expect.equality(has_callable, true, lhs .. " should have callable rhs")
    end

    check_keymap("<leader>bn") -- Forward
    check_keymap("<leader>bp") -- Backward
    check_keymap("<leader>bN") -- Forward same buf
    check_keymap("<leader>bP") -- Backward same buf
end

T["bufjump"]["bufjump functions are callable"] = function()
    vim.wait(1000)

    local bufjump = require("bufjump")
    MiniTest.expect.equality(type(bufjump.forward), "function", "bufjump.forward should be a function")
    MiniTest.expect.equality(type(bufjump.backward), "function", "bufjump.backward should be a function")
    MiniTest.expect.equality(
        type(bufjump.forward_same_buf),
        "function",
        "bufjump.forward_same_buf should be a function"
    )
    MiniTest.expect.equality(
        type(bufjump.backward_same_buf),
        "function",
        "bufjump.backward_same_buf should be a function"
    )
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
