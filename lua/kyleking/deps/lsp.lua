local MiniDeps = require("mini.deps")
local deps_utils = require("kyleking.deps_utils")
local add, later = MiniDeps.add, deps_utils.maybe_later

-- Configure signature help border globally
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

later(function()
    add("mfussenegger/nvim-lint")
    local lint = require("lint")
    local fre = require("find-relative-executable")

    lint.linters_by_ft = {
        css = { "stylelint" },
        go = { "golangcilint" },
        javascript = { "oxlint" },
        javascriptreact = { "oxlint" },
        lua = { "selene" },
        python = { "ruff" },
        sh = { "shellcheck" },
        -- tflint intentionally disabled due to high CPU usage on large Terraform projects
        -- To enable: uncomment and consider using BufWritePost instead of TextChanged
        -- terraform = { "tflint" },
        typescript = { "oxlint" },
        typescriptreact = { "oxlint" },
        yaml = { "yamllint" },
        zsh = { "zsh" },
    }

    local function _override_linter_cmd(linter_name, tool_name)
        local linter = lint.linters[linter_name]
        if not linter then return end
        linter.cmd = fre.cmd_for(tool_name)
    end

    _override_linter_cmd("oxlint", "oxlint")
    _override_linter_cmd("ruff", "ruff")
    _override_linter_cmd("stylelint", "stylelint")

    local executable_cache = {}
    local function cmd_is_executable(cmd)
        if executable_cache[cmd] == nil then executable_cache[cmd] = vim.fn.executable(cmd) == 1 end
        return executable_cache[cmd]
    end

    local function get_available_linters(filetype)
        local configured = lint.linters_by_ft[filetype]
        if not configured then return {} end

        local available = {}
        for _, linter_name in ipairs(configured) do
            local linter = lint.linters[linter_name]

            if type(linter) == "function" then
                local ok, resolved = pcall(linter)
                linter = ok and resolved or nil
            end

            local cmd = type(linter) == "table" and linter.cmd or nil
            if type(cmd) == "function" then
                local ok, resolved_cmd = pcall(cmd)
                cmd = ok and resolved_cmd or nil
            end
            if type(cmd) == "table" then cmd = cmd[1] end

            if type(cmd) ~= "string" or cmd_is_executable(cmd) then table.insert(available, linter_name) end
        end

        return available
    end

    local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
            -- Skip terminal buffers for performance
            if vim.bo.buftype == "terminal" then return end

            local filetype = vim.bo.filetype
            local candidates = get_available_linters(filetype)
            if #candidates > 0 then lint.try_lint(candidates) end
        end,
    })

    -- NOTE: Linter progress is tracked in statusline (bars-and-lines.lua) using lint.get_running()
    -- See: https://github.com/mfussenegger/nvim-lint#get-the-current-running-linters-for-your-buffer

    vim.keymap.set(
        "n",
        "<leader>ll",
        function() require("lint").try_lint() end,
        { desc = "Trigger linting for current file" }
    )
end)

later(function()
    add("neovim/nvim-lspconfig")
    add("b0o/SchemaStore.nvim")

    vim.lsp.config("jsonls", {
        settings = {
            json = {
                schemas = require("schemastore").json.schemas(),
                validate = { enable = true },
            },
        },
    })

    vim.lsp.config("yamlls", {
        settings = {
            yaml = {
                schemaStore = { enable = false, url = "" },
                schemas = require("schemastore").yaml.schemas(),
            },
        },
    })

    -- Python type checker selection: ty (fast) vs pyright (mature)
    -- Set USE_PYRIGHT=1 to prefer pyright over ty
    local python_lsp = vim.env.USE_PYRIGHT == "1" and "pyright" or "ty"

    vim.lsp.enable({
        "bashls",
        "cssls",
        "docker_compose_language_service",
        "dockerls",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        python_lsp,
        "taplo",
        "terraformls",
        "ts_ls",
        "yamlls",
    })

    local keymap_group = vim.api.nvim_create_augroup("kyleking_lsp_keymaps", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = keymap_group,
        callback = function(event)
            local function map(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
            end

            -- Disable native LSP bindings (use picker UI via <leader>lg* instead)
            -- Native bindings: gd (definition), grr (references), gri (implementation)
            vim.keymap.set("n", "gd", "<nop>", { buffer = event.buf, desc = "Use <leader>lgd (picker UI)" })
            vim.keymap.set("n", "grr", "<nop>", { buffer = event.buf, desc = "Use <leader>lgr (picker UI)" })
            vim.keymap.set("n", "gri", "<nop>", { buffer = event.buf, desc = "Use <leader>lgi (picker UI)" })

            map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP code actions")
            map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
            map("n", "<leader>cD", vim.diagnostic.setloclist, "Diagnostics to loclist")
            map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "LSP format buffer")
            map(
                "n",
                "<leader>cn",
                function() require("kyleking.utils.noqa").ignore_inline() end,
                "Ignore diagnostic (inline)"
            )
            map(
                "n",
                "<leader>cN",
                function() require("kyleking.utils.noqa").ignore_file() end,
                "Ignore diagnostic (file)"
            )
            -- <leader>cR removed - redundant with <leader>lgr (picker UI)
            map("n", "<leader>cr", vim.lsp.buf.rename, "LSP rename symbol")
        end,
    })
end)

later(function()
    add("folke/lazydev.nvim")
    require("lazydev").setup({
        integrations = {
            cmp = false,
            coq = false,
        },
    })
end)

later(function()
    local wd = require("kyleking.utils.workspace_diagnostics")
    local K = vim.keymap.set

    -- Workspace diagnostics (leader-lw prefix for workspace operations)
    K("n", "<leader>lwd", function()
        vim.diagnostic.setqflist({ severity = nil })
        vim.cmd("copen")
    end, { desc = "LSP workspace diagnostics to quickfix" })

    -- Project-wide type checking and linting (CLI tools, independent of LSP)
    -- Runs in all projects within VCS root, or current project if not in VCS

    -- Python tools (p)
    K("n", "<leader>lwpm", function() wd.run_workspace("mypy") end, { desc = "Python: mypy" })
    K("n", "<leader>lwpp", function() wd.run_workspace("pyright") end, { desc = "Python: pyright" })
    K("n", "<leader>lwpr", function() wd.run_workspace("ruff") end, { desc = "Python: ruff" })
    K("n", "<leader>lwpt", function() wd.run_workspace("ty") end, { desc = "Python: ty" })

    -- TypeScript/JavaScript tools (t)
    K("n", "<leader>lwte", function() wd.run_workspace("eslint") end, { desc = "TypeScript: eslint" })
    K("n", "<leader>lwto", function() wd.run_workspace("oxlint") end, { desc = "TypeScript: oxlint" })

    -- Go tools (g)
    K("n", "<leader>lwgg", function() wd.run_workspace("golangcilint") end, { desc = "Go: golangci-lint" })

    -- Lua tools (l)
    K("n", "<leader>lwll", function() wd.run_workspace("selene") end, { desc = "Lua: selene" })

    -- Quickfix batch operations (leader-q prefix)
    K("n", "<leader>qs", wd.qf.stats, { desc = "Quickfix stats" })
    K("n", "<leader>qd", wd.qf.dedupe, { desc = "Quickfix dedupe" })
    K("n", "<leader>qS", wd.qf.sort, { desc = "Quickfix sort" })

    -- Filtering
    K("n", "<leader>qf", function()
        vim.ui.input({ prompt = "Filter pattern (keep): " }, function(pattern)
            if pattern then wd.qf.filter(pattern, true) end
        end)
    end, { desc = "Quickfix filter (keep)" })

    K("n", "<leader>qF", function()
        vim.ui.input({ prompt = "Filter pattern (remove): " }, function(pattern)
            if pattern then wd.qf.filter(pattern, false) end
        end)
    end, { desc = "Quickfix filter (remove)" })

    K("n", "<leader>qt", wd.qf.filter_severity_interactive, { desc = "Quickfix filter by severity" })

    -- File operations
    K("n", "<leader>qo", function() wd.qf.open_all() end, { desc = "Quickfix open all files" })
    K("n", "<leader>qO", function() wd.qf.open_all("vsplit") end, { desc = "Quickfix open all (vsplit)" })

    -- Batch operations
    K("n", "<leader>qb", function() wd.qf.batch_fix({ preview = true }) end, { desc = "Quickfix batch fix (auto)" })
    K(
        "n",
        "<leader>qB",
        function() wd.qf.batch_fix({ mode = "interactive" }) end,
        { desc = "Quickfix batch fix (interactive)" }
    )
    K("n", "<leader>qn", function() wd.qf.batch_fix({ mode = "navigate" }) end, { desc = "Quickfix navigate mode" })
    K("n", "<leader>qg", wd.qf.picker_grouped, { desc = "Quickfix grouped picker" })

    -- Session management
    K("n", "<leader>qw", function()
        vim.ui.input({ prompt = "Save to (default: .qf_session): ", default = ".qf_session" }, function(path)
            if path then wd.qf.save_session(path) end
        end)
    end, { desc = "Quickfix save session" })

    K("n", "<leader>qr", function()
        vim.ui.input({ prompt = "Load from (default: .qf_session): ", default = ".qf_session" }, function(path)
            if path then wd.qf.load_session(path) end
        end)
    end, { desc = "Quickfix load session" })

    -- Debug helper
    K("n", "<leader>lwi", wd.debug_project_root, { desc = "Workspace: show project info" })

    -- User command for easier access
    vim.api.nvim_create_user_command("WorkspaceInfo", wd.debug_project_root, { desc = "Show project root info" })
end)

-- PLANNED: Consider mini.quickfix when released for persistent diagnostic list
