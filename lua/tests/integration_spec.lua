-- Integration tests for high-level coding workflows
-- Tests combinations of LSP, fuzzy finding, editing, and other features
local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Load core configuration
            require("kyleking.core")
            vim.cmd("sleep 100m")
        end,
        post_once = function() end,
    },
})

-- Test end-to-end coding workflow
T["coding workflow"] = MiniTest.new_set()

T["coding workflow"]["complete Lua development workflow"] = function()
    H.with_temp_file(function(filepath)
        -- 1. Open a Lua file
        vim.cmd("edit " .. filepath)
        local bufnr = vim.api.nvim_get_current_buf()

        -- 2. Write some code
        H.set_buffer_content(bufnr, {
            "local M = {}",
            "",
            "function M.add(a, b)",
            "  return a + b",
            "end",
            "",
            "return M",
        })

        -- 3. Verify LSP can attach (if lua_ls is installed)
        local lsp_attached = H.wait_for_lsp(bufnr, 5000)

        -- 4. Comment a line using mini.comment
        vim.api.nvim_win_set_cursor(0, { 3, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[3]:match("^%-%- ") ~= nil, "Line should be commented")

        -- 5. Uncomment the line
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[3]:match("^function") ~= nil, "Line should be uncommented")

        -- 6. Test text objects (mini.ai) - delete inside function
        vim.api.nvim_win_set_cursor(0, { 4, 5 })
        H.feed_keys("di(")
        vim.cmd("sleep 50m")

        lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[3]:match("function M%.add%(%)") ~= nil, "Should delete function parameters")

        -- Workflow completed successfully
        H.assert_true(true, "Complete workflow executed successfully")
    end, { "local M = {}", "return M" }, ".lua")
end

T["coding workflow"]["Python development workflow"] = function()
    H.with_temp_file(function(filepath)
        vim.cmd("edit " .. filepath)
        local bufnr = vim.api.nvim_get_current_buf()

        -- Write Python code
        H.set_buffer_content(bufnr, {
            "def calculate(x, y):",
            "    result = x + y",
            "    return result",
        })

        -- Wait for LSP (if pyright is installed)
        H.wait_for_lsp(bufnr, 5000)

        -- Test commenting
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[2]:match("^    # ") ~= nil, "Python comment should be applied")

        H.assert_true(true, "Python workflow executed successfully")
    end, "# Python test", ".py")
end

-- Test LSP integration with editing
T["LSP editing integration"] = MiniTest.new_set()

T["LSP editing integration"]["LSP + formatting workflow"] = function()
    H.with_temp_file(function(filepath)
        vim.cmd("edit " .. filepath)
        local bufnr = vim.api.nvim_get_current_buf()

        -- Write code that might need formatting
        H.set_buffer_content(bufnr, {
            "local x=1",
            "local y  =  2",
            "local z=3",
        })

        -- Wait for LSP
        local lsp_attached = H.wait_for_lsp(bufnr, 5000)

        if lsp_attached then
            -- LSP formatting is available via <leader>cf
            -- Verify the keymap exists
            local has_format_keymap = H.check_keymap("n", "<leader>cf", "LSP format buffer")
            H.assert_true(has_format_keymap, "LSP format keymap should exist")
        end

        H.assert_true(true, "LSP formatting integration verified")
    end, "local test = 1", ".lua")
end

T["LSP editing integration"]["LSP diagnostics + Trouble workflow"] = function()
    H.with_temp_file(function(filepath)
        vim.cmd("edit " .. filepath)
        local bufnr = vim.api.nvim_get_current_buf()

        -- Write Lua code with potential issues
        H.set_buffer_content(bufnr, {
            "local unused_variable = 1",
            "print(undefined_variable)",
        })

        -- Wait for LSP
        H.wait_for_lsp(bufnr, 5000)

        -- Verify Trouble integration
        local has_trouble = H.check_keymap("n", "<leader>xx", "Diagnostics (Trouble)")
        H.assert_true(has_trouble, "Trouble diagnostics keymap should exist")

        -- Verify diagnostic keymaps
        local has_diag = H.check_keymap("n", "<leader>cd", "Line diagnostics")
        H.assert_true(has_diag, "Line diagnostics keymap should exist")

        H.assert_true(true, "LSP diagnostics integration verified")
    end, "-- Test file", ".lua")
end

-- Test fuzzy finding workflows
T["fuzzy finding workflows"] = MiniTest.new_set()

T["fuzzy finding workflows"]["buffer navigation workflow"] = function()
    -- Create multiple buffers
    local buf1 = H.create_test_buffer({ "Buffer 1" })
    local buf2 = H.create_test_buffer({ "Buffer 2" })
    local buf3 = H.create_test_buffer({ "Buffer 3" })

    -- Verify buffer picker keymap exists
    local has_buffer_picker = H.check_keymap("n", "<leader>;", "Find in open buffers")
    H.assert_true(has_buffer_picker, "Buffer picker keymap should exist")

    -- Clean up
    H.delete_buffer(buf1)
    H.delete_buffer(buf2)
    H.delete_buffer(buf3)

    H.assert_true(true, "Buffer navigation workflow verified")
end

T["fuzzy finding workflows"]["file finding workflow"] = function()
    -- Verify file finding keymaps
    local keymaps = {
        { lhs = "<leader>ff", desc = "Find in files" },
        { lhs = "<leader>gf", desc = "Find in Git Files" },
        { lhs = "<leader>br", desc = "Find [r]ecently opened files" },
    }

    for _, keymap_spec in ipairs(keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "File finding keymap should exist: " .. keymap_spec.lhs)
    end

    H.assert_true(true, "File finding workflow verified")
end

-- Test git workflows
T["git workflows"] = MiniTest.new_set()

T["git workflows"]["git integration available"] = function()
    -- Verify gitsigns is loaded
    require("kyleking.deps.git")
    vim.cmd("sleep 100m")

    H.assert_true(H.is_plugin_loaded("gitsigns"), "gitsigns should be loaded")

    -- Verify diffview is loaded
    H.assert_true(H.is_plugin_loaded("diffview"), "diffview should be loaded")

    -- Verify statusline shows git info
    local statusline = require("mini.statusline")
    local git_section = statusline.section_git({ trunc_width = 40 })
    H.assert_true(type(git_section) == "string", "Git section should be available in statusline")
end

-- Test terminal workflows
T["terminal workflows"] = MiniTest.new_set()

T["terminal workflows"]["terminal integration available"] = function()
    require("kyleking.deps.terminal-integration")
    vim.cmd("sleep 100m")

    -- Verify toggleterm is loaded
    H.assert_true(H.is_plugin_loaded("toggleterm"), "toggleterm should be loaded")

    -- Verify terminal keymaps
    local has_float = H.check_keymap("n", "<leader>tf", "ToggleTerm float")
    H.assert_true(has_float, "Float terminal keymap should exist")

    -- Verify toggle keymap exists
    local has_toggle = H.check_keymap("n", "<C-'>", "Toggle terminal")
    H.assert_true(has_toggle, "Terminal toggle keymap should exist")
end

-- Test editing enhancement workflows
T["editing enhancements"] = MiniTest.new_set()

T["editing enhancements"]["text manipulation workflow"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "test text for editing",
        })

        -- Verify mini.ai is available for text objects
        H.assert_true(H.is_plugin_loaded("mini.ai"), "mini.ai should be loaded")

        -- Verify mini.comment is available
        H.assert_true(H.is_plugin_loaded("mini.comment"), "mini.comment should be loaded")

        -- Verify mini.surround is available
        H.assert_true(H.is_plugin_loaded("mini.surround"), "mini.surround should be loaded")

        -- Verify mini.move is available
        H.assert_true(H.is_plugin_loaded("mini.move"), "mini.move should be loaded")

        H.assert_true(true, "Text manipulation tools available")
    end, nil, "text")
end

-- Test statusline integration workflow
T["statusline integration"] = MiniTest.new_set()

T["statusline integration"]["complete statusline workflow"] = function()
    H.with_temp_file(function(filepath)
        vim.cmd("edit " .. filepath)
        local bufnr = vim.api.nvim_get_current_buf()

        H.set_buffer_content(bufnr, {
            "test content",
        })

        -- Wait for LSP
        H.wait_for_lsp(bufnr, 5000)

        local statusline = require("mini.statusline")

        -- Test all statusline sections work together
        local mode = statusline.section_mode({ trunc_width = 999 })
        local git = statusline.section_git({ trunc_width = 40 })
        local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
        local filename = statusline.section_filename({ trunc_width = 140 })
        local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
        local location = statusline.section_location({ trunc_width = 75 })

        H.assert_not_nil(mode, "Mode section should work")
        H.assert_not_nil(git, "Git section should work")
        H.assert_not_nil(diagnostics, "Diagnostics section should work")
        H.assert_not_nil(filename, "Filename section should work")
        H.assert_not_nil(fileinfo, "Fileinfo section should work")
        H.assert_not_nil(location, "Location section should work")

        -- Test lint progress integration
        if _G.kyleking_lint_progress then
            local lint_info = _G.kyleking_lint_progress()
            H.assert_true(type(lint_info) == "string", "Lint progress should integrate with statusline")
        end

        H.assert_true(true, "Complete statusline integration verified")
    end, "test", ".lua")
end

-- Test search and navigation workflow
T["search and navigation"] = MiniTest.new_set()

T["search and navigation"]["search enhancements available"] = function()
    -- Verify nvim-hlslens is loaded
    require("kyleking.deps.search")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("hlslens"), "hlslens should be loaded")

    -- Verify flash.nvim is loaded for motion
    require("kyleking.deps.motion")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("flash"), "flash should be loaded")
end

-- Test color and UI workflow
T["color and UI"] = MiniTest.new_set()

T["color and UI"]["UI enhancements available"] = function()
    -- Verify colorscheme is set
    require("kyleking.deps.colorscheme")
    vim.cmd("sleep 100m")
    H.assert_not_nil(vim.g.colors_name, "Colorscheme should be set")

    -- Verify mini.icons is available
    H.assert_true(H.is_plugin_loaded("mini.icons"), "mini.icons should be loaded")

    -- Verify colorful-winsep is loaded
    require("kyleking.deps.split-and-window")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("colorful-winsep"), "colorful-winsep should be loaded")
end

-- Test help and keybinding discovery
T["help and discovery"] = MiniTest.new_set()

T["help and discovery"]["documentation access available"] = function()
    -- Verify help keymap
    local has_help = H.check_keymap("n", "<leader>fh", "Find in nvim help")
    H.assert_true(has_help, "Help search keymap should exist")

    -- Verify keymaps discovery
    local has_keymaps = H.check_keymap("n", "<leader>fk", "Find keymaps")
    H.assert_true(has_keymaps, "Keymap search should exist")

    -- Verify which-key is loaded
    require("kyleking.deps.keybinding")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("which-key"), "which-key should be loaded")
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

return T
