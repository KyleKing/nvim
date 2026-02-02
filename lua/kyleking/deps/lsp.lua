local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- PLANNED: Configure keymaps and settings: https://github.com/ray-x/lsp_signature.nvim?tab=readme-ov-file#keymap
later(function()
    add("ray-x/lsp_signature.nvim")
    local signature = require("lsp_signature")
    signature.setup({
        bind = false,
        hint_enable = false,
        handler_opts = { border = "rounded" },
    })

    local toggle_signature = function() signature.toggle_float_win() end
    vim.keymap.set({ "n", "i" }, "<leader>ks", toggle_signature, { desc = "Toggle signature help" })
end)

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
        -- terraform = { "tflint" }, -- TODO: this is using up CPU
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
            local filetype = vim.bo.filetype
            local candidates = get_available_linters(filetype)
            if #candidates > 0 then lint.try_lint(candidates) end
        end,
    })

    -- PLANNED: track which linters are being run with:
    --  https://github.com/mfussenegger/nvim-lint#get-the-current-running-linters-for-your-buffer

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

    vim.lsp.enable({
        "bashls",
        "gopls",
        "jsonls",
        "lua_ls",
        "pyright",
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
            map("n", "<leader>cR", vim.lsp.buf.references, "LSP references")
            map("n", "<leader>cr", vim.lsp.buf.rename, "LSP rename symbol")
        end,
    })
end)

-- PLANNED: Consider mini.quickfix when released for persistent diagnostic list
