-- Globally discovery of bin directories for local executables like flake8 and eslint
-- NOTE: This module is now supplemented by workspace_detection.lua which provides
-- comprehensive monorepo support with configurable depth and multiple marker types

local M = {}

local node_modules_path = {}

vim.cmd([[
augroup NodeModulesDetect
  autocmd!
  autocmd BufEnter * lua detect_node_modules()
augroup END
]])

function M.detect_node_modules()
    local bufname = vim.fn.expand("%:p:h") -- Get the path of the currently visible buffer
    local parent_dirs = {}
    for dir in bufname:gmatch("[^/]+") do
        table.insert(parent_dirs, dir)
        local parent_path = table.concat(parent_dirs, "/")
        local node_modules_check = parent_path .. "/node_modules"
        if vim.fn.isdirectory(node_modules_check) == 1 then
            node_modules_path[bufname] = node_modules_check
            return node_modules_path[bufname] -- FIXME: Add short-circuit logic
        end
    end
    node_modules_path[bufname] = nil
end

return M
