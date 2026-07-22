local MiniTest = require("mini.test")
local runner = require("tests.docs.runner")

local T = MiniTest.new_set({
    hooks = {
        -- A fixture that leaves a pinned window current (mini.files, mini.pick) breaks
        -- buffer switching for every fixture after it, and unconsumed keys replay
        -- inside whichever fixture runs next
        pre_case = function()
            local helpers = require("tests.helpers")
            -- An explorer left open swallows keys meant for the next fixture
            pcall(function() require("mini.files").close() end)
            helpers.clear_winfixbuf()
            helpers.reset_pending_state()
        end,
        post_once = function()
            runner.print_profiling_summary()
            runner.clear_snapshot_cache()
        end,
    },
})

-- Discover all fixture files
local fixture_files = vim.fn.glob("lua/tests/docs/*.lua", false, true)
fixture_files = vim.tbl_filter(function(f)
    local name = vim.fn.fnamemodify(f, ":t")
    return name ~= "runner.lua"
        and name ~= "generator.lua"
        and name ~= "init.lua"
        and name ~= "validate_documentation.lua"
        and not name:match("_spec%.lua$")
end, fixture_files)

for _, fixture_path in ipairs(fixture_files) do
    local name = vim.fn.fnamemodify(fixture_path, ":t:r")
    T[name] = function() runner.run_fixture(fixture_path) end
end

if ... == nil then MiniTest.run() end

return T
