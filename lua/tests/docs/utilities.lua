return {
    title = "Utilities",
    see_also = {},
    desc = "Various utility plugins for patches, URLs, and spell checking.",
    source = "lua/kyleking/deps/utility.lua",

    notes = {
        "**patch_it.nvim** -- Apply LLM-generated patches with fuzzy matching:",
        "",
        "`<leader>paa` Apply patch -- prompts for target file",
        "`<leader>pap` Preview patch -- dry-run showing what would change",
        "`<leader>pab` Apply with auto-suggest -- suggests target from buffer name",
        "",
        "Workflow: get an LLM-generated patch, paste into a buffer (`:enew`), preview with `<leader>pap`, apply with `<leader>paa`, undo with `u`.",
        "",
        "Features: fuzzy matching tolerates whitespace differences, accepts patches with or without space-prefixed context lines, handles interleaved additions and removals within a hunk.",
        "",
        "Command: `:PatchApply path/to/target.lua`",
        "",
        "Lua API:",
        "```lua",
        'local patch_it = require("patch_it")',
        'patch_it.apply(patch_string, "target.lua")',
        'patch_it.apply_buffer("target.lua")',
        'patch_it.apply_buffer("target.lua", { preview = true })',
        "```",
        "",
        "See also: <https://github.com/KyleKing/patch_it.nvim>",
        "",
        "**gx.nvim** -- `gx` opens URL or file path under cursor",
        "",
        "**url-open** -- `<leader>uu` opens URL under cursor",
        "",
        "**vim-dirtytalk** -- extends spell dictionary with programming terms. `<leader>pzs` sorts the spell dictionary file",
        "",
        "**vim-spellsync** -- automatically syncs spell files",
    },

    grammars = {
        {
            pattern = "<leader>pa",
            desc = "Patch operations",
            tests = {
                {
                    name = "patch_it available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, patch_it = pcall(require, "patch_it")
                            if not ok then MiniTest.skip("patch_it plugin not installed") end
                            MiniTest.expect.equality(type(patch_it.apply), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "gx",
            desc = "Open URL/file under cursor",
            tests = {
                {
                    name = "gx functionality",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("gx", "n")
                            MiniTest.expect.equality(has_keymap, true, "Should have gx keymap in normal mode")
                        end,
                    },
                },
            },
        },
    },
}
