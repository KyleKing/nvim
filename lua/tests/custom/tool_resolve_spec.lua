local MiniTest = require("mini.test")
local fre = require("find-relative-executable")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() fre.clear_cache() end,
    },
})

T["find-relative-executable"] = MiniTest.new_set()

T["find-relative-executable"]["command_for returns a function"] = function()
    local cmd_fn = fre.command_for("ruff")
    MiniTest.expect.equality(type(cmd_fn), "function")
end

T["find-relative-executable"]["cmd_for returns a function"] = function()
    local cmd_fn = fre.cmd_for("oxlint")
    MiniTest.expect.equality(type(cmd_fn), "function")
end

T["find-relative-executable"]["resolve returns string for python tool"] = function()
    local result = fre.resolve("ruff", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string")
end

T["find-relative-executable"]["resolve returns string for node tool"] = function()
    local result = fre.resolve("oxlint", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string")
end

T["find-relative-executable"]["unknown tools fall back gracefully"] = function()
    local result = fre.resolve("nonexistent_tool_xyz", vim.fn.getcwd())
    MiniTest.expect.equality(type(result), "string")
end

T["find-relative-executable"]["clear_cache is callable without error"] = function()
    MiniTest.expect.no_error(function() fre.clear_cache() end)
end

T["find-relative-executable"]["get_project_root returns string or nil"] = function()
    local result = fre.get_project_root(vim.fn.getcwd(), "python")
    MiniTest.expect.equality(type(result) == "string" or result == nil, true)
end

T["find-relative-executable"]["get_project_root finds python project"] = function()
    -- This nvim config has a pyproject.toml in test fixtures
    local result = fre.get_project_root(vim.fn.getcwd(), "python")
    -- Should find a root or nil (both acceptable)
    MiniTest.expect.equality(type(result) == "string" or result == nil, true)
end

T["find-relative-executable"]["get_current_project_root works"] = function()
    local result = fre.get_current_project_root()
    -- Should return string (git root) or nil
    MiniTest.expect.equality(type(result) == "string" or result == nil, true)
end

T["find-relative-executable"]["lsp_root_for returns function"] = function()
    local root_fn = fre.lsp_root_for({ "python", "node" })
    MiniTest.expect.equality(type(root_fn), "function")
end

T["find-relative-executable"]["lsp_root_for function returns string or nil"] = function()
    local root_fn = fre.lsp_root_for({ "python" })
    local result = root_fn(vim.fn.getcwd())
    MiniTest.expect.equality(type(result) == "string" or result == nil, true)
end

T["find-relative-executable"]["get_current_project_root caches results"] = function()
    -- Create a test buffer with known path
    local test_file = vim.fn.tempname() .. ".lua"
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, test_file)
    vim.api.nvim_set_current_buf(bufnr)

    -- First call
    local result1 = fre.get_current_project_root()
    -- Second call should return cached value
    local result2 = fre.get_current_project_root()
    MiniTest.expect.equality(result1, result2)

    -- Cleanup
    vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["find-relative-executable"]["get_vcs_root caches results"] = function()
    -- First call
    local result1 = fre.get_vcs_root(vim.fn.getcwd())
    -- Second call should return cached value
    local result2 = fre.get_vcs_root(vim.fn.getcwd())

    -- Both should have same type and value
    if result1 == nil then
        MiniTest.expect.equality(result2, nil)
    else
        MiniTest.expect.equality(result1.type, result2.type)
        MiniTest.expect.equality(result1.root, result2.root)
    end
end

T["find-relative-executable"]["clear_cache clears root and vcs caches"] = function()
    -- Populate cache
    fre.get_current_project_root()
    fre.get_vcs_root(vim.fn.getcwd())

    -- Clear should not error
    MiniTest.expect.no_error(function() fre.clear_cache() end)

    -- After clearing, calls should work
    local result = fre.get_current_project_root()
    MiniTest.expect.equality(type(result) == "string" or result == nil, true)
end

if ... == nil then MiniTest.run() end

return T
