-- Test codanna.nvim integration (local plugin from ~/Developer/kyleking)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["codanna"] = MiniTest.new_set()

T["codanna"]["setup configures mini.pick as preferred picker"] = function()
    local codanna = require("codanna")
    MiniTest.expect.equality(codanna.config.preferred_picker, "mini", "Config should prefer mini.pick")

    local ok, mini_picker = pcall(require, "codanna.mini")
    MiniTest.expect.equality(ok and next(mini_picker) ~= nil, true, "mini.pick backend should be available")
end

T["codanna"]["exec surfaces CLI errors instead of raising"] = function()
    if vim.fn.executable("codanna") ~= 1 then
        MiniTest.skip("codanna not installed")
        return
    end

    local data, err = require("codanna.core").exec("mcp", { "find_symbol", "name:nonexistent_symbol_xyz" })
    MiniTest.expect.equality(data, nil, "Missing symbol should return no data")
    MiniTest.expect.equality(type(err), "string", "Error message should be returned")
end

if ... == nil then MiniTest.run() end
return T
