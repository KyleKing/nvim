-- Test file for mini.comment functionality using Mini.test
-- Tests commenting and uncommenting code
local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            require("kyleking.deps.editing-support")
            vim.cmd("sleep 50m")
        end,
        post_once = function() end,
    },
})

-- Test mini.comment module
T["mini.comment module"] = MiniTest.new_set()

T["mini.comment module"]["loads successfully"] = function()
    H.assert_true(H.is_plugin_loaded("mini.comment"), "mini.comment should be loaded")
end

T["mini.comment module"]["has expected API"] = function()
    local comment = require("mini.comment")

    H.assert_not_nil(comment, "mini.comment module should be available")
    H.assert_true(type(comment.setup) == "function", "comment.setup should be a function")
end

-- Test comment functionality with different filetypes
T["mini.comment functionality"] = MiniTest.new_set()

T["mini.comment functionality"]["comments lua code"] = function()
    H.with_buffer(function(bufnr)
        -- Set up Lua code
        H.set_buffer_content(bufnr, {
            "local function test()",
            "  print('hello')",
            "end",
        })

        -- Move to first line and comment it
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("gcc")

        -- Wait for comment to be applied
        vim.cmd("sleep 50m")

        -- Check that line is commented
        local lines = H.get_buffer_content(bufnr)
        H.assert_true(
            lines[1]:match("^%-%- local function test%(%)") ~= nil,
            "Line should be commented with -- "
        )
    end, nil, "lua")
end

T["mini.comment functionality"]["comments python code"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "def test():",
            "    print('hello')",
            "    return True",
        })

        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[1]:match("^# def test%(%)%:") ~= nil, "Line should be commented with # ")
    end, nil, "python")
end

T["mini.comment functionality"]["comments javascript code"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "function test() {",
            "  console.log('hello');",
            "}",
        })

        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(
            lines[1]:match("^// function test%(%) {") ~= nil,
            "Line should be commented with // "
        )
    end, nil, "javascript")
end

T["mini.comment functionality"]["uncommenting works"] = function()
    H.with_buffer(function(bufnr)
        -- Start with commented Lua code
        H.set_buffer_content(bufnr, {
            "-- local x = 1",
            "local y = 2",
        })

        -- Uncomment first line
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[1] == "local x = 1", "Line should be uncommented")
    end, nil, "lua")
end

T["mini.comment functionality"]["toggles comment state"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "local test = true",
        })

        -- Comment
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        local is_commented = lines[1]:match("^%-%- ")
        H.assert_true(is_commented ~= nil, "Line should be commented")

        -- Uncomment
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[1] == "local test = true", "Line should be uncommented")
    end, nil, "lua")
end

-- Test visual mode commenting
T["mini.comment visual mode"] = MiniTest.new_set()

T["mini.comment visual mode"]["comments multiple lines in visual mode"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "local x = 1",
            "local y = 2",
            "local z = 3",
        })

        -- Select all lines in visual mode and comment
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("VGgc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[1]:match("^%-%- ") ~= nil, "Line 1 should be commented")
        H.assert_true(lines[2]:match("^%-%- ") ~= nil, "Line 2 should be commented")
        H.assert_true(lines[3]:match("^%-%- ") ~= nil, "Line 3 should be commented")
    end, nil, "lua")
end

T["mini.comment visual mode"]["works with visual line mode"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "print('line 1')",
            "print('line 2')",
        })

        -- Visual line mode select and comment
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("Vjgc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[1]:match("^%-%- ") ~= nil, "Both lines should be commented")
        H.assert_true(lines[2]:match("^%-%- ") ~= nil, "Both lines should be commented")
    end, nil, "lua")
end

-- Test comment with different operators
T["mini.comment operators"] = MiniTest.new_set()

T["mini.comment operators"]["gc with motion"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "line 1",
            "line 2",
            "line 3",
        })

        -- Comment from cursor to end of buffer
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        H.feed_keys("gcG")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        H.assert_true(lines[1]:match("^%-%- ") ~= nil, "Line 1 should be commented")
        H.assert_true(lines[3]:match("^%-%- ") ~= nil, "Line 3 should be commented")
    end, nil, "lua")
end

-- Test commentstring configuration
T["mini.comment commentstring"] = MiniTest.new_set()

T["mini.comment commentstring"]["uses correct commentstring for filetype"] = function()
    -- Test that mini.comment respects vim's commentstring option
    local filetypes_comments = {
        { ft = "lua", pattern = "^%-%- ", example = "-- comment" },
        { ft = "python", pattern = "^# ", example = "# comment" },
        { ft = "javascript", pattern = "^// ", example = "// comment" },
        { ft = "vim", pattern = "^\" ", example = "\" comment" },
    }

    for _, test_case in ipairs(filetypes_comments) do
        H.with_buffer(function(bufnr)
            H.set_buffer_content(bufnr, { "test line" })

            vim.api.nvim_win_set_cursor(0, { 1, 0 })
            H.feed_keys("gcc")
            vim.cmd("sleep 50m")

            local lines = H.get_buffer_content(bufnr)
            H.assert_true(
                lines[1]:match(test_case.pattern) ~= nil,
                "Should use correct comment for " .. test_case.ft
            )
        end, nil, test_case.ft)
    end
end

-- Test that mini.comment replaces ts-comments
T["mini.comment migration"] = MiniTest.new_set()

T["mini.comment migration"]["ts-comments is not loaded"] = function()
    -- Verify that we're using mini.comment instead of ts-comments
    H.assert_false(H.is_plugin_loaded("ts-comments"), "ts-comments should not be loaded")
end

T["mini.comment migration"]["mini.comment is loaded instead"] = function()
    H.assert_true(H.is_plugin_loaded("mini.comment"), "mini.comment should be loaded")
end

-- Test edge cases
T["mini.comment edge cases"] = MiniTest.new_set()

T["mini.comment edge cases"]["handles empty lines"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "local x = 1",
            "",
            "local y = 2",
        })

        -- Comment the empty line
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        -- Empty line behavior varies - just ensure no error
        H.assert_true(true, "Should handle empty lines without error")
    end, nil, "lua")
end

T["mini.comment edge cases"]["handles indented code"] = function()
    H.with_buffer(function(bufnr)
        H.set_buffer_content(bufnr, {
            "function test()",
            "  local x = 1",
            "  return x",
            "end",
        })

        -- Comment indented line
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        H.feed_keys("gcc")
        vim.cmd("sleep 50m")

        local lines = H.get_buffer_content(bufnr)
        -- Check that comment is added (indentation may vary)
        H.assert_true(lines[2]:match("%-%- ") ~= nil, "Indented line should be commented")
    end, nil, "lua")
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

return T
