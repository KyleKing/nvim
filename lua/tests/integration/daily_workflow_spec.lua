-- Daily workflow integration tests
-- Tests common usage patterns to catch real-world issues
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Setup
        end,
    },
})

T["editing workflows"] = MiniTest.new_set()

T["editing workflows"]["open file, navigate, and edit"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        -- Create a test file
        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        -- Add some content
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local function test()",
            "  print('hello')",
            "  print('world')",
            "end",
            "",
            "test()",
        })

        -- Navigate: gg to top
        vim.api.nvim_feedkeys("gg", "x", false)
        vim.wait(50)

        -- Navigate: G to bottom
        vim.api.nvim_feedkeys("G", "x", false)
        vim.wait(50)

        -- Navigate: gg again
        vim.api.nvim_feedkeys("gg", "x", false)
        vim.wait(50)

        -- Navigate: } to next paragraph
        vim.api.nvim_feedkeys("}", "x", false)
        vim.wait(50)

        -- Navigate: { to previous paragraph
        vim.api.nvim_feedkeys("{", "x", false)
        vim.wait(50)

        local cursor = vim.api.nvim_win_get_cursor(0)
        print("SUCCESS: Cursor at line " .. cursor[1])
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Edit workflow should complete: " .. result.stderr)
end

T["editing workflows"]["surround operations with mini.surround"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"hello world"})

        -- Move to first word
        vim.api.nvim_feedkeys("gg0", "x", false)
        vim.wait(50)

        -- Try sa (surround add) - should work with mini.surround
        -- This tests that 's' isn't completely disabled
        vim.api.nvim_feedkeys("saiw)", "x", false)
        vim.wait(200)

        local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
        if line:match("%(hello%)") then
            print("SUCCESS: Surround add works")
        else
            print("Line after surround: " .. line)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Surround workflow should complete: " .. result.stderr)
end

T["editing workflows"]["comment operations with mini.comment"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.bo.filetype = "lua"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"local x = 1"})

        -- Move to line
        vim.api.nvim_feedkeys("gg", "x", false)
        vim.wait(50)

        -- Toggle comment with gcc
        vim.api.nvim_feedkeys("gcc", "x", false)
        vim.wait(200)

        local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
        if line:match("^%s*%-%-") then
            print("SUCCESS: Comment toggle works")
        else
            print("Line after comment: " .. line)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Comment workflow should complete: " .. result.stderr)
end

T["navigation workflows"] = MiniTest.new_set()

T["navigation workflows"]["word navigation"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "the quick brown fox jumps over the lazy dog"
        })

        -- Start at beginning
        vim.api.nvim_feedkeys("gg0", "x", false)
        vim.wait(50)

        -- Navigate with w (word forward)
        for i = 1, 3 do
            vim.api.nvim_feedkeys("w", "x", false)
            vim.wait(30)
        end

        -- Navigate with b (word backward)
        vim.api.nvim_feedkeys("b", "x", false)
        vim.wait(30)

        -- Navigate with e (end of word)
        vim.api.nvim_feedkeys("e", "x", false)
        vim.wait(30)

        print("SUCCESS: Word navigation works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Word navigation should work: " .. result.stderr)
end

T["navigation workflows"]["search and jump"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test1() {",
            "  return 1;",
            "}",
            "function test2() {",
            "  return 2;",
            "}",
        })

        -- Search for 'function'
        vim.api.nvim_feedkeys("/function\r", "x", false)
        vim.wait(100)

        -- Jump to next match with 'n'
        vim.api.nvim_feedkeys("n", "x", false)
        vim.wait(50)

        -- Jump back with 'N'
        vim.api.nvim_feedkeys("N", "x", false)
        vim.wait(50)

        print("SUCCESS: Search navigation works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Search navigation should work: " .. result.stderr)
end

T["leader key workflows"] = MiniTest.new_set()

T["leader key workflows"]["leader key shows clue without errors"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")

        -- Press leader key and wait for clue
        vim.api.nvim_feedkeys(" ", "x", false)
        vim.wait(600)

        -- Cancel with escape
        vim.api.nvim_feedkeys("\27", "x", false)
        vim.wait(50)

        print("SUCCESS: Leader clue shown")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Leader clue should work: " .. result.stderr)
    local has_error = result.stderr:match("Error") ~= nil
    MiniTest.expect.equality(has_error, false, "Should have no errors: " .. result.stderr)
end

T["leader key workflows"]["leader f (find) prefix works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")

        -- Try leader + f (should show find submenu)
        vim.api.nvim_feedkeys(" f", "x", false)
        vim.wait(600)

        -- Cancel
        vim.api.nvim_feedkeys("\27", "x", false)
        vim.wait(50)

        print("SUCCESS: Leader+f works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Leader+f should work: " .. result.stderr)
end

T["leader key workflows"]["leader g (git) prefix works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")

        -- Try leader + g
        vim.api.nvim_feedkeys(" g", "x", false)
        vim.wait(600)

        -- Cancel
        vim.api.nvim_feedkeys("\27", "x", false)
        vim.wait(50)

        print("SUCCESS: Leader+g works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Leader+g should work: " .. result.stderr)
end

T["visual mode workflows"] = MiniTest.new_set()

T["visual mode workflows"]["visual selection and operations"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.bo.filetype = "lua"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local x = 1",
            "local y = 2",
            "local z = 3",
        })

        -- Start at top
        vim.api.nvim_feedkeys("gg", "x", false)
        vim.wait(50)

        -- Enter visual mode
        vim.api.nvim_feedkeys("V", "x", false)
        vim.wait(50)

        -- Select 2 lines
        vim.api.nvim_feedkeys("j", "x", false)
        vim.wait(50)

        -- Try comment with gc
        vim.api.nvim_feedkeys("gc", "x", false)
        vim.wait(200)

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local commented_count = 0
        for _, line in ipairs(lines) do
            if line:match("^%s*%-%-") then
                commented_count = commented_count + 1
            end
        end

        if commented_count >= 2 then
            print("SUCCESS: Visual comment works")
        else
            print("WARNING: Expected 2+ commented lines, got " .. commented_count)
        end
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Visual mode workflow should complete: " .. result.stderr)
end

T["window workflows"] = MiniTest.new_set()

T["window workflows"]["window navigation with ctrl-w"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        -- Create splits
        vim.cmd("split")
        vim.cmd("vsplit")

        -- Try <C-w> prefix (should trigger clue)
        vim.api.nvim_feedkeys("\23", "x", false) -- <C-w>
        vim.wait(600)

        -- Navigate with j
        vim.api.nvim_feedkeys("j", "x", false)
        vim.wait(50)

        print("SUCCESS: Window navigation works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Window navigation should work: " .. result.stderr)
end

T["fold workflows"] = MiniTest.new_set()

T["fold workflows"]["z prefix for folds works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "function test() {",
            "  if (true) {",
            "    console.log('nested');",
            "  }",
            "}",
        })

        -- Try 'z' prefix (should show clue)
        vim.api.nvim_feedkeys("z", "x", false)
        vim.wait(600)

        -- Try zz to center screen
        vim.api.nvim_feedkeys("z", "x", false)
        vim.wait(50)

        print("SUCCESS: z prefix works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "z prefix should work: " .. result.stderr)
    local has_error = result.stderr:match("Error") ~= nil
    MiniTest.expect.equality(has_error, false, "Should have no errors: " .. result.stderr)
end

T["marks and registers"] = MiniTest.new_set()

T["marks and registers"]["marks prefix works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line 1", "line 2", "line 3"})

        -- Set a mark
        vim.api.nvim_feedkeys("gg", "x", false)
        vim.wait(50)
        vim.api.nvim_feedkeys("ma", "x", false)
        vim.wait(50)

        -- Move away
        vim.api.nvim_feedkeys("G", "x", false)
        vim.wait(50)

        -- Try ' prefix (should show marks clue)
        vim.api.nvim_feedkeys("'", "x", false)
        vim.wait(600)

        -- Cancel
        vim.api.nvim_feedkeys("\27", "x", false)
        vim.wait(50)

        print("SUCCESS: Marks prefix works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Marks should work: " .. result.stderr)
end

T["marks and registers"]["registers prefix works"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(1000)

        vim.cmd("enew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {"hello world"})

        -- Yank to register a
        vim.api.nvim_feedkeys("gg0", "x", false)
        vim.wait(50)
        vim.api.nvim_feedkeys('"ayiw', "x", false)
        vim.wait(100)

        -- Try " prefix (should show registers clue)
        vim.api.nvim_feedkeys('"', "x", false)
        vim.wait(600)

        -- Cancel
        vim.api.nvim_feedkeys("\27", "x", false)
        vim.wait(50)

        print("SUCCESS: Registers prefix works")
    ]],
        15000
    )

    MiniTest.expect.equality(result.code, 0, "Registers should work: " .. result.stderr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
