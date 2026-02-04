-- Script to check for Lua diagnostics in a headless Neovim instance
-- This runs AFTER normal init.lua has loaded, so LSP is already configured
-- Usage: MINI_DEPS_LATER_AS_NOW=1 nvim --headless +"lua dofile('scripts/check-lua-diagnostics.lua')" +qall file1.lua file2.lua

-- Disable swap files to avoid conflicts with running nvim sessions
vim.opt.swapfile = false
vim.opt.shortmess:append("A") -- Don't show ATTENTION messages for existing swap files

local files = {}
for _, arg in ipairs(vim.v.argv) do
    if vim.fn.filereadable(arg) == 1 and arg:match("%.lua$") then table.insert(files, vim.fn.fnamemodify(arg, ":p")) end
end

if #files == 0 then
    print("No Lua files to check")
    return
end

-- Batch load all files into buffers first
local buffers = {}
for _, filepath in ipairs(files) do
    local bufnr = vim.fn.bufadd(filepath)
    vim.fn.bufload(bufnr)
    vim.bo[bufnr].filetype = "lua"
    buffers[filepath] = bufnr
end

-- Set the first buffer as current to trigger LSP attachment
local first_file = files[1]
vim.api.nvim_set_current_buf(buffers[first_file])
vim.cmd("edit " .. vim.fn.fnameescape(first_file))

-- Wait for LSP to attach once (not per file)
local lsp_attached = vim.wait(3000, function()
    local clients = vim.lsp.get_clients({ bufnr = buffers[first_file] })
    return #clients > 0
end, 100)

if not lsp_attached then print("Warning: LSP did not attach, diagnostics may be incomplete") end

-- Trigger didOpen for all other buffers (LSP will process them in parallel)
for i = 2, #files do
    local filepath = files[i]
    local bufnr = buffers[filepath]
    vim.api.nvim_set_current_buf(bufnr)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

-- Wait for all diagnostics to be published (batch processing)
-- LSP processes files concurrently, so this is much faster than per-file waits
vim.wait(2000)

-- Collect diagnostics from all files
local has_errors = false
local diagnostics_by_file = {}

for filepath, bufnr in pairs(buffers) do
    local diagnostics = vim.diagnostic.get(bufnr, {
        severity = { min = vim.diagnostic.severity.WARN },
    })

    if #diagnostics > 0 then
        has_errors = true
        diagnostics_by_file[filepath] = diagnostics
    end
end

-- Report diagnostics
if has_errors then
    print("\n=== Lua Diagnostics Found ===\n")
    for filepath, diagnostics in pairs(diagnostics_by_file) do
        print(string.format("File: %s", filepath))
        for _, diag in ipairs(diagnostics) do
            local severity = vim.diagnostic.severity[diag.severity]
            local line = diag.lnum + 1
            local col = diag.col + 1
            print(string.format("  %s:%d:%d: [%s] %s", filepath, line, col, severity, diag.message))
        end
        print("")
    end
    vim.cmd("cquit 1") -- Exit with error code
else
    print("✓ No Lua diagnostics found")
end
