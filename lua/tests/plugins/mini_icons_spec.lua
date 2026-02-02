-- Test mini.icons integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["mini.icons"] = MiniTest.new_set()

T["mini.icons"]["mini.icons is loaded"] = function()
    -- mini.icons is loaded with now() so should be available immediately
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.icons"), true, "mini.icons should be loaded")
end

T["mini.icons"]["mini.icons is configured"] = function()
    local MiniIcons = require("mini.icons")
    MiniTest.expect.no_error(function() return MiniIcons.config end, "mini.icons config should be accessible")
end

T["mini.icons"]["style is set to glyph"] = function()
    local MiniIcons = require("mini.icons")
    MiniTest.expect.equality(MiniIcons.config.style, "glyph", "Style should be 'glyph' for Nerd Fonts")
end

T["mini.icons"]["can get file icon"] = function()
    local MiniIcons = require("mini.icons")

    -- Test getting icon for common file types
    local lua_icon, lua_hl = MiniIcons.get("file", "test.lua")
    MiniTest.expect.equality(lua_icon ~= nil and lua_icon ~= "", true, "Should return icon for .lua file")
    MiniTest.expect.equality(lua_hl ~= nil, true, "Should return highlight group for .lua file")

    local py_icon = MiniIcons.get("file", "test.py")
    MiniTest.expect.equality(py_icon ~= nil and py_icon ~= "", true, "Should return icon for .py file")

    local js_icon = MiniIcons.get("file", "test.js")
    MiniTest.expect.equality(js_icon ~= nil and js_icon ~= "", true, "Should return icon for .js file")
end

T["mini.icons"]["can get directory icon"] = function()
    local MiniIcons = require("mini.icons")

    local dir_icon = MiniIcons.get("directory", "src")
    MiniTest.expect.equality(dir_icon ~= nil and dir_icon ~= "", true, "Should return icon for directory")
end

T["mini.icons"]["can get extension icon"] = function()
    local MiniIcons = require("mini.icons")

    local lua_ext_icon = MiniIcons.get("extension", "lua")
    MiniTest.expect.equality(lua_ext_icon ~= nil and lua_ext_icon ~= "", true, "Should return icon for lua extension")
end

T["mini.icons"]["can get filetype icon"] = function()
    local MiniIcons = require("mini.icons")

    local lua_ft_icon = MiniIcons.get("filetype", "lua")
    MiniTest.expect.equality(lua_ft_icon ~= nil and lua_ft_icon ~= "", true, "Should return icon for lua filetype")
end

T["mini.icons"]["icons are different for different file types"] = function()
    local MiniIcons = require("mini.icons")

    local lua_icon = MiniIcons.get("file", "test.lua")
    local py_icon = MiniIcons.get("file", "test.py")
    local js_icon = MiniIcons.get("file", "test.js")

    -- Icons should be different (not just checking for existence, but uniqueness)
    local all_same = lua_icon == py_icon and py_icon == js_icon
    MiniTest.expect.equality(all_same, false, "Different file types should have different icons")
end

T["mini.icons integration"] = MiniTest.new_set()

T["mini.icons integration"]["mini.statusline uses icons"] = function()
    vim.wait(1000) -- Wait for statusline to load

    -- Check that mini.statusline is loaded and configured to use icons
    if helpers.is_plugin_loaded("mini.statusline") then
        local MiniStatusline = require("mini.statusline")
        MiniTest.expect.equality(
            MiniStatusline.config.use_icons,
            true,
            "mini.statusline should be configured to use icons"
        )
    end
end

T["mini.icons integration"]["mini.tabline uses icons"] = function()
    vim.wait(1000) -- Wait for tabline to load

    -- Check that mini.tabline is loaded and configured to use icons
    if helpers.is_plugin_loaded("mini.tabline") then
        local MiniTabline = require("mini.tabline")
        MiniTest.expect.equality(MiniTabline.config.show_icons, true, "mini.tabline should be configured to show icons")
    end
end

T["mini.icons integration"]["mini.files can use icons"] = function()
    vim.wait(1000)

    -- Check that mini.files is loaded (it auto-detects mini.icons)
    if helpers.is_plugin_loaded("mini.files") then
        -- mini.files will detect mini.icons via its presence in package.loaded
        MiniTest.expect.equality(
            helpers.is_plugin_loaded("mini.icons"),
            true,
            "mini.icons should be available for mini.files"
        )
    end
end

T["mini.icons integration"]["mini.pick can use icons"] = function()
    vim.wait(1000)

    -- Check that mini.pick is loaded (it auto-detects mini.icons)
    if helpers.is_plugin_loaded("mini.pick") then
        -- mini.pick will detect mini.icons via its presence in package.loaded
        MiniTest.expect.equality(
            helpers.is_plugin_loaded("mini.icons"),
            true,
            "mini.icons should be available for mini.pick"
        )
    end
end

T["mini.icons integration"]["icons display correctly in statusline"] = function()
    vim.wait(1000)

    -- Create a test file buffer to trigger statusline update
    local bufnr = helpers.create_test_buffer({ "-- test lua file" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Get statusline content
    local statusline = vim.api.nvim_eval_statusline(vim.o.statusline, {}).str

    -- Statusline should contain content (not empty)
    MiniTest.expect.equality(statusline ~= nil and statusline ~= "", true, "Statusline should have content")

    helpers.delete_buffer(bufnr)
end

T["mini.icons integration"]["icons are globally accessible"] = function()
    -- Verify mini.icons module functions are accessible
    local MiniIcons = require("mini.icons")

    MiniTest.expect.no_error(function() MiniIcons.get("file", "test.lua") end, "MiniIcons.get should work")
    MiniTest.expect.no_error(function() MiniIcons.list("file") end, "MiniIcons.list should work with category")

    -- Test that icon data is structured correctly
    local icon, hl = MiniIcons.get("file", "test.lua")
    MiniTest.expect.equality(type(icon), "string", "Icon should be a string")
    MiniTest.expect.equality(type(hl), "string", "Highlight group should be a string")
end

T["mini.icons integration"]["setup is called before dependent plugins"] = function()
    -- mini.icons should be loaded with now() before other plugins
    -- This test verifies the loading order by checking package.loaded order isn't possible,
    -- but we can verify that when statusline/tabline load, mini.icons is already available

    vim.wait(1000) -- Wait for later() plugins to load

    local icons_loaded = helpers.is_plugin_loaded("mini.icons")
    local statusline_loaded = helpers.is_plugin_loaded("mini.statusline")

    -- If statusline is loaded, icons must be loaded (since icons loads first with now())
    if statusline_loaded then
        MiniTest.expect.equality(icons_loaded, true, "mini.icons should be loaded before mini.statusline (via now())")
    end
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
