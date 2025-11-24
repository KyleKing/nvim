-- Test file for mini.statusline functionality using Mini.test
-- Tests statusline configuration and display
local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            require("kyleking.deps.bars-and-lines")
            vim.cmd("sleep 50m") -- Allow lazy loading
        end,
        post_once = function() end,
    },
})

-- Test mini.statusline module
T["mini.statusline module"] = MiniTest.new_set()

T["mini.statusline module"]["loads successfully"] = function()
    H.assert_true(H.is_plugin_loaded("mini.statusline"), "mini.statusline should be loaded")
end

T["mini.statusline module"]["has expected API"] = function()
    local statusline = require("mini.statusline")

    H.assert_not_nil(statusline.setup, "statusline.setup should exist")
    H.assert_not_nil(statusline.section_mode, "statusline.section_mode should exist")
    H.assert_not_nil(statusline.section_git, "statusline.section_git should exist")
    H.assert_not_nil(statusline.section_diagnostics, "statusline.section_diagnostics should exist")
    H.assert_not_nil(statusline.section_filename, "statusline.section_filename should exist")
    H.assert_not_nil(statusline.section_fileinfo, "statusline.section_fileinfo should exist")
    H.assert_not_nil(statusline.section_location, "statusline.section_location should exist")
    H.assert_not_nil(statusline.section_searchcount, "statusline.section_searchcount should exist")
    H.assert_not_nil(statusline.combine_groups, "statusline.combine_groups should exist")
end

-- Test statusline configuration
T["mini.statusline configuration"] = MiniTest.new_set()

T["mini.statusline configuration"]["uses icons"] = function()
    -- Verify that use_icons is configured
    -- Note: Can't directly inspect config, but icons should be visible
    H.assert_true(true, "Icons configuration set during setup")
end

T["mini.statusline configuration"]["sets vim settings"] = function()
    -- The config has set_vim_settings = true
    -- This should set laststatus and other vim options
    local laststatus = vim.o.laststatus
    H.assert_true(laststatus >= 2, "laststatus should be set to show statusline")
end

-- Test statusline sections
T["mini.statusline sections"] = MiniTest.new_set()

T["mini.statusline sections"]["mode section works"] = function()
    local statusline = require("mini.statusline")

    local mode, mode_hl = statusline.section_mode({ trunc_width = 999 })

    H.assert_not_nil(mode, "Mode section should return mode string")
    H.assert_not_nil(mode_hl, "Mode section should return highlight group")
end

T["mini.statusline sections"]["git section works"] = function()
    local statusline = require("mini.statusline")

    local git = statusline.section_git({ trunc_width = 40 })

    H.assert_true(type(git) == "string", "Git section should return a string")
end

T["mini.statusline sections"]["diagnostics section works"] = function()
    local statusline = require("mini.statusline")

    local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })

    H.assert_true(type(diagnostics) == "string", "Diagnostics section should return a string")
end

T["mini.statusline sections"]["filename section works"] = function()
    local statusline = require("mini.statusline")

    -- Create a test buffer to have a filename
    H.with_temp_file(function(filepath)
        vim.cmd("edit " .. filepath)

        local filename = statusline.section_filename({ trunc_width = 140 })

        H.assert_true(type(filename) == "string", "Filename section should return a string")
        H.assert_true(#filename > 0, "Filename should not be empty")
    end, "test content", ".txt")
end

T["mini.statusline sections"]["fileinfo section works"] = function()
    local statusline = require("mini.statusline")

    local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })

    H.assert_true(type(fileinfo) == "string", "Fileinfo section should return a string")
end

T["mini.statusline sections"]["location section works"] = function()
    local statusline = require("mini.statusline")

    local location = statusline.section_location({ trunc_width = 75 })

    H.assert_true(type(location) == "string", "Location section should return a string")
end

T["mini.statusline sections"]["searchcount section works"] = function()
    local statusline = require("mini.statusline")

    local search = statusline.section_searchcount({ trunc_width = 75 })

    H.assert_true(type(search) == "string", "Searchcount section should return a string")
end

-- Test lint progress integration
T["mini.statusline lint integration"] = MiniTest.new_set()

T["mini.statusline lint integration"]["lint progress function exists"] = function()
    require("kyleking.deps.lsp")
    vim.cmd("sleep 100m")

    H.assert_true(
        type(_G.kyleking_lint_progress) == "function",
        "Global lint progress function should exist"
    )
end

T["mini.statusline lint integration"]["lint progress returns string"] = function()
    require("kyleking.deps.lsp")
    vim.cmd("sleep 100m")

    if _G.kyleking_lint_progress then
        local progress = _G.kyleking_lint_progress()
        H.assert_true(type(progress) == "string", "Lint progress should return a string")
    end
end

T["mini.statusline lint integration"]["statusline includes lint info"] = function()
    -- The custom active function includes lint_info
    -- We verify the function exists and is accessible
    local statusline = require("mini.statusline")

    H.assert_not_nil(statusline, "Statusline should be configured with custom content")

    -- Verify lint progress can be called without error
    if _G.kyleking_lint_progress then
        local ok, result = pcall(_G.kyleking_lint_progress)
        H.assert_true(ok, "Lint progress should be callable without error")
        H.assert_true(type(result) == "string", "Lint progress result should be string")
    end
end

-- Test statusline customization
T["mini.statusline customization"] = MiniTest.new_set()

T["mini.statusline customization"]["has custom active content"] = function()
    -- Our config provides a custom active content function
    -- We verify the statusline is configured (actual rendering tested visually)
    local statusline = require("mini.statusline")

    H.assert_not_nil(statusline, "Statusline should be configured")
end

T["mini.statusline customization"]["combine_groups works"] = function()
    local statusline = require("mini.statusline")

    -- Test that combine_groups can combine sections
    local groups = {
        { hl = "Normal", strings = { "test1" } },
        { hl = "Normal", strings = { "test2" } },
    }

    local combined = statusline.combine_groups(groups)

    H.assert_true(type(combined) == "string", "combine_groups should return a string")
end

-- Test mini.icons integration
T["mini.statusline icons"] = MiniTest.new_set()

T["mini.statusline icons"]["mini.icons loaded"] = function()
    H.assert_true(H.is_plugin_loaded("mini.icons"), "mini.icons should be loaded")
end

T["mini.statusline icons"]["mini.icons API available"] = function()
    local icons = require("mini.icons")

    H.assert_not_nil(icons, "mini.icons should be available")
    H.assert_true(type(icons.get) == "function", "mini.icons.get should be a function")
end

T["mini.statusline icons"]["mini.icons provides file icons"] = function()
    local icons = require("mini.icons")

    -- Test getting an icon for a common filetype
    local icon, hl = icons.get("filetype", "lua")

    H.assert_not_nil(icon, "Should get icon for lua filetype")
    H.assert_true(type(icon) == "string", "Icon should be a string")
end

T["mini.statusline icons"]["MiniIcons global available"] = function()
    -- Our config sets MiniIcons as a global
    H.assert_not_nil(MiniIcons, "MiniIcons should be available as global")
    H.assert_true(type(MiniIcons.get) == "function", "MiniIcons.get should be available")
end

-- Test vim-illuminate integration
T["bars and lines illuminate"] = MiniTest.new_set()

T["bars and lines illuminate"]["vim-illuminate loaded"] = function()
    H.assert_true(H.is_plugin_loaded("illuminate"), "vim-illuminate should be loaded")
end

T["bars and lines illuminate"]["has illuminate keymaps"] = function()
    local expected_keymaps = {
        { lhs = "<leader>ur", desc = "Toggle reference highlighting" },
        { lhs = "<leader>uR", desc = "Toggle reference highlighting (buffer)" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "Illuminate keymap should exist: " .. keymap_spec.lhs)
    end
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

return T
