local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- PLANNED: See how TS/LSP mappings have changed:
--  https://gpanders.com/blog/whats-new-in-neovim-0-11/#more-default-mappings
--  https://lsp-zero.netlify.app/blog/lsp-config-overview.html#profit

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

    -- All available linters: https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file#available-linters
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

    -- Guard against missing binaries so autocmds do not raise ENOENT errors.
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

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
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
    -- local function lint_progress()
    --     local running = lint.get_running()
    --     if #running == 0 then return "󰦕" end
    --     return "󱉶 " .. table.concat(running, ", ")
    -- end
    --
    -- PLANNED: Integrate with mini.statusline once enabled or as modal
    -- local statusline = require("mini.statusline")
    -- statusline.setup({
    --     content = {
    --         active = function()
    --             local mode = statusline.section_mode({ trunc_width = 999 })
    --             local git = statusline.section_git()
    --             local diagnostics = statusline.section_diagnostics()
    --             local filename = statusline.section_filename({ trunc_width = 140 })
    --             local fileinfo = statusline.section_fileinfo()
    --             local lint_info = lint_progress()
    --             return statusline.combine_groups({
    --                 { hl = mode.hl, strings = { mode.string } },
    --                 { hl = "MiniStatuslineDevinfo", strings = { git, diagnostics, lint_info } },
    --                 "%<",
    --                 { hl = "MiniStatuslineFilename", strings = { filename } },
    --                 "%=",
    --                 { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
    --             })
    --         end,
    --     },
    -- })

    vim.keymap.set("n", "<leader>ll", function() require("lint").try_lint() end, { desc = "Trigger linting for current file" })
end)

later(function()
    add("neovim/nvim-lspconfig")

    -- FYI: see `:help lspconfig-all` or https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#angularls
    -- FYI: See mapping of server names here: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
    vim.lsp.enable({
        "gopls",
        "lua_ls",
        "pyright",
        "ts_ls",
    })

    local keymap_group = vim.api.nvim_create_augroup("kyleking_lsp_keymaps", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = keymap_group,
        callback = function(event)
            local function map(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
            end

            map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP code actions")
            map("n", "<leader>cR", vim.lsp.buf.references, "LSP references")
            map("n", "<leader>cr", vim.lsp.buf.rename, "LSP rename symbol")
            map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "LSP format buffer")
            map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
            map("n", "<leader>cD", vim.diagnostic.setloclist, "Diagnostics to loclist")
        end,
    })
end)

-- PLANNED: Consider mini.quickfix when released for persistent diagnostic list
