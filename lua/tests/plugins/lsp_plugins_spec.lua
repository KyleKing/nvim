-- Test LSP-related plugins (lsp_signature, nvim-lint)
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["lsp plugins"] = MiniTest.new_set()

T["lsp_signature"] = MiniTest.new_set()

T["lsp_signature"]["lsp_signature is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("lsp_signature"), true, "lsp_signature should be loaded")
end

T["lsp_signature"]["signature keymap is set"] = function()
    vim.wait(1000)

    local keymap_n = vim.fn.maparg("<leader>ks", "n", false, true)
    local keymap_i = vim.fn.maparg("<leader>ks", "i", false, true)

    MiniTest.expect.equality(
        keymap_n ~= nil and keymap_n.lhs ~= nil,
        true,
        "<leader>ks mapping should exist in normal mode"
    )
    MiniTest.expect.equality(
        keymap_i ~= nil and keymap_i.lhs ~= nil,
        true,
        "<leader>ks mapping should exist in insert mode"
    )

    -- Verify callable
    local has_callable_n = (type(keymap_n.callback) == "function")
        or (type(keymap_n.rhs) == "string" and keymap_n.rhs ~= "")
    local has_callable_i = (type(keymap_i.callback) == "function")
        or (type(keymap_i.rhs) == "string" and keymap_i.rhs ~= "")

    MiniTest.expect.equality(has_callable_n, true, "<leader>ks should have callable rhs in normal mode")
    MiniTest.expect.equality(has_callable_i, true, "<leader>ks should have callable rhs in insert mode")
end

T["lsp_signature"]["signature functions are callable"] = function()
    vim.wait(1000)

    local signature = require("lsp_signature")
    MiniTest.expect.equality(type(signature.toggle_float_win), "function", "toggle_float_win should be a function")
end

T["lsp_signature"]["signature is configured with rounded border"] = function()
    vim.wait(1000)

    local signature = require("lsp_signature")
    local config = signature.config or {}

    -- Check that border is rounded (if config is accessible)
    if config.handler_opts then
        MiniTest.expect.equality(config.handler_opts.border, "rounded", "Signature should use rounded border")
    end
end

T["nvim-lint"] = MiniTest.new_set()

T["nvim-lint"]["nvim-lint is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("lint"), true, "nvim-lint should be loaded")
end

T["nvim-lint"]["linters are configured for common filetypes"] = function()
    vim.wait(1000)

    local lint = require("lint")
    local linters_by_ft = lint.linters_by_ft or {}

    -- Check that common filetypes have linters
    local common_filetypes = { "lua", "python", "javascript", "typescript", "yaml", "sh" }

    for _, ft in ipairs(common_filetypes) do
        local linters = linters_by_ft[ft]
        MiniTest.expect.equality(linters ~= nil and #linters > 0, true, ft .. " should have linters configured")
    end
end

T["nvim-lint"]["python uses ruff linter"] = function()
    vim.wait(1000)

    local lint = require("lint")
    local python_linters = lint.linters_by_ft.python or {}

    local has_ruff = false
    for _, linter in ipairs(python_linters) do
        if linter == "ruff" then
            has_ruff = true
            break
        end
    end

    MiniTest.expect.equality(has_ruff, true, "Python should use ruff linter")
end

T["nvim-lint"]["lua uses selene linter"] = function()
    vim.wait(1000)

    local lint = require("lint")
    local lua_linters = lint.linters_by_ft.lua or {}

    local has_selene = false
    for _, linter in ipairs(lua_linters) do
        if linter == "selene" then
            has_selene = true
            break
        end
    end

    MiniTest.expect.equality(has_selene, true, "Lua should use selene linter")
end

T["nvim-lint"]["javascript uses oxlint"] = function()
    vim.wait(1000)

    local lint = require("lint")
    local js_linters = lint.linters_by_ft.javascript or {}

    local has_oxlint = false
    for _, linter in ipairs(js_linters) do
        if linter == "oxlint" then
            has_oxlint = true
            break
        end
    end

    MiniTest.expect.equality(has_oxlint, true, "JavaScript should use oxlint linter")
end

T["nvim-lint"]["lint autocmds are set"] = function()
    vim.wait(1000)

    -- Check that lint autocmds exist
    local autocmds = vim.api.nvim_get_autocmds({ group = "nvim-lint" })
    MiniTest.expect.equality(#autocmds > 0, true, "nvim-lint autocmds should be configured")
end

T["nvim-lint"]["try_lint function exists"] = function()
    vim.wait(1000)

    local lint = require("lint")
    MiniTest.expect.equality(type(lint.try_lint), "function", "try_lint should be a function")
end

T["nvim-lint"]["lint keymap is set"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>ll", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>ll mapping should exist")

    -- Verify callable
    local has_callable = (type(keymap.callback) == "function") or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
    MiniTest.expect.equality(has_callable, true, "<leader>ll should have callable rhs")
end

T["lazydev"] = MiniTest.new_set()

T["lazydev"]["lazydev is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("lazydev"), true, "lazydev should be loaded")
end

T["lazydev"]["integrations disable cmp and coq"] = function()
    vim.wait(1000)

    local config = require("lazydev.config")
    MiniTest.expect.equality(config.integrations.cmp, false, "cmp integration should be disabled")
    MiniTest.expect.equality(config.integrations.coq, false, "coq integration should be disabled")
end

T["lazydev"]["lspconfig integration is enabled"] = function()
    vim.wait(1000)

    local config = require("lazydev.config")
    MiniTest.expect.equality(config.integrations.lspconfig, true, "lspconfig integration should be enabled")
end

T["lazydev"]["runtime points to VIMRUNTIME"] = function()
    vim.wait(1000)

    local config = require("lazydev.config")
    MiniTest.expect.equality(config.runtime, vim.env.VIMRUNTIME, "runtime should match $VIMRUNTIME")
end

T["lazydev"]["find_workspace is callable"] = function()
    vim.wait(1000)

    local lazydev = require("lazydev")
    MiniTest.expect.equality(type(lazydev.find_workspace), "function", "find_workspace should be a function")
end

T["lazydev"]["workspace module loads"] = function()
    vim.wait(1000)

    MiniTest.expect.no_error(function()
        local ws = require("lazydev.workspace")
        MiniTest.expect.equality(type(ws.find), "function", "workspace.find should be a function")
        MiniTest.expect.equality(type(ws.get), "function", "workspace.get should be a function")
    end)
end

T["diagnostics"] = MiniTest.new_set()

T["diagnostics"]["diagnostic config has format function"] = function()
    local config = vim.diagnostic.config()
    MiniTest.expect.equality(type(config.virtual_text.format), "function", "virtual_text should have a format function")
    MiniTest.expect.equality(type(config.float.format), "function", "float should have a format function")
end

T["diagnostics"]["format function includes source and code"] = function()
    local config = vim.diagnostic.config()
    local format_fn = config.virtual_text.format

    local result = format_fn({ source = "ruff", code = "E501", message = "line too long" })
    MiniTest.expect.equality(result, "[ruff E501] line too long", "format should include source and code prefix")
end

T["diagnostics"]["format function handles missing source and code"] = function()
    local config = vim.diagnostic.config()
    local format_fn = config.virtual_text.format

    local result = format_fn({ message = "some error" })
    MiniTest.expect.equality(result, "some error", "format should work without source/code")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
