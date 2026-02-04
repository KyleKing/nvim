-- Script to check for Lua diagnostics in a headless Neovim instance
-- This runs AFTER normal init.lua has loaded, so LSP is already configured
-- Usage: MINI_DEPS_LATER_AS_NOW=1 nvim --headless +"lua dofile('scripts/check-lua-diagnostics.lua')" +qall file1.lua file2.lua

-- Disable swap files to avoid conflicts with running nvim sessions
vim.opt.swapfile = false
vim.opt.shortmess:append("A") -- Don't show ATTENTION messages for existing swap files

-- Configuration
local VERBOSE = os.getenv("VERBOSE") == "1"
local FAIL_FAST = os.getenv("FAIL_FAST") == "1" -- Exit on first diagnostic found

local files = {}
for _, arg in ipairs(vim.v.argv) do
    if vim.fn.filereadable(arg) == 1 and arg:match("%.lua$") then table.insert(files, vim.fn.fnamemodify(arg, ":p")) end
end

if #files == 0 then
    print("No Lua files to check")
    return
end

if VERBOSE then print(string.format("Checking %d Lua files for diagnostics...", #files)) end

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

if VERBOSE then print("Waiting for LSP to attach...") end

-- Wait for LSP to attach once (not per file) - optimized with shorter interval
local lsp_attached = vim.wait(2500, function()
    local clients = vim.lsp.get_clients({ bufnr = buffers[first_file] })
    return #clients > 0
end, 50)

if not lsp_attached then
    print("Warning: LSP did not attach, diagnostics may be incomplete")
elseif VERBOSE then
    local clients = vim.lsp.get_clients({ bufnr = buffers[first_file] })
    print(string.format("LSP attached: %s", clients[1] and clients[1].name or "unknown"))
end

if VERBOSE then print("Loading files and waiting for diagnostics...") end

-- Trigger didOpen for all other buffers (LSP will process them in parallel)
for i = 2, #files do
    local filepath = files[i]
    local bufnr = buffers[filepath]
    vim.api.nvim_set_current_buf(bufnr)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

-- Optimized wait: shorter delay since LSP processes files in parallel
-- For fail-fast mode, check periodically for errors
if FAIL_FAST then
    local timeout = vim.uv.now() + 3000
    while vim.uv.now() < timeout do
        vim.wait(200) -- Check every 200ms
        local found_any = false
        for _, bufnr in pairs(buffers) do
            local diagnostics = vim.diagnostic.get(bufnr, { severity = { min = vim.diagnostic.severity.WARN } })
            if #diagnostics > 0 then
                found_any = true
                break
            end
        end
        if found_any then break end
    end
else
    -- Standard mode: single wait for all diagnostics
    vim.wait(1500) -- Reduced from 2000ms, LSP typically publishes faster
end

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
        if FAIL_FAST then break end -- Exit early in fail-fast mode
    end
end

-- Report diagnostics
if has_errors then
    print("\n=== Lua Diagnostics Found ===\n")
    local total_diagnostics = 0
    for filepath, diagnostics in pairs(diagnostics_by_file) do
        print(string.format("File: %s", filepath))
        for _, diag in ipairs(diagnostics) do
            local severity = vim.diagnostic.severity[diag.severity]
            local line = diag.lnum + 1
            local col = diag.col + 1
            print(string.format("  %s:%d:%d: [%s] %s", filepath, line, col, severity, diag.message))
            total_diagnostics = total_diagnostics + 1
        end
        print("")
    end
    if VERBOSE then
        print(
            string.format(
                "Found %d diagnostic%s in %d file%s",
                total_diagnostics,
                total_diagnostics == 1 and "" or "s",
                vim.tbl_count(diagnostics_by_file),
                vim.tbl_count(diagnostics_by_file) == 1 and "" or "s"
            )
        )
    end
    vim.cmd("cquit 1") -- Exit with error code
else
    if VERBOSE then
        print(string.format("✓ No diagnostics found in %d file%s", #files, #files == 1 and "" or "s"))
    else
        print("✓ No Lua diagnostics found")
    end
end
