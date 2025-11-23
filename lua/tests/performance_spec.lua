-- Performance tests for tracking and validating nvim performance
-- Based on mini.test framework

local helpers = require("tests.helpers")
local expect, eq = helpers.expect, helpers.eq

-- Helper function to get performance module
local function get_perf()
    return require("kyleking.core.performance")
end

-- Test suite
local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Reset performance metrics before each test
            local perf = get_perf()
            perf.metrics = {
                startup_time = 0,
                plugin_load_times = {},
                operation_counts = {},
                operation_durations = {},
            }
        end,
    },
})

-- Startup time tests
T["startup_time"] = MiniTest.new_set()

T["startup_time"]["tracks startup time"] = function()
    local perf = get_perf()
    perf.start_time = vim.loop.hrtime()
    vim.loop.sleep(10) -- Sleep for 10ms
    perf.finish_startup()

    expect.truth(perf.metrics.startup_time > 0, "Startup time should be tracked")
    expect.truth(perf.metrics.startup_time >= 10, "Startup time should be at least 10ms")
end

T["startup_time"]["startup time is reasonable"] = function()
    local perf = get_perf()
    -- Assuming startup tracking is already running
    -- Check that startup time is reasonable (< 5000ms = 5 seconds)
    if perf.metrics.startup_time > 0 then
        expect.truth(
            perf.metrics.startup_time < 5000,
            string.format("Startup time should be < 5000ms, got %.2f ms", perf.metrics.startup_time)
        )
    end
end

-- Plugin load time tests
T["plugin_load_times"] = MiniTest.new_set()

T["plugin_load_times"]["tracks plugin load time"] = function()
    local perf = get_perf()
    perf.track_plugin("test_plugin", function()
        vim.loop.sleep(5) -- Simulate plugin load time
    end)

    expect.truth(perf.metrics.plugin_load_times["test_plugin"] ~= nil, "Plugin load time should be tracked")
    expect.truth(
        perf.metrics.plugin_load_times["test_plugin"] >= 5,
        "Plugin load time should be at least 5ms"
    )
end

-- Operation counting tests
T["operation_counts"] = MiniTest.new_set()

T["operation_counts"]["counts operations"] = function()
    local perf = get_perf()
    perf.count("test_operation")
    perf.count("test_operation")
    perf.count("test_operation")

    eq(perf.metrics.operation_counts["test_operation"], 3)
end

T["operation_counts"]["tracks multiple operations"] = function()
    local perf = get_perf()
    perf.count("operation_a")
    perf.count("operation_b")
    perf.count("operation_a")

    eq(perf.metrics.operation_counts["operation_a"], 2)
    eq(perf.metrics.operation_counts["operation_b"], 1)
end

-- Operation duration tests
T["operation_durations"] = MiniTest.new_set()

T["operation_durations"]["tracks operation duration"] = function()
    local perf = get_perf()
    perf.time_operation("test_op", function()
        vim.loop.sleep(5)
    end)

    local metric = perf.metrics.operation_durations["test_op"]
    expect.truth(metric ~= nil, "Operation duration should be tracked")
    expect.truth(metric.count == 1, "Operation count should be 1")
    expect.truth(metric.total >= 5, "Total duration should be at least 5ms")
end

T["operation_durations"]["calculates statistics correctly"] = function()
    local perf = get_perf()

    -- Run operation multiple times with different durations
    perf.time_operation("stat_test", function() vim.loop.sleep(10) end)
    perf.time_operation("stat_test", function() vim.loop.sleep(5) end)
    perf.time_operation("stat_test", function() vim.loop.sleep(15) end)

    local metric = perf.metrics.operation_durations["stat_test"]
    expect.truth(metric.count == 3, "Should have 3 operations")
    expect.truth(metric.min >= 5, "Min should be >= 5ms")
    expect.truth(metric.max >= 15, "Max should be >= 15ms")
    expect.truth(metric.min < metric.max, "Min should be less than max")
end

T["operation_durations"]["returns function result"] = function()
    local perf = get_perf()
    local result = perf.time_operation("return_test", function()
        return 42
    end)

    eq(result, 42)
end

-- Metrics retrieval tests
T["get_metrics"] = MiniTest.new_set()

T["get_metrics"]["returns complete summary"] = function()
    local perf = get_perf()
    perf.metrics.startup_time = 100
    perf.count("test_count")
    perf.time_operation("test_time", function() vim.loop.sleep(5) end)

    local summary = perf.get_metrics()

    expect.truth(summary.startup_time_ms == 100, "Should include startup time")
    expect.truth(summary.operation_counts["test_count"] == 1, "Should include counts")
    expect.truth(summary.operation_durations["test_time"] ~= nil, "Should include durations")
end

T["get_metrics"]["calculates percentiles"] = function()
    local perf = get_perf()

    -- Add 100 samples to test percentile calculation
    for i = 1, 100 do
        perf.time_operation("percentile_test", function()
            vim.loop.sleep(i % 10) -- Sleep 0-9ms in a pattern
        end)
    end

    local summary = perf.get_metrics()
    local stats = summary.operation_durations["percentile_test"]

    expect.truth(stats.p95_ms ~= nil, "Should have p95")
    expect.truth(stats.p95_ms >= stats.avg_ms, "p95 should be >= avg")
end

-- Export tests
T["export"] = MiniTest.new_set()

T["export"]["exports valid JSON"] = function()
    local perf = get_perf()
    perf.metrics.startup_time = 100
    perf.count("json_test")

    local json = perf.export_json()

    expect.truth(type(json) == "string", "Export should return string")
    expect.truth(json:find("startup_time_ms"), "JSON should contain startup_time_ms")
    expect.truth(json:find("json_test"), "JSON should contain operation counts")
end

-- Integration tests
T["integration"] = MiniTest.new_set()

T["integration"]["tracks real buffer operations"] = function()
    local perf = get_perf()
    local initial_count = perf.metrics.operation_counts["buffer_read"] or 0

    -- Create and read a buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "test" })

    -- Trigger BufReadPost
    vim.cmd("doautocmd BufReadPost")

    -- Wait a bit for autocmd to fire
    vim.wait(100)

    local new_count = perf.metrics.operation_counts["buffer_read"] or 0
    expect.truth(new_count > initial_count, "Should track buffer_read operations")
end

-- Performance benchmarks (these are informational, not strict tests)
T["benchmarks"] = MiniTest.new_set()

T["benchmarks"]["LSP operation should be fast"] = function()
    local perf = get_perf()
    local iterations = 100

    for _ = 1, iterations do
        perf.time_operation("benchmark_lsp_call", function()
            -- Simulate LSP operation
            local _ = vim.lsp.get_clients()
        end)
    end

    local summary = perf.get_metrics()
    local stats = summary.operation_durations["benchmark_lsp_call"]

    -- This is informational - log the results
    if stats then
        print(string.format(
            "LSP call benchmark: avg=%.2fms, min=%.2fms, max=%.2fms, p95=%.2fms",
            stats.avg_ms,
            stats.min_ms,
            stats.max_ms,
            stats.p95_ms
        ))
    end

    -- Soft assertion - LSP calls should generally be < 10ms
    if stats and stats.avg_ms > 10 then
        print("WARNING: LSP calls averaging > 10ms, may want to investigate")
    end
end

return T
