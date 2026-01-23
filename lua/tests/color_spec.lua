-- Test file for color.lua using Mini.test
local MiniTest = require("mini.test")

-- Define a new test set properly
local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Do any setup before each test case
        end,
        post_once = function()
            -- Clean up after all tests
        end,
    },
})

-- Test case for the color module initialization
T["color module"] = MiniTest.new_set()

T["color module"].initialization = function()
    -- Load the module
    require("kyleking.deps.color")

    -- Check that CCC is loaded
    MiniTest.expect.equality(package.loaded.ccc ~= nil, true, "CCC plugin should be loaded")

    -- Check that the CCC plugin is set up
    local ccc = require("ccc")
    MiniTest.expect.equality(ccc.get_config().default_color, "#40BFBF", "Default color should be set correctly")

    -- Verify keymaps are set
    local check_keymap = function(lhs, cmd, desc)
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        MiniTest.expect.equality(keymap ~= nil, true, "Keymap should exist: " .. lhs)
        if keymap then
            MiniTest.expect.equality(keymap.rhs, cmd, "Command should match for keymap: " .. lhs)
            MiniTest.expect.equality(keymap.desc, desc, "Description should match for keymap: " .. lhs)
        end
    end

    check_keymap("<leader>ucC", "<cmd>CccHighlighterToggle<cr>", "Toggle colorizer")
    check_keymap("<leader>ucc", "<cmd>CccConvert<cr>", "Convert color")
    check_keymap("<leader>ucp", "<cmd>CccPick<cr>", "Pick Color")

    -- Verify autocommands are set
    local has_autocmd = function(pattern, callback_check)
        local found = false
        for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ pattern = pattern })) do
            if callback_check(autocmd) then
                found = true
                break
            end
        end
        MiniTest.expect.equality(found, true, "Autocmd should exist for pattern: " .. pattern)
    end

    has_autocmd(
        "*:[vV\\x16]*",
        function(autocmd) return autocmd.desc == "Disable Color Highlight when entering visual mode" end
    )

    has_autocmd(
        "[vV\\x16]*:*",
        function(autocmd) return autocmd.desc == "Enable Color Highlight when leaving visual mode" end
    )
end

-- Test color highlighting functionality
T["color module"].highlighting = function()
    -- Create a temporary buffer with sample color codes
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "Color examples:",
        "#FF0000 - Red",
        "#00FF00 - Green",
        "#0000FF - Blue",
        "#40BFBF - Default color",
    })

    -- Switch to the buffer
    vim.api.nvim_set_current_buf(bufnr)

    -- Enable highlighting
    vim.cmd("CccHighlighterEnable")

    -- Allow some time for highlighting
    vim.cmd("sleep 100m")

    -- Check that highlighting exists (basic check)
    local ns = vim.api.nvim_get_namespaces()["ccc.nvim"]
    MiniTest.expect.equality(ns ~= nil, true, "CCC.nvim namespace should exist")

    local has_highlights = false
    if ns then
        for _ in ipairs(vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})) do
            has_highlights = true
            break
        end
    end
    MiniTest.expect.equality(has_highlights, true, "Color highlighting should be applied")

    -- Clean up
    vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

-- Return the test set for discovery by the test runner
return T
