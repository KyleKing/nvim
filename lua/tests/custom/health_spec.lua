local MiniTest = require("mini.test")
local health = require("kyleking.health")

local T = MiniTest.new_set({ hooks = {} })

T["_config"] = MiniTest.new_set()

T["_config"]["exposes lsp_binaries"] = function()
    MiniTest.expect.equality(type(health._config.lsp_binaries), "table")
    MiniTest.expect.equality(health._config.lsp_binaries.lua_ls, "lua-language-server")
    MiniTest.expect.equality(health._config.lsp_binaries.pyright, "pyright-langserver")
end

T["_config"]["exposes fre_tools"] = function()
    MiniTest.expect.equality(type(health._config.fre_tools), "table")
    MiniTest.expect.equality(type(health._config.fre_tools.python), "table")
    MiniTest.expect.equality(type(health._config.fre_tools.node), "table")
    MiniTest.expect.equality(vim.tbl_contains(health._config.fre_tools.python, "ruff"), true)
end

T["_config"]["exposes system_tools"] = function()
    MiniTest.expect.equality(type(health._config.system_tools), "table")
    MiniTest.expect.equality(type(health._config.system_tools.linters), "table")
    MiniTest.expect.equality(type(health._config.system_tools.formatters), "table")
end

T["_config"]["exposes lsp_config_files"] = function()
    MiniTest.expect.equality(type(health._config.lsp_config_files), "table")
    MiniTest.expect.equality(vim.tbl_contains(health._config.lsp_config_files, "lua_ls"), true)
    MiniTest.expect.equality(vim.tbl_contains(health._config.lsp_config_files, "pyright"), true)
end

T["_check_lsp_servers"] = MiniTest.new_set()

T["_check_lsp_servers"]["returns structured results"] = function()
    local results = health._check_lsp_servers()
    MiniTest.expect.equality(type(results), "table")
    MiniTest.expect.equality(#results > 0, true)

    local first = results[1]
    MiniTest.expect.equality(type(first.name), "string")
    MiniTest.expect.equality(type(first.binary), "string")
    MiniTest.expect.equality(type(first.found), "boolean")
end

T["_check_lsp_servers"]["results are sorted by name"] = function()
    local results = health._check_lsp_servers()
    for i = 2, #results do
        MiniTest.expect.equality(results[i - 1].name < results[i].name, true)
    end
end

T["_check_lsp_servers"]["includes all configured servers"] = function()
    local results = health._check_lsp_servers()
    local names = {}
    for _, r in ipairs(results) do
        names[r.name] = true
    end

    for server, _ in pairs(health._config.lsp_binaries) do
        MiniTest.expect.equality(names[server], true, "missing server: " .. server)
    end
end

T["_check_lsp_configs"] = MiniTest.new_set()

T["_check_lsp_configs"]["returns structured results"] = function()
    local results = health._check_lsp_configs()
    MiniTest.expect.equality(type(results), "table")
    MiniTest.expect.equality(#results > 0, true)

    local first = results[1]
    MiniTest.expect.equality(type(first.name), "string")
    MiniTest.expect.equality(type(first.path), "string")
    MiniTest.expect.equality(type(first.exists), "boolean")
end

T["_check_lsp_configs"]["existing configs report correctly"] = function()
    local results = health._check_lsp_configs()
    local lua_ls_result = nil
    for _, r in ipairs(results) do
        if r.name == "lua_ls" then
            lua_ls_result = r
            break
        end
    end

    MiniTest.expect.equality(lua_ls_result ~= nil, true)
    MiniTest.expect.equality(lua_ls_result.exists, true)
end

T["_check_fre_tools"] = MiniTest.new_set()

T["_check_fre_tools"]["returns structured results"] = function()
    local results = health._check_fre_tools()
    MiniTest.expect.equality(type(results), "table")
    MiniTest.expect.equality(#results > 0, true)

    local first = results[1]
    MiniTest.expect.equality(type(first.name), "string")
    MiniTest.expect.equality(type(first.ecosystem), "string")
    MiniTest.expect.equality(type(first.found), "boolean")
    MiniTest.expect.equality(type(first.is_local), "boolean")
end

T["_check_fre_tools"]["results are sorted by name"] = function()
    local results = health._check_fre_tools()
    for i = 2, #results do
        MiniTest.expect.equality(results[i - 1].name < results[i].name, true)
    end
end

T["_check_system_tools"] = MiniTest.new_set()

T["_check_system_tools"]["returns structured results"] = function()
    local results = health._check_system_tools()
    MiniTest.expect.equality(type(results), "table")
    MiniTest.expect.equality(#results > 0, true)

    local first = results[1]
    MiniTest.expect.equality(type(first.name), "string")
    MiniTest.expect.equality(type(first.category), "string")
    MiniTest.expect.equality(type(first.found), "boolean")
end

T["_check_system_tools"]["results are sorted by name"] = function()
    local results = health._check_system_tools()
    for i = 2, #results do
        MiniTest.expect.equality(results[i - 1].name < results[i].name, true)
    end
end

T["_check_system_tools"]["deduplicates tools"] = function()
    local results = health._check_system_tools()
    local seen = {}
    for _, r in ipairs(results) do
        MiniTest.expect.equality(seen[r.name], nil, "duplicate tool: " .. r.name)
        seen[r.name] = true
    end
end

T["_check_core_plugins"] = MiniTest.new_set()

T["_check_core_plugins"]["returns structured results"] = function()
    local results = health._check_core_plugins()
    MiniTest.expect.equality(type(results), "table")
    MiniTest.expect.equality(#results > 0, true)

    local first = results[1]
    MiniTest.expect.equality(type(first.name), "string")
    MiniTest.expect.equality(type(first.required), "boolean")
    MiniTest.expect.equality(type(first.loaded), "boolean")
end

T["_check_core_plugins"]["mini.deps is required and loaded"] = function()
    local results = health._check_core_plugins()
    local mini_deps = nil
    for _, r in ipairs(results) do
        if r.name == "mini.deps" then
            mini_deps = r
            break
        end
    end

    MiniTest.expect.equality(mini_deps ~= nil, true)
    MiniTest.expect.equality(mini_deps.required, true)
    MiniTest.expect.equality(mini_deps.loaded, true)
end

T["check"] = MiniTest.new_set()

T["check"]["runs without error"] = function()
    local ok, err = pcall(health.check)
    MiniTest.expect.equality(ok, true, "health.check() failed: " .. tostring(err))
end

if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
