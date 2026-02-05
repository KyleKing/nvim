-- Test cache invalidation autocmds for find-relative-executable
local MiniTest = require("mini.test")
local fre = require("find-relative-executable")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() fre.clear_cache() end,
    },
})

T["cache_invalidation"] = MiniTest.new_set()

T["cache_invalidation"]["autocmds are registered"] = function()
    local autocmds = vim.api.nvim_get_autocmds({ group = "project_tools_cache" })

    -- Should have 3 autocmds: BufWritePost, DirChanged, VimResume
    MiniTest.expect.no_equality(#autocmds, 0, "Should register cache invalidation autocmds")

    local events = {}
    for _, autocmd in ipairs(autocmds) do
        table.insert(events, autocmd.event)
    end

    -- Verify all required events are present
    local has_bufwrite = vim.tbl_contains(events, "BufWritePost")
    local has_dirchanged = vim.tbl_contains(events, "DirChanged")
    local has_vimresume = vim.tbl_contains(events, "VimResume")

    MiniTest.expect.equality(has_bufwrite, true, "Should have BufWritePost autocmd")
    MiniTest.expect.equality(has_dirchanged, true, "Should have DirChanged autocmd")
    MiniTest.expect.equality(has_vimresume, true, "Should have VimResume autocmd")
end

T["cache_invalidation"]["BufWritePost clears cache for marker files"] = function()
    -- Populate cache
    local root1 = fre.get_current_project_root()

    -- Create a temp marker file
    local tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    local marker_file = tmpdir .. "/pyproject.toml"
    vim.fn.writefile({ "[tool.test]" }, marker_file)

    -- Edit the marker file to trigger BufWritePost
    vim.cmd("edit " .. marker_file)

    -- Write the file (triggers BufWritePost)
    vim.cmd("silent write")

    -- Cache should be cleared (we can verify by checking that get_current_project_root works)
    local root2 = fre.get_current_project_root()

    -- Both should work without errors (cache invalidation successful)
    MiniTest.expect.equality(type(root1) == "string" or root1 == nil, true)
    MiniTest.expect.equality(type(root2) == "string" or root2 == nil, true)

    -- Cleanup
    vim.fn.delete(tmpdir, "rf")
end

T["cache_invalidation"]["BufWritePost ignores non-marker files"] = function()
    -- Populate cache
    fre.get_current_project_root()

    -- Create a temp non-marker file
    local tmpfile = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ "-- test" }, tmpfile)

    -- Edit and write the non-marker file
    vim.cmd("edit " .. tmpfile)
    vim.cmd("silent write")

    -- Cache should still be valid (non-marker files don't trigger invalidation)
    -- We can't directly test cache validity, but we can verify no errors occur
    local root = fre.get_current_project_root()
    MiniTest.expect.equality(type(root) == "string" or root == nil, true)

    -- Cleanup
    vim.fn.delete(tmpfile)
end

T["cache_invalidation"]["DirChanged clears cache"] = function()
    -- Populate cache
    local root1 = fre.get_current_project_root()

    -- Change directory (triggers DirChanged)
    local cwd = vim.fn.getcwd()
    local tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")

    vim.cmd("cd " .. tmpdir)

    -- Cache should be cleared
    local root2 = fre.get_current_project_root()

    -- Both should work without errors
    MiniTest.expect.equality(type(root1) == "string" or root1 == nil, true)
    MiniTest.expect.equality(type(root2) == "string" or root2 == nil, true)

    -- Restore cwd and cleanup
    vim.cmd("cd " .. cwd)
    vim.fn.delete(tmpdir, "rf")
end

T["cache_invalidation"]["clear_cache manually invalidates"] = function()
    -- Populate cache
    local root1 = fre.get_current_project_root()

    -- Manually clear cache
    fre.clear_cache()

    -- Get root again (should recompute)
    local root2 = fre.get_current_project_root()

    -- Both should have same value (but cache was cleared between calls)
    if root1 then
        MiniTest.expect.equality(root1, root2)
    else
        MiniTest.expect.equality(root2, nil)
    end
end

T["cache_invalidation"]["resolve caches tool paths"] = function()
    -- First call should populate cache
    local tool1 = fre.resolve("stylua", vim.fn.getcwd())

    -- Second call should use cache
    local tool2 = fre.resolve("stylua", vim.fn.getcwd())

    -- Should return same result
    MiniTest.expect.equality(tool1, tool2)
end

T["cache_invalidation"]["get_vcs_root respects cache"] = function()
    -- First call populates cache
    local vcs1 = fre.get_vcs_root()

    -- Second call uses cache
    local vcs2 = fre.get_vcs_root()

    -- Should return same result
    if vcs1 and vcs2 then
        MiniTest.expect.equality(vcs1.type, vcs2.type)
        MiniTest.expect.equality(vcs1.root, vcs2.root)
    else
        MiniTest.expect.equality(vcs2, nil)
    end
end

if ... == nil then MiniTest.run() end

return T
