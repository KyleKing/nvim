-- Performance tracking module
-- Inspired by Prometheus-style metrics for production monitoring

local M = {}

-- Metrics storage
M.metrics = {
    startup_time = 0,
    plugin_load_times = {},
    operation_counts = {},
    operation_durations = {},
}

-- Track startup time
M.start_time = vim.loop.hrtime()

-- Calculate startup time (call this at the end of init)
M.finish_startup = function()
    M.metrics.startup_time = (vim.loop.hrtime() - M.start_time) / 1e6 -- Convert to milliseconds
end

-- Track plugin load time
M.track_plugin = function(name, fn)
    local start = vim.loop.hrtime()
    fn()
    local elapsed = (vim.loop.hrtime() - start) / 1e6 -- milliseconds
    M.metrics.plugin_load_times[name] = elapsed
end

-- Track operation count (like Prometheus counter)
M.count = function(operation)
    M.metrics.operation_counts[operation] = (M.metrics.operation_counts[operation] or 0) + 1
end

-- Track operation duration (like Prometheus histogram)
M.time_operation = function(operation, fn)
    local start = vim.loop.hrtime()
    local result = fn()
    local elapsed = (vim.loop.hrtime() - start) / 1e6 -- milliseconds

    if not M.metrics.operation_durations[operation] then
        M.metrics.operation_durations[operation] = {
            count = 0,
            total = 0,
            min = math.huge,
            max = 0,
            samples = {},
        }
    end

    local metric = M.metrics.operation_durations[operation]
    metric.count = metric.count + 1
    metric.total = metric.total + elapsed
    metric.min = math.min(metric.min, elapsed)
    metric.max = math.max(metric.max, elapsed)

    -- Keep last 100 samples for percentile calculation
    table.insert(metric.samples, elapsed)
    if #metric.samples > 100 then
        table.remove(metric.samples, 1)
    end

    return result
end

-- Get metric summary (like Prometheus scrape endpoint)
M.get_metrics = function()
    local summary = {
        startup_time_ms = M.metrics.startup_time,
        plugin_load_times = M.metrics.plugin_load_times,
        operation_counts = M.metrics.operation_counts,
        operation_durations = {},
    }

    -- Calculate statistics for each operation
    for op, metric in pairs(M.metrics.operation_durations) do
        local avg = metric.total / metric.count

        -- Calculate p95 (95th percentile)
        local samples = vim.deepcopy(metric.samples)
        table.sort(samples)
        local p95_idx = math.ceil(#samples * 0.95)
        local p95 = samples[p95_idx] or 0

        summary.operation_durations[op] = {
            count = metric.count,
            avg_ms = avg,
            min_ms = metric.min,
            max_ms = metric.max,
            p95_ms = p95,
        }
    end

    return summary
end

-- Print metrics in human-readable format
M.print_metrics = function()
    local summary = M.get_metrics()

    print("=== Neovim Performance Metrics ===")
    print(string.format("Startup Time: %.2f ms", summary.startup_time_ms))

    print("\n--- Plugin Load Times ---")
    local plugins = {}
    for name, time in pairs(summary.plugin_load_times) do
        table.insert(plugins, { name = name, time = time })
    end
    table.sort(plugins, function(a, b) return a.time > b.time end)
    for _, plugin in ipairs(plugins) do
        print(string.format("  %s: %.2f ms", plugin.name, plugin.time))
    end

    print("\n--- Operation Counts ---")
    for op, count in pairs(summary.operation_counts) do
        print(string.format("  %s: %d", op, count))
    end

    print("\n--- Operation Durations ---")
    for op, stats in pairs(summary.operation_durations) do
        print(string.format("  %s:", op))
        print(string.format("    Count: %d", stats.count))
        print(string.format("    Avg: %.2f ms", stats.avg_ms))
        print(string.format("    Min: %.2f ms", stats.min_ms))
        print(string.format("    Max: %.2f ms", stats.max_ms))
        print(string.format("    P95: %.2f ms", stats.p95_ms))
    end
end

-- Export metrics to JSON (for external monitoring)
M.export_json = function()
    local summary = M.get_metrics()
    return vim.json.encode(summary)
end

-- Setup autocmd to track certain operations automatically
M.setup = function()
    -- Track buffer operations
    vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function()
            M.count("buffer_read")
        end,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
            M.count("buffer_write")
        end,
    })

    -- Track LSP operations
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function()
            M.count("lsp_attach")
        end,
    })

    -- Commands for viewing metrics
    vim.api.nvim_create_user_command("PerfMetrics", function()
        M.print_metrics()
    end, { desc = "Show performance metrics" })

    vim.api.nvim_create_user_command("PerfExport", function()
        local json = M.export_json()
        print(json)
    end, { desc = "Export performance metrics as JSON" })

    vim.api.nvim_create_user_command("PerfReset", function()
        M.metrics = {
            startup_time = M.metrics.startup_time, -- Keep startup time
            plugin_load_times = M.metrics.plugin_load_times, -- Keep plugin load times
            operation_counts = {},
            operation_durations = {},
        }
        print("Performance metrics reset")
    end, { desc = "Reset performance metrics" })
end

-- Keymap for quick access
vim.keymap.set("n", "<leader>up", "<Cmd>PerfMetrics<CR>", { desc = "Show performance metrics" })

return M
