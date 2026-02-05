return {
    title = "Editing Support Utilities",
    see_also = { "operators", "surround", "ai", "move" },
    desc = "Trailing whitespace highlighting, list editing, preview, and other editing utilities.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "**Trailing whitespace**:",
        "- `<leader>ut` - Toggle trailing whitespace highlighting",
        "- `:Trim` - Remove trailing whitespace from buffer",
        "",
        "**List editing**:",
        "Custom utilities for markdown/djot list continuation and manipulation.",
        "",
        "**Preview**:",
        "CLI-based markdown/djot preview in browser using pandoc or djot CLI.",
    },

    grammars = {
        {
            pattern = "<leader>ut",
            desc = "Toggle trailing whitespace highlighting",
            tests = {
                {
                    name = "toggle exists and survives multiple calls",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Verify keybinding exists
                            MiniTest.expect.equality(
                                helpers.check_keymap("<leader>ut", "n"),
                                true,
                                "trailspace toggle keymap"
                            )

                            -- Test multiple toggle cycles
                            local ok, MiniTrailspace = pcall(require, "mini.trailspace")
                            if ok then
                                -- Get the keymap function
                                local keymaps = vim.api.nvim_get_keymap("n")
                                local toggle_map = nil
                                for _, map in ipairs(keymaps) do
                                    if map.lhs == " ut" then
                                        toggle_map = map
                                        break
                                    end
                                end

                                if toggle_map and toggle_map.callback then
                                    -- Call toggle multiple times - should not error
                                    local success1, err1 = pcall(toggle_map.callback)
                                    MiniTest.expect.equality(
                                        success1,
                                        true,
                                        "First toggle call should succeed: " .. tostring(err1)
                                    )

                                    local success2, err2 = pcall(toggle_map.callback)
                                    MiniTest.expect.equality(
                                        success2,
                                        true,
                                        "Second toggle call should succeed: " .. tostring(err2)
                                    )

                                    local success3, err3 = pcall(toggle_map.callback)
                                    MiniTest.expect.equality(
                                        success3,
                                        true,
                                        "Third toggle call should succeed: " .. tostring(err3)
                                    )
                                end
                            end
                        end,
                    },
                },
            },
        },
    },
}
