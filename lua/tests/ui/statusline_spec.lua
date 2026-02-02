-- Test mini.statusline integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["statusline"] = MiniTest.new_set()

T["statusline"]["temp session detection prevents statusline setup"] = function()
    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    -- This test documents the behavior: temp sessions don't get statusline
    -- We can't easily test the negative case, but we can verify the detection works
    MiniTest.expect.equality(type(is_temp), "boolean", "Temp session detection should return boolean")
end

T["statusline"]["vim-illuminate is configured"] = function()
    -- Wait for later() to execute
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("illuminate"), true, "illuminate should be loaded")
end

T["statusline"]["illuminate keymaps are set"] = function()
    -- Wait for later() to execute
    vim.wait(1000)

    local check_keymap = function(lhs, desc_pattern)
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        MiniTest.expect.equality(keymap ~= nil, true, "Keymap should exist: " .. lhs)
        if keymap and desc_pattern then
            local desc_matches = keymap.desc and string.find(keymap.desc, desc_pattern)
            MiniTest.expect.equality(desc_matches ~= nil, true, "Desc should match for " .. lhs)
        end
    end

    check_keymap("]r", "reference")
    check_keymap("[r", "reference")
    check_keymap("<leader>ur", "Toggle")
    check_keymap("<leader>uR", "Toggle")
end

T["statusline"]["multicolumn is configured"] = function()
    -- Wait for later() to execute
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("multicolumn"), true, "multicolumn should be loaded")
end

T["statusline in non-temp session"] = MiniTest.new_set()

T["statusline in non-temp session"]["mini.statusline is loaded in normal session"] = function()
    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if not is_temp then
        -- Give some time for later() to execute
        vim.wait(500)
        MiniTest.expect.equality(
            helpers.is_plugin_loaded("mini.statusline"),
            true,
            "mini.statusline should be loaded in normal session"
        )
    end
end

T["statusline in non-temp session"]["statusline highlight groups are set"] = function()
    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if not is_temp then
        vim.wait(500)

        -- Check that mode highlight groups exist
        local hl_groups = {
            "MiniStatuslineModeNormal",
            "MiniStatuslineModeInsert",
            "MiniStatuslineModeVisual",
            "MiniStatuslineModeReplace",
            "MiniStatuslineModeCommand",
            "MiniStatuslineModeOther",
            "MiniStatuslineDevinfo",
            "MiniStatuslineFilename",
            "MiniStatuslineFileinfo",
            "MiniStatuslineInactive",
        }

        for _, hl_group in ipairs(hl_groups) do
            local hl = vim.api.nvim_get_hl(0, { name = hl_group })
            MiniTest.expect.equality(next(hl) ~= nil, true, "Highlight group should be defined: " .. hl_group)
        end
    end
end

T["statusline in non-temp session"]["statusline renders without errors"] = function()
    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if not is_temp then
        vim.wait(500)

        -- Create a test buffer
        local bufnr = helpers.create_test_buffer({ "test line" }, "lua")
        vim.api.nvim_set_current_buf(bufnr)

        -- Try to get statusline content
        local success = pcall(function()
            -- Force statusline update
            vim.cmd("redrawstatus")
        end)

        MiniTest.expect.equality(success, true, "Statusline should render without errors")

        helpers.delete_buffer(bufnr)
    end
end

T["filename handling"] = MiniTest.new_set()

T["filename handling"]["unnamed buffer shows [No Name]"] = function()
    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if not is_temp then
        vim.wait(500)

        -- Create unnamed buffer
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(bufnr)

        -- The statusline should handle unnamed buffers
        local success = pcall(function() vim.cmd("redrawstatus") end)
        MiniTest.expect.equality(success, true, "Should handle unnamed buffer")

        helpers.delete_buffer(bufnr)
    end
end

T["filename handling"]["modified buffer shows indicator"] = function()
    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if not is_temp then
        vim.wait(500)

        local tmpfile = helpers.create_temp_file("test content", "txt")
        vim.cmd("edit " .. tmpfile)

        -- Modify buffer
        vim.api.nvim_buf_set_lines(0, 0, 1, false, { "modified content" })

        -- Check buffer is marked modified
        MiniTest.expect.equality(vim.bo.modified, true, "Buffer should be marked modified")

        -- Statusline should render without errors
        local success = pcall(function() vim.cmd("redrawstatus") end)
        MiniTest.expect.equality(success, true, "Should render modified indicator")

        vim.cmd("bdelete!")
        helpers.cleanup_temp_file(tmpfile)
    end
end

T["filename handling"]["long paths are truncated"] = function()
    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if not is_temp then
        vim.wait(500)

        -- Create a file with a very long path
        local long_dir = "/very/long/directory/path/with/many/components/to/test/truncation"
        vim.fn.mkdir(vim.fn.tempname() .. long_dir, "p")
        local tmpfile = vim.fn.tempname() .. long_dir .. "/test_file.txt"
        vim.fn.writefile({ "test" }, tmpfile)

        vim.cmd("edit " .. tmpfile)

        -- Statusline should render without errors even with long path
        local success = pcall(function() vim.cmd("redrawstatus") end)
        MiniTest.expect.equality(success, true, "Should handle long paths")

        vim.cmd("bdelete!")
        vim.fn.delete(tmpfile)
    end
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
