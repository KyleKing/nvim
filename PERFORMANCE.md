# Performance Tracking and Metrics

This Neovim configuration includes a built-in performance tracking system inspired by Prometheus-style metrics for production monitoring.

## Overview

The performance module tracks:
- **Startup time**: Time from init to all plugins loaded
- **Plugin load times**: Individual plugin initialization times
- **Operation counts**: How many times specific operations occur
- **Operation durations**: Timing statistics for tracked operations (avg, min, max, p95)

## Quick Start

### View Current Metrics

```vim
" Show performance metrics in a readable format
:PerfMetrics

" Or use the keymap
<leader>up
```

### Export Metrics as JSON

```vim
" Export metrics as JSON (for external monitoring)
:PerfExport
```

### Reset Metrics

```vim
" Reset all runtime metrics (keeps startup time and plugin load times)
:PerfReset
```

## What's Being Tracked

### Automatic Tracking

The following operations are tracked automatically:

1. **Startup Time**: Measured from when the performance module loads until 100ms after plugin initialization
2. **Buffer Operations**:
   - `buffer_read` - Every time a buffer is read
   - `buffer_write` - Every time a buffer is written
3. **LSP Operations**:
   - `lsp_attach` - Every time LSP attaches to a buffer

### Custom Tracking

You can track your own operations in your configuration:

```lua
local perf = require("kyleking.core.performance")

-- Count occurrences
perf.count("my_operation")

-- Time an operation
local result = perf.time_operation("my_timed_operation", function()
    -- Your code here
    return some_value
end)

-- Track plugin load time
perf.track_plugin("my_plugin", function()
    require("my_plugin").setup()
end)
```

## Understanding the Metrics

### Startup Time

```
Startup Time: 156.23 ms
```

This is the total time from when Neovim starts loading your config to when all plugins are initialized.

**Target**: < 200ms for good performance, < 500ms acceptable

### Plugin Load Times

```
--- Plugin Load Times ---
  flash.nvim: 12.34 ms
  nvim-treesitter: 45.67 ms
  ...
```

Shows how long each plugin took to initialize, sorted by duration (slowest first).

**Interpretation**:
- < 10ms: Fast
- 10-50ms: Acceptable
- > 50ms: Consider if the plugin is necessary or can be lazy-loaded

### Operation Counts

```
--- Operation Counts ---
  buffer_read: 42
  buffer_write: 15
  lsp_attach: 3
```

Simple counters for how many times each operation has occurred during this session.

**Use cases**:
- Identify frequently used operations
- Detect unexpected repeated operations
- Track usage patterns

### Operation Durations

```
--- Operation Durations ---
  lsp_call:
    Count: 150
    Avg: 2.45 ms
    Min: 0.12 ms
    Max: 45.32 ms
    P95: 8.23 ms
```

Statistical analysis of timed operations:
- **Count**: How many times the operation ran
- **Avg**: Average duration
- **Min**: Fastest execution
- **Max**: Slowest execution
- **P95**: 95th percentile (95% of executions were this fast or faster)

**Interpretation**:
- P95 is often more useful than average for understanding real-world performance
- Large gap between avg and max might indicate occasional slow operations
- High P95 indicates consistently slow operations that need optimization

## Performance Goals

### Startup Performance

Target startup times:
- ✅ < 200ms: Excellent
- ⚠️ 200-500ms: Good
- ❌ > 500ms: Investigate slow plugins

### Operation Performance

General guidelines:
- LSP operations: < 10ms average
- File operations: < 5ms average
- UI updates: < 16ms (60fps threshold)

## Advanced Usage

### Tracking Custom Metrics in Plugins

If you're developing a plugin or custom functionality:

```lua
-- Track how often a feature is used
vim.keymap.set("n", "<leader>myfeature", function()
    local perf = require("kyleking.core.performance")
    perf.count("my_feature_used")

    perf.time_operation("my_feature_execution", function()
        -- Your feature code here
    end)
end)
```

### Profiling Specific Functions

```lua
local perf = require("kyleking.core.performance")

-- Profile a specific function
local function slow_function()
    -- ... potentially slow code ...
end

local optimized_result = perf.time_operation("slow_function", slow_function)
```

### Exporting for External Monitoring

You can export metrics to send to external monitoring systems:

```lua
-- Get metrics as Lua table
local perf = require("kyleking.core.performance")
local metrics = perf.get_metrics()

-- Export as JSON
local json = perf.export_json()

-- Send to external system (example)
-- vim.fn.system('curl -X POST http://metrics-server/nvim -d ' .. json)
```

## Performance Testing

Performance tests are included in the test suite:

```vim
" Run all tests (including performance tests)
:RunAllTests

" Or use the keymap
<leader>ta
```

The performance tests validate:
- Startup time tracking works
- Plugin load times are recorded
- Operation counting is accurate
- Duration statistics are calculated correctly
- Percentile calculations work
- Export functionality works

## Troubleshooting

### High Startup Time

1. Check plugin load times: `:PerfMetrics`
2. Look for slow plugins (> 50ms)
3. Consider lazy-loading slow plugins
4. Use `:startuptime` for more detailed analysis

### Slow Operations

1. Look at operation durations: `:PerfMetrics`
2. Check for high P95 times
3. Look for operations with very high max times
4. Add more granular tracking to identify bottlenecks

### Memory Usage

The performance module stores the last 100 samples for each timed operation. This is minimal overhead, but if you're tracking hundreds of different operations, consider resetting metrics periodically with `:PerfReset`.

## Integration with Existing Tools

### Native Profiling

Neovim has built-in profiling:

```vim
" Profile everything
:profile start /tmp/nvim-profile.txt
:profile func *
:profile file *

" ... use Neovim normally ...

:profile stop
" Check /tmp/nvim-profile.txt
```

### Startup Time Analysis

```bash
# Detailed startup time breakdown
nvim --startuptime /tmp/nvim-startuptime.txt +qall
cat /tmp/nvim-startuptime.txt
```

The performance module complements these tools with runtime metrics and easier access to common performance data.

## See Also

- [PLUGINS.md](./PLUGINS.md) - Documentation for all configured plugins
- [MINI_ANALYSIS.md](./MINI_ANALYSIS.md) - Analysis of mini.nvim ecosystem
- Neovim `:help profiling` - Built-in profiling documentation
