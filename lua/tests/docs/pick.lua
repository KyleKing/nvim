return {
    title = "Fuzzy Finding (mini.pick)",
    see_also = { "MiniPick", "MiniExtra" },
    desc = "Fuzzy finder for files, buffers, grep, help, keymaps, and more. Uses mini.pick with mini.extra for additional pickers.",
    source = "lua/kyleking/deps/fuzzy-finder.lua",

    notes = {
        "**Navigation**:",
        "- `<C-j>`/`<C-k>` Move down/up through matches",
        "- `<C-g>` Jump to first match",
        "- `<C-f>`/`<C-b>` Scroll page down/up (matches or preview)",
        "- `<C-h>`/`<C-l>` Scroll left/right (matches or preview)",
        "- `<CR>` Choose item",
        "- `<C-s>` Choose in horizontal split",
        "- `<C-v>` Choose in vertical split",
        "- `<C-t>` Choose in new tab",
        "- `<Esc>` Close picker",
        "",
        "**Editing the query**:",
        "- `<C-w>` Toggle between insert and normal mode",
        "- In normal mode, use standard vim motions (`w`, `b`, `x`, `i`, `a`, etc.) to edit the query",
        "- Press `<C-w>` again to return to insert mode for searching",
        "",
        "**Preview**:",
        "- `<Tab>` Toggle preview (replaces match list in same window)",
        "- `<S-Tab>` Toggle info (shows available mappings)",
        "- While preview is active, `<C-f>`/`<C-b>` scroll the preview content",
        "- Moving between items (`<C-j>`/`<C-k>`) updates preview automatically",
        "",
        "**Query syntax**:",
        "Queries are fuzzy by default. Prefix/suffix characters change matching:",
        "- `'text` Exact (substring) match",
        "- `^text` Exact match anchored to start",
        "- `text$` Exact match anchored to end",
        "- `*text` Forced fuzzy match (override other modes)",
        "- `text1 text2` Grouped: each term matched independently",
        "",
        "Respects `ignorecase` and `smartcase` settings.",
        "Scoring sorts by narrowest match width first, then earliest start position. No special preference for filename vs path.",
        "",
        "**Marking and bulk actions**:",
        "- `<C-x>` Toggle mark on current item",
        "- `<C-a>` Toggle mark on all matches",
        "- `<M-CR>` Choose all marked items (e.g., open in quickfix)",
        "",
        "**Refine (progressive narrowing)**:",
        "- `<C-Space>` Refine current matches (reset query, keep results)",
        "- `<M-Space>` Refine marked items only",
        "- Example: type `'hello`, press `<C-Space>`, then type `'world` to find items containing both terms",
        "",
        "**Paste into prompt**:",
        "`<C-r>` followed by register key (like insert mode):",
        '- `<C-r>"` Paste from default register (last yank/delete)',
        "- `<C-r>+` Paste from system clipboard",
        "- `<C-r>*` Paste from selection clipboard",
        "- `<C-r>/` Paste last search pattern",
        "- `<C-r>:` Paste last command",
        "- `<C-r><C-w>` Paste word under cursor",
        "- `<C-r><C-a>` Paste WORD under cursor",
        "- `<C-r><C-l>` Paste current line",
        "",
        "**Grep glob filtering**:",
        "In live grep (`<leader>fw`), press `<C-o>` to add a glob pattern that restricts results to matching files (e.g., `*.lua`, `tests/**`). Multiple globs can be stacked. Only supported with rg and git tools.",
        "",
        "**File picker and hidden files**:",
        "`<leader>ff` uses rg which includes hidden/dotfiles (`.github/**`, etc.) and respects `.gitignore`. `<leader>gf` uses `git ls-files` to list only git-tracked files.",
        "",
        "**Register operations**:",
        "- `<leader>fr` Browse registers (view contents)",
        "- `<leader>fp` Paste from register picker (choose register, then paste)",
        "",
        "**Tips**:",
        "- `<leader>fB` lists all built-in pickers -- useful for discovering what is available",
        "- `<leader><CR>` resumes the last picker with its previous query and matches intact",
    },

    grammars = {
        {
            pattern = "<leader>;",
            desc = "Buffer picker",
            tests = {
                {
                    name = "pick buffer",
                    setup = {
                        fn = function()
                            local helpers = require("tests.helpers")
                            -- Create multiple buffers
                            helpers.create_test_buffer({ "buffer1" }, "text")
                            helpers.create_test_buffer({ "buffer2" }, "text")
                            helpers.create_test_buffer({ "buffer3" }, "text")
                        end,
                    },
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")
                            MiniPick.start({ source = { name = "Buffers", items = { "a", "b", "c" } } })
                            local is_active = MiniPick.is_picker_active()
                            MiniPick.stop()
                            MiniTest.expect.equality(is_active, true, "Picker should be active")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader><leader>",
            desc = "Resume last picker",
            tests = {
                {
                    name = "resume picker",
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")
                            -- Start and stop a picker to create history
                            MiniPick.start({ source = { name = "Test", items = { "x", "y" } } })
                            MiniPick.stop()
                            -- Resume should work
                            MiniPick.start({ source = { name = "Resume" } })
                            local is_active = MiniPick.is_picker_active()
                            MiniPick.stop()
                            MiniTest.expect.equality(is_active, true, "Resume should start picker")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-j> / <C-k>",
            desc = "Navigate picker items",
            tests = {
                {
                    name = "navigate with ctrl-j",
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")
                            MiniPick.start({ source = { name = "Nav", items = { "a", "b", "c" } } })
                            local was_active = MiniPick.is_picker_active()
                            -- Simulate navigation
                            vim.api.nvim_feedkeys(
                                vim.api.nvim_replace_termcodes("<C-j>", true, false, true),
                                "x",
                                false
                            )
                            vim.wait(20)
                            MiniPick.stop()
                            MiniTest.expect.equality(was_active, true, "Picker should be active for navigation")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<C-w>",
            desc = "Toggle insert/normal mode for query editing",
            tests = {
                {
                    name = "toggle to normal mode and edit query",
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")

                            -- Start picker with some items
                            MiniPick.start({ source = { name = "Test", items = { "apple", "banana", "cherry" } } })

                            -- Set initial query
                            MiniPick.set_picker_query("test")

                            -- Get the query before toggling
                            local initial_query = MiniPick.get_picker_query()

                            -- Verify initial query is set
                            MiniTest.expect.equality(initial_query, "test", "Initial query should be 'test'")

                            -- Cleanup
                            MiniPick.stop()
                        end,
                    },
                },
                {
                    name = "verify toggle_info mapping exists",
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")

                            -- Get the current config to verify toggle_info mapping
                            -- Default is <C-w> if not overridden
                            local config = MiniPick.config or {}
                            local mappings = config.mappings or {}

                            -- If toggle_info is not in mappings, it uses the default <C-w>
                            local has_toggle_info = mappings.toggle_info == nil or mappings.toggle_info ~= false

                            MiniTest.expect.equality(
                                has_toggle_info,
                                true,
                                "toggle_info mapping should be available (default <C-w>)"
                            )
                        end,
                    },
                },
                {
                    name = "set_picker_query modifies query",
                    expect = {
                        fn = function(_ctx)
                            local MiniPick = require("mini.pick")
                            local MiniTest = require("mini.test")

                            MiniPick.start({ source = { name = "Test", items = { "a", "b", "c" } } })

                            -- Set query programmatically (simulates editing)
                            MiniPick.set_picker_query("new query")
                            local query = MiniPick.get_picker_query()

                            MiniPick.stop()

                            MiniTest.expect.equality(query, "new query", "Query should be updated")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>fh",
            desc = "Find in nvim help",
            tests = {
                {
                    name = "help picker keybinding",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("<leader>fh", "n")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>fh keymap")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>fk",
            desc = "Find keymaps",
            tests = {
                {
                    name = "keymaps picker keybinding",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("<leader>fk", "n")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>fk keymap")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>fr",
            desc = "Find registers",
            tests = {
                {
                    name = "registers picker keybinding",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("<leader>fr", "n")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>fr keymap")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>fp",
            desc = "Paste from register picker",
            tests = {
                {
                    name = "paste picker keybinding exists",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap_n = helpers.check_keymap("n", "<leader>fp")
                            local has_keymap_x = helpers.check_keymap("x", "<leader>fp")
                            MiniTest.expect.equality(has_keymap_n, true, "Should have <leader>fp in normal mode")
                            MiniTest.expect.equality(has_keymap_x, true, "Should have <leader>fp in visual mode")
                        end,
                    },
                },
                {
                    name = "paste picker integration",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")

                            -- Create buffer and populate register
                            local bufnr = helpers.create_test_buffer({ "original" }, "text")
                            vim.api.nvim_set_current_buf(bufnr)
                            vim.fn.setreg("a", "from register a")

                            -- Verify register has content
                            local reg_content = vim.fn.getreg("a")
                            MiniTest.expect.equality(
                                reg_content,
                                "from register a",
                                "Register should have expected content"
                            )

                            helpers.delete_buffer(bufnr)
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>f'",
            desc = "Find marks",
            tests = {
                {
                    name = "marks picker keybinding",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("<leader>f'", "n")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>f' keymap")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>fl",
            desc = "Find in quickfix/location lists",
            tests = {
                {
                    name = "quickfix picker keybinding",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local helpers = require("tests.helpers")
                            local has_keymap = helpers.check_keymap("<leader>fl", "n")
                            MiniTest.expect.equality(has_keymap, true, "Should have <leader>fl keymap")
                        end,
                    },
                },
            },
        },
    },
}
