-- Test LSP-related plugins (lsp_signature, nvim-lint, lazydev)
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() vim.wait(1000) end,
    },
})

T["lsp_signature"] = MiniTest.new_set()

T["lsp_signature"]["signature is configured with rounded border"] = function()
    local signature = require("lsp_signature")
    local config = signature.config or {}

    if config.handler_opts then
        MiniTest.expect.equality(config.handler_opts.border, "rounded", "Signature should use rounded border")
    end
end

T["nvim-lint"] = MiniTest.new_set()

T["nvim-lint"]["linters are configured for common filetypes"] = function()
    local lint = require("lint")
    local linters_by_ft = lint.linters_by_ft or {}

    local common_filetypes = { "lua", "python", "javascript", "typescript", "yaml", "sh" }

    for _, ft in ipairs(common_filetypes) do
        local linters = linters_by_ft[ft]
        MiniTest.expect.equality(linters ~= nil and #linters > 0, true, ft .. " should have linters configured")
    end
end

T["nvim-lint"]["python uses ruff linter"] = function()
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
    local autocmds = vim.api.nvim_get_autocmds({ group = "nvim-lint" })
    MiniTest.expect.equality(#autocmds > 0, true, "nvim-lint autocmds should be configured")
end

T["lazydev"] = MiniTest.new_set()

T["lazydev"]["integrations disable cmp and coq"] = function()
    local config = require("lazydev.config")
    MiniTest.expect.equality(config.integrations.cmp, false, "cmp integration should be disabled")
    MiniTest.expect.equality(config.integrations.coq, false, "coq integration should be disabled")
end

T["lazydev"]["lspconfig integration is enabled"] = function()
    local config = require("lazydev.config")
    MiniTest.expect.equality(config.integrations.lspconfig, true, "lspconfig integration should be enabled")
end

T["lazydev"]["runtime points to VIMRUNTIME"] = function()
    local config = require("lazydev.config")
    MiniTest.expect.equality(config.runtime, vim.env.VIMRUNTIME, "runtime should match $VIMRUNTIME")
end

T["lazydev"]["find_workspace is callable"] = function()
    local lazydev = require("lazydev")
    MiniTest.expect.equality(type(lazydev.find_workspace), "function", "find_workspace should be a function")
end

T["lazydev"]["workspace module loads"] = function()
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
