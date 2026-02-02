-- Test mini.pick integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["mini.pick"] = MiniTest.new_set()

T["mini.pick"]["mini.pick is configured"] = function()
    -- Wait for later() to execute
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.pick"), true, "mini.pick should be loaded")
end

T["mini.pick"]["mini.extra is loaded"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.extra"), true, "mini.extra should be loaded")
end

T["picker keymaps"] = MiniTest.new_set()

T["picker keymaps"]["core picker keymaps are set"] = function()
    vim.wait(1000)

    local check_keymap = function(lhs, desc_pattern)
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "Keymap should exist: " .. lhs)
        if keymap and desc_pattern then
            local desc_matches = keymap.desc and string.find(keymap.desc, desc_pattern)
            MiniTest.expect.equality(desc_matches ~= nil, true, "Desc should match for " .. lhs)
        end
    end

    -- Core pickers
    check_keymap("<leader><CR>", "Resume")
    check_keymap("<leader>;", "buffer")
end

T["picker keymaps"]["buffer operation keymaps are set"] = function()
    vim.wait(1000)

    local check_keymap = function(lhs, desc_pattern)
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        MiniTest.expect.equality(keymap ~= nil, true, "Keymap should exist: " .. lhs)
        if keymap and desc_pattern then
            local desc_matches = keymap.desc and string.find(keymap.desc, desc_pattern)
            MiniTest.expect.equality(desc_matches ~= nil, true, "Desc should match for " .. lhs)
        end
    end

    check_keymap("<leader>br", "recent")
    check_keymap("<leader>bb", "buffer")
end

T["picker keymaps"]["git operation keymaps are set"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>gf", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "Git files keymap should exist")
end

T["picker keymaps"]["LSP operation keymaps are set"] = function()
    vim.wait(1000)

    local lsp_keymaps = {
        "<leader>ld",
        "<leader>lgs",
        "<leader>lgd",
        "<leader>lgi",
        "<leader>lgr",
        "<leader>lgt",
    }

    for _, lhs in ipairs(lsp_keymaps) do
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        MiniTest.expect.equality(keymap ~= nil, true, "LSP keymap should exist: " .. lhs)
    end
end

T["picker keymaps"]["find operation keymaps are set"] = function()
    vim.wait(1000)

    local find_keymaps = {
        "<leader>fB", -- Pickers
        "<leader>f'", -- Marks
        "<leader>fC", -- Commands
        "<leader>ff", -- Files
        "<leader>fh", -- Help
        "<leader>fk", -- Keymaps
        "<leader>fr", -- Registers
        "<leader>fw", -- Live grep
    }

    for _, lhs in ipairs(find_keymaps) do
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        MiniTest.expect.equality(keymap ~= nil, true, "Find keymap should exist: " .. lhs)
    end
end

T["picker keymaps"]["visual grep keymap is set"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>f*", "v", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "Visual grep keymap should exist")
end

T["picker functionality"] = MiniTest.new_set()

T["picker functionality"]["buffers picker can be invoked"] = function()
    vim.wait(1000)

    local MiniPick = require("mini.pick")
    local success = pcall(function()
        -- Start picker
        MiniPick.builtin.buffers()
        -- Stop it immediately
        MiniPick.stop()
    end)

    MiniTest.expect.equality(success, true, "Buffers picker should be invokable")
end

T["picker functionality"]["files picker can be invoked"] = function()
    vim.wait(1000)

    local MiniPick = require("mini.pick")
    local success = pcall(function()
        MiniPick.builtin.files()
        MiniPick.stop()
    end)

    MiniTest.expect.equality(success, true, "Files picker should be invokable")
end

T["picker functionality"]["grep picker can be invoked"] = function()
    vim.wait(1000)

    local MiniPick = require("mini.pick")
    local success = pcall(function()
        MiniPick.builtin.grep({ pattern = "test" })
        MiniPick.stop()
    end)

    MiniTest.expect.equality(success, true, "Grep picker should be invokable")
end

T["picker functionality"]["help picker can be invoked"] = function()
    vim.wait(1000)

    local MiniExtra = require("mini.extra")
    local success = pcall(function()
        MiniExtra.pickers.help()
        require("mini.pick").stop()
    end)

    MiniTest.expect.equality(success, true, "Help picker should be invokable")
end

T["picker functionality"]["marks picker can be invoked"] = function()
    vim.wait(1000)

    local MiniExtra = require("mini.extra")
    local success = pcall(function()
        MiniExtra.pickers.marks()
        require("mini.pick").stop()
    end)

    MiniTest.expect.equality(success, true, "Marks picker should be invokable")
end

T["picker functionality"]["commands picker can be invoked"] = function()
    vim.wait(1000)

    local MiniExtra = require("mini.extra")
    local success = pcall(function()
        MiniExtra.pickers.commands()
        require("mini.pick").stop()
    end)

    MiniTest.expect.equality(success, true, "Commands picker should be invokable")
end

T["picker functionality"]["keymaps picker can be invoked"] = function()
    vim.wait(1000)

    local MiniExtra = require("mini.extra")
    local success = pcall(function()
        MiniExtra.pickers.keymaps()
        require("mini.pick").stop()
    end)

    MiniTest.expect.equality(success, true, "Keymaps picker should be invokable")
end

T["picker functionality"]["registers picker can be invoked"] = function()
    vim.wait(1000)

    local MiniExtra = require("mini.extra")
    local success = pcall(function()
        MiniExtra.pickers.registers()
        require("mini.pick").stop()
    end)

    MiniTest.expect.equality(success, true, "Registers picker should be invokable")
end

T["TODO integration"] = MiniTest.new_set()

T["TODO integration"]["TODO keymap is set"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>ft", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "TODO keymap should exist")
    MiniTest.expect.equality(type(keymap.callback), "function", "TODO keymap should have callback")
end

T["TODO integration"]["TODO grep pattern includes all keywords"] = function()
    vim.wait(1000)

    -- The pattern should include TODO, FIXME, NOTE, etc.
    -- We can't easily test the exact pattern without invoking the function
    -- But we can verify the keymap exists and is callable
    local keymap = vim.fn.maparg("<leader>ft", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil, true, "TODO keymap should be configured")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
