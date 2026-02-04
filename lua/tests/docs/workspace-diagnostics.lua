return {
    title = "Workspace Diagnostics",
    see_also = { "diagnostic", "quickfix", "lsp" },
    desc = "Project-wide type checking, linting, and quickfix batch operations.",
    source = "lua/kyleking/deps/lsp.lua, lua/kyleking/utils/workspace_diagnostics.lua",

    notes = {
        "**Workspace-wide type checking** (runs project-local tools across all projects):",
        "",
        "The `<leader>lw{ecosystem}{tool}` pattern groups linters by language ecosystem:",
        "- Python (p): mypy, pyright, ruff, ty",
        "- TypeScript (t): eslint, oxlint",
        "- Go (g): golangci-lint",
        "- Lua (l): selene",
        "",
        "**Project detection**:",
        "Automatically detects all projects within VCS root (monorepo-aware).",
        "Falls back to current project if not in VCS.",
        "Respects project-local tool versions (`.venv/bin/mypy`, `node_modules/.bin/eslint`).",
        "",
        "**Quickfix batch operations** (`<leader>q` prefix):",
        "",
        "Browse and filter:",
        "- `<leader>fl` - Quickfix picker (flat view)",
        "- `<leader>qg` - Quickfix picker (grouped by file)",
        "- `<leader>qf` / `<leader>qF` - Filter by pattern (keep/remove)",
        "- `<leader>qt` - Filter by severity (interactive menu)",
        "",
        "Batch operations:",
        "- `<leader>qb` - Batch fix: auto mode (bulk apply with confirmation)",
        "- `<leader>qB` - Batch fix: interactive mode (review each fix)",
        "- `<leader>qn` - Batch fix: navigate mode (manual with open buffers)",
        "",
        "Utilities:",
        "- `<leader>qs` - Show quickfix statistics",
        "- `<leader>qd` - Remove duplicate entries",
        "- `<leader>qS` - Sort by file + line number",
        "- `<leader>qo` / `<leader>qO` - Open all files (edit/vsplit)",
        "",
        "Session management:",
        "- `<leader>qw` - Save quickfix list to file",
        "- `<leader>qr` - Load quickfix list from file",
        "",
        "**Batch fix modes**:",
        "",
        "1. **Auto mode** (`<leader>qb`) - Fast bulk apply:",
        "   - Single confirmation prompt",
        "   - Applies first matching code action to each item",
        "   - Best for trusted fixes (e.g., 100 type annotations)",
        "",
        "2. **Interactive mode** (`<leader>qB`) - Review each fix:",
        "   - Shows each fix one at a time",
        "   - Options: Apply | Skip | Apply to all remaining | Cancel",
        "   - Pattern detection: after applying same fix twice, offers bulk apply",
        "   - Best for learning patterns or mixed error types",
        "",
        "3. **Navigate mode** (`<leader>qn`) - Manual control:",
        "   - Opens all affected files",
        "   - Use `]q` / `[q` to jump between errors",
        "   - Use `<leader>ca` to apply code action at cursor",
        "   - Best for complex refactoring requiring context",
        "",
        "See `:h workspace-diagnostics` for detailed examples and workflows.",
    },

    grammars = {
        {
            pattern = "<leader>lwd",
            desc = "LSP workspace diagnostics to quickfix",
            tests = {
                {
                    name = "workspace diagnostics available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(type(vim.diagnostic.setqflist), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>lwpm / <leader>lwpp / <leader>lwpr / <leader>lwpt",
            desc = "Python: mypy / pyright / ruff / ty",
            tests = {
                {
                    name = "workspace_diagnostics module available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, wd = pcall(require, "kyleking.utils.workspace_diagnostics")
                            MiniTest.expect.equality(ok, true)
                            MiniTest.expect.equality(type(wd.run_workspace), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>lwte / <leader>lwto",
            desc = "TypeScript: eslint / oxlint",
            tests = {
                {
                    name = "supports typescript ecosystem",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local fre = require("find-relative-executable")
                            MiniTest.expect.equality(type(fre.ecosystems.eslint), "string")
                            MiniTest.expect.equality(type(fre.ecosystems.oxlint), "string")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>qs",
            desc = "Quickfix statistics",
            tests = {
                {
                    name = "stats function available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local wd = require("kyleking.utils.workspace_diagnostics")
                            MiniTest.expect.equality(type(wd.qf.stats), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>qt",
            desc = "Filter quickfix by severity",
            tests = {
                {
                    name = "severity filter available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local wd = require("kyleking.utils.workspace_diagnostics")
                            MiniTest.expect.equality(type(wd.qf.filter_severity), "function")
                            MiniTest.expect.equality(type(wd.qf.filter_severity_interactive), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>qb / <leader>qB / <leader>qn",
            desc = "Batch fix: auto / interactive / navigate",
            tests = {
                {
                    name = "batch fix function available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local wd = require("kyleking.utils.workspace_diagnostics")
                            MiniTest.expect.equality(type(wd.qf.batch_fix), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>qg",
            desc = "Quickfix grouped picker",
            tests = {
                {
                    name = "grouped picker available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local wd = require("kyleking.utils.workspace_diagnostics")
                            MiniTest.expect.equality(type(wd.qf.picker_grouped), "function")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>qw / <leader>qr",
            desc = "Save / load quickfix session",
            tests = {
                {
                    name = "session management available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local wd = require("kyleking.utils.workspace_diagnostics")
                            MiniTest.expect.equality(type(wd.qf.save_session), "function")
                            MiniTest.expect.equality(type(wd.qf.load_session), "function")
                        end,
                    },
                },
            },
        },
    },
}
