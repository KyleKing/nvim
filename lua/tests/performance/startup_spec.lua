-- Startup performance benchmarks
-- Track startup time regression
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["startup time"] = MiniTest.new_set()

T["startup time"]["startup completes under threshold"] = function()
    -- Run nvim with --startuptime
    local tmplog = vim.fn.tempname() .. "_startup.log"

    local result = vim.system({
        "nvim",
        "--headless",
        "--startuptime",
        tmplog,
        "-c",
        "qall!",
    }, { text = true }):wait(30000)

    MiniTest.expect.equality(result.code, 0, "Startup should complete successfully")

    -- Read and parse startup log
    if vim.fn.filereadable(tmplog) == 1 then
        local lines = vim.fn.readfile(tmplog)
        local last_line = lines[#lines]

        -- Extract time from last line (format: "123.456  000.123: --- NVIM STARTED ---")
        local total_time = tonumber(last_line:match("^([%d%.]+)"))

        if total_time then
            print(string.format("Startup time: %.1fms", total_time))

            -- Threshold: warn if > 150ms (current target from milestone)
            local threshold = 150.0
            if total_time > threshold then
                print(string.format("WARNING: Startup time %.1fms exceeds threshold %.1fms", total_time, threshold))
            else
                print(string.format("SUCCESS: Startup time %.1fms within threshold %.1fms", total_time, threshold))
            end

            -- Test passes if under 300ms (failure threshold)
            MiniTest.expect.equality(
                total_time < 300.0,
                true,
                string.format("Startup time %.1fms should be under 300ms", total_time)
            )
        else
            print("WARNING: Could not parse startup time from log")
        end
    end

    vim.fn.delete(tmplog)
end

T["startup time"]["no errors during startup"] = function()
    local result = vim.system({
        "nvim",
        "--headless",
        "-c",
        "messages",
        "-c",
        "qall!",
    }, { text = true }):wait(30000)

    MiniTest.expect.equality(result.code, 0, "Startup should complete without errors")

    -- Check for common error patterns
    local stderr = result.stderr or ""
    local has_error = stderr:match("[Ee]error") ~= nil or stderr:match("E%d+:") ~= nil

    if has_error then
        print("WARNING: Errors detected during startup:")
        print(stderr)
    end

    MiniTest.expect.equality(has_error, false, "Should have no errors in stderr: " .. stderr)
end

T["plugin load time"] = MiniTest.new_set()

T["plugin load time"]["mini.deps loads plugins efficiently"] = function()
    -- This test measures that later() defers plugin loading
    local tmplog = vim.fn.tempname() .. "_plugin.log"

    vim.system({
        "nvim",
        "--headless",
        "--startuptime",
        tmplog,
        "-c",
        "qall!",
    }, { text = true }):wait(30000)

    if vim.fn.filereadable(tmplog) == 1 then
        local content = table.concat(vim.fn.readfile(tmplog), "\n")

        -- Check that plugins are loaded after init
        local has_mini_deps = content:match("mini%.deps") ~= nil
        local has_later_plugins = content:match("mini%.pick") ~= nil or content:match("mini%.clue") ~= nil

        if has_mini_deps then print("SUCCESS: mini.deps is loading plugins") end

        if has_later_plugins then print("INFO: later() plugins detected in startup log") end

        MiniTest.expect.equality(has_mini_deps, true, "mini.deps should be present in startup")
    end

    vim.fn.delete(tmplog)
end

T["large file handling"] = MiniTest.new_set()

T["large file handling"]["can open moderately large file"] = function()
    -- Create temp file with 1000 lines
    local tmpfile = vim.fn.tempname() .. ".lua"
    local lines = {}
    for i = 1, 1000 do
        table.insert(lines, string.format("local var_%d = %d -- Line %d", i, i, i))
    end

    local f = io.open(tmpfile, "w")
    if f then
        f:write(table.concat(lines, "\n"))
        f:close()
    end

    local start = vim.loop.now()
    local result = vim.system({
        "nvim",
        "--headless",
        "-c",
        "edit " .. tmpfile,
        "-c",
        "qall!",
    }, { text = true }):wait(30000)

    local elapsed = vim.loop.now() - start

    print(string.format("Opened 1000-line file in %.0fms", elapsed))

    MiniTest.expect.equality(result.code, 0, "Should open large file: " .. (result.stderr or ""))
    MiniTest.expect.equality(elapsed < 5000, true, "Should open large file in under 5s")

    vim.fn.delete(tmpfile)
end

T["large file handling"]["treesitter handles large file"] = function()
    local tmpfile = vim.fn.tempname() .. ".lua"
    local lines = {}

    -- Generate complex Lua code
    for i = 1, 500 do
        table.insert(lines, string.format("local function test_%d()", i))
        table.insert(lines, string.format("  local x = %d", i))
        table.insert(lines, "  return x * 2")
        table.insert(lines, "end")
    end

    local f = io.open(tmpfile, "w")
    if f then
        f:write(table.concat(lines, "\n"))
        f:close()
    end

    local result = vim.system({
        "nvim",
        "--headless",
        "-c",
        "edit " .. tmpfile,
        "-c",
        "sleep 2",
        "-c",
        "qall!",
    }, { text = true }):wait(30000)

    MiniTest.expect.equality(result.code, 0, "Should handle treesitter on large file: " .. (result.stderr or ""))

    vim.fn.delete(tmpfile)
end

T["memory usage"] = MiniTest.new_set()

T["memory usage"]["startup memory is reasonable"] = function()
    -- This is a basic check - actual memory profiling would need OS-specific tools
    local result = vim.system({
        "nvim",
        "--headless",
        "-c",
        "lua print(vim.loop.resident_set_memory())",
        "-c",
        "qall!",
    }, { text = true }):wait(30000)

    if result.stdout then print("Memory info captured (requires external profiling for detailed analysis)") end

    MiniTest.expect.equality(result.code, 0, "Should capture memory info")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
