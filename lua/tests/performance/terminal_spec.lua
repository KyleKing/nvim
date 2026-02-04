local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clear any existing terminal state
            package.loaded["kyleking.deps.terminal-integration"] = nil
        end,
        post_case = function()
            -- Cleanup terminals
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal" then
                    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
                end
            end
            -- Cleanup tabs
            while #vim.api.nvim_list_tabpages() > 1 do
                vim.cmd("tablast | tabclose!")
            end
        end,
    },
})

T["terminal performance"] = MiniTest.new_set()

-- Benchmark: Terminal buffer creation
T["terminal performance"]["terminal creation is fast"] = function()
    local start_time = vim.uv.hrtime()

    -- Create terminal buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.fn.termopen({ vim.o.shell })

    -- Wait for terminal to be ready
    vim.wait(500, function() return vim.b[bufnr].terminal_job_id ~= nil end)

    local elapsed_ms = (vim.uv.hrtime() - start_time) / 1000000

    -- Terminal creation should be fast (< 500ms)
    MiniTest.expect.equality(elapsed_ms < 500, true, string.format("Terminal creation took %.2fms", elapsed_ms))

    -- Cleanup
    vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- Benchmark: Statusline refresh in terminal
T["terminal performance"]["statusline refresh in terminal is fast"] = function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.fn.termopen({ vim.o.shell })

    -- Wait for terminal to be ready
    vim.wait(500, function() return vim.b[bufnr].terminal_job_id ~= nil end)

    -- Force statusline to be set up
    vim.cmd("doautocmd BufEnter")

    local iterations = 100
    local start_time = vim.uv.hrtime()

    -- Simulate statusline refreshes (happens on every mode change, cursor move, etc.)
    for _ = 1, iterations do
        vim.cmd("redrawstatus")
    end

    local elapsed_ms = (vim.uv.hrtime() - start_time) / 1000000
    local per_refresh = elapsed_ms / iterations

    -- Each statusline refresh should be < 5ms in terminal buffers
    MiniTest.expect.equality(
        per_refresh < 5,
        true,
        string.format("Statusline refresh took %.2fms per call (%.2fms total)", per_refresh, elapsed_ms)
    )

    vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- Benchmark: Mode changes in terminal
T["terminal performance"]["mode changes in terminal are fast"] = function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.fn.termopen({ vim.o.shell })

    -- Wait for terminal to be ready
    vim.wait(500, function() return vim.b[bufnr].terminal_job_id ~= nil end)

    local iterations = 50
    local start_time = vim.uv.hrtime()

    -- Simulate ModeChanged autocmds (the expensive operation we optimized)
    for _ = 1, iterations do
        vim.cmd("doautocmd ModeChanged")
    end

    local elapsed_ms = (vim.uv.hrtime() - start_time) / 1000000
    local per_change = elapsed_ms / iterations

    -- ModeChanged autocmd should be fast in terminals (< 2ms each, skips expensive ops)
    MiniTest.expect.equality(
        per_change < 2,
        true,
        string.format("ModeChanged took %.2fms per event (%.2fms total)", per_change, elapsed_ms)
    )

    vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- Benchmark: Terminal output handling
T["terminal performance"]["terminal output handling is fast"] = function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)

    local start_time = vim.uv.hrtime()

    -- Create terminal with command that produces output
    local chan_id = vim.fn.termopen({ "sh", "-c", "for i in {1..100}; do echo line $i; done" })

    -- Wait for command to complete
    vim.wait(2000, function() return vim.fn.jobwait({ chan_id }, 0)[1] ~= -1 end)

    local elapsed_ms = (vim.uv.hrtime() - start_time) / 1000000

    -- Terminal output handling should be fast (< 2000ms for 100 lines)
    MiniTest.expect.equality(elapsed_ms < 2000, true, string.format("Output handling took %.2fms", elapsed_ms))

    -- Verify output was received
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    MiniTest.expect.equality(#lines > 50, true, "Should have received output")

    vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- Benchmark: Project root detection is cached
T["terminal performance"]["project root detection uses cache"] = function()
    local project_tools = require("find-relative-executable")
    project_tools.clear_cache()

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)

    -- First call (cold cache)
    local start_time = vim.uv.hrtime()
    local result1 = project_tools.get_current_project_root()
    local cold_time = (vim.uv.hrtime() - start_time) / 1000000

    -- Second call (warm cache)
    start_time = vim.uv.hrtime()
    local result2 = project_tools.get_current_project_root()
    local warm_time = (vim.uv.hrtime() - start_time) / 1000000

    -- Cached call should be significantly faster (< 1ms)
    MiniTest.expect.equality(
        warm_time < 1,
        true,
        string.format("Cached call took %.2fms (cold: %.2fms)", warm_time, cold_time)
    )

    -- Results should be identical
    MiniTest.expect.equality(result1, result2)

    vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- Benchmark: VCS detection is cached
T["terminal performance"]["vcs detection uses cache"] = function()
    local project_tools = require("find-relative-executable")
    project_tools.clear_cache()

    local test_path = vim.fn.getcwd()

    -- First call (cold cache)
    local start_time = vim.uv.hrtime()
    local result1 = project_tools.get_vcs_root(test_path)
    local cold_time = (vim.uv.hrtime() - start_time) / 1000000

    -- Second call (warm cache)
    start_time = vim.uv.hrtime()
    local result2 = project_tools.get_vcs_root(test_path)
    local warm_time = (vim.uv.hrtime() - start_time) / 1000000

    -- Cached call should be significantly faster (< 1ms)
    MiniTest.expect.equality(
        warm_time < 1,
        true,
        string.format("Cached VCS call took %.2fms (cold: %.2fms)", warm_time, cold_time)
    )

    -- Results should be identical
    if result1 == nil then
        MiniTest.expect.equality(result2, nil)
    else
        MiniTest.expect.equality(result1.type, result2.type)
        MiniTest.expect.equality(result1.root, result2.root)
    end
end

-- Benchmark: Illuminate is disabled in terminals
T["terminal performance"]["illuminate disabled in terminal buffers"] = function()
    -- Load illuminate
    local ok, _illuminate = pcall(require, "illuminate")
    if not ok then
        MiniTest.skip("vim-illuminate not available")
        return
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo[bufnr].buftype = "terminal"

    -- Trigger illuminate events
    vim.cmd("doautocmd CursorMoved")
    vim.wait(300) -- Wait for illuminate delay

    -- Check that illuminate is disabled for this buffer
    -- We verify by checking if should_enable returns false
    local config = require("illuminate.config")
    local should_enable = config.get().should_enable
    if should_enable then
        local enabled = should_enable(bufnr)
        MiniTest.expect.equality(enabled, false, "Illuminate should be disabled in terminal buffers")
    end

    vim.api.nvim_buf_delete(bufnr, { force = true })
end

if ... == nil then MiniTest.run() end

return T
