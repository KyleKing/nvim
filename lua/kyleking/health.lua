local M = {}

local lsp_binaries = {
    bashls = "bash-language-server",
    gopls = "gopls",
    jsonls = "vscode-json-language-server",
    lua_ls = "lua-language-server",
    pyright = "pyright-langserver",
    terraformls = "terraform-ls",
    ts_ls = "typescript-language-server",
    yamlls = "yaml-language-server",
}

local fre_tools = {
    python = { "beautysh", "ruff" },
    node = { "oxlint", "prettier", "prettierd", "stylelint" },
}

local system_tools = {
    linters = { "golangcilint", "selene", "shellcheck", "yamllint" },
    formatters = { "golangci-lint", "golines", "mdformat", "shfmt", "stylua", "typos" },
}

local lsp_config_files = { "gopls", "lua_ls", "pyright", "terraformls", "ts_ls" }

local core_plugins = {
    required = { "mini.deps" },
    optional = { "conform", "lint", "mini.pick", "mini.files" },
}

function M._check_lsp_servers()
    local results = {}
    for server, binary in pairs(lsp_binaries) do
        local path = vim.fn.exepath(binary)
        local found = path ~= ""
        table.insert(results, {
            name = server,
            binary = binary,
            found = found,
            path = found and path or nil,
        })
    end
    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end

function M._check_lsp_configs()
    local results = {}
    local config_dir = vim.fn.stdpath("config") .. "/lsp"
    for _, name in ipairs(lsp_config_files) do
        local path = config_dir .. "/" .. name .. ".lua"
        local exists = vim.fn.filereadable(path) == 1
        table.insert(results, {
            name = name,
            path = path,
            exists = exists,
        })
    end
    return results
end

function M._check_fre_tools()
    local results = {}
    local fre = require("find-relative-executable")

    for ecosystem, tools in pairs(fre_tools) do
        for _, tool in ipairs(tools) do
            local resolved = fre.resolve(tool, vim.fn.getcwd())
            local system_path = vim.fn.exepath(tool)
            local is_local = resolved ~= system_path and resolved ~= tool
            local found = vim.fn.executable(resolved) == 1

            table.insert(results, {
                name = tool,
                ecosystem = ecosystem,
                found = found,
                path = found and resolved or nil,
                is_local = is_local,
            })
        end
    end

    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end

function M._check_system_tools()
    local results = {}
    local seen = {}

    for category, tools in pairs(system_tools) do
        for _, tool in ipairs(tools) do
            if not seen[tool] then
                seen[tool] = true
                local path = vim.fn.exepath(tool)
                local found = path ~= ""
                table.insert(results, {
                    name = tool,
                    category = category,
                    found = found,
                    path = found and path or nil,
                })
            end
        end
    end

    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end

function M._check_core_plugins()
    local results = {}

    for _, plugin in ipairs(core_plugins.required) do
        local loaded = package.loaded[plugin] ~= nil
        table.insert(results, {
            name = plugin,
            required = true,
            loaded = loaded,
        })
    end

    for _, plugin in ipairs(core_plugins.optional) do
        local loaded = package.loaded[plugin] ~= nil
        table.insert(results, {
            name = plugin,
            required = false,
            loaded = loaded,
        })
    end

    return results
end

function M.check()
    local health = vim.health

    health.start("LSP Servers")
    for _, result in ipairs(M._check_lsp_servers()) do
        if result.found then
            health.ok(("%s (%s)"):format(result.name, result.binary))
        else
            health.warn(("%s: %s not found in PATH"):format(result.name, result.binary))
        end
    end

    health.start("LSP Configurations")
    for _, result in ipairs(M._check_lsp_configs()) do
        if result.exists then
            health.ok(result.name .. ".lua")
        else
            health.warn(result.name .. ".lua not found")
        end
    end

    health.start("Project-Local Tools (find-relative-executable)")
    for _, result in ipairs(M._check_fre_tools()) do
        if result.found then
            local indicator = result.is_local and "[local]" or "[global]"
            health.ok(("%s %s: %s"):format(result.name, indicator, result.path))
        else
            health.warn(("%s: not found"):format(result.name))
        end
    end

    health.start("System Tools")
    for _, result in ipairs(M._check_system_tools()) do
        if result.found then
            health.ok(("%s: %s"):format(result.name, result.path))
        else
            health.warn(("%s: not found in PATH"):format(result.name))
        end
    end

    health.start("Core Plugins")
    for _, result in ipairs(M._check_core_plugins()) do
        if result.loaded then
            health.ok(result.name)
        elseif result.required then
            health.error(result.name .. " not loaded (required)")
        else
            health.info(result.name .. " not loaded (deferred)")
        end
    end
end

M._config = {
    lsp_binaries = lsp_binaries,
    fre_tools = fre_tools,
    system_tools = system_tools,
    lsp_config_files = lsp_config_files,
    core_plugins = core_plugins,
}

return M
