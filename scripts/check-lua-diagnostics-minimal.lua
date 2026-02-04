-- Minimal Lua diagnostics checker - loads ONLY LSP, no other plugins
-- This is 2-3x faster than the full version
-- Usage: nvim --headless --clean +"lua dofile('scripts/check-lua-diagnostics-minimal.lua')" file1.lua file2.lua

-- Disable swap files to avoid conflicts
vim.opt.swapfile = false
vim.opt.shortmess:append("A")

-- Configuration
local VERBOSE = os.getenv("VERBOSE") == "1"
local FAIL_FAST = os.getenv("FAIL_FAST") == "1"

-- Minimal LSP setup - just lua_ls with .luarc.json config
vim.lsp.config.lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".git" },
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = { checkThirdParty = false },
        },
    },
}
vim.lsp.enable("lua_ls")

-- Get files to check
local files = {}
for _, arg in ipairs(vim.v.argv) do
    if vim.fn.filereadable(arg) == 1 and arg:match("%.lua$") then table.insert(files, vim.fn.fnamemodify(arg, ":p")) end
end

if #files == 0 then
    print("No Lua files to check")
    return
end

if VERBOSE then print(string.format("Checking %d Lua files (minimal mode)...", #files)) end

-- Batch load all files
local buffers = {}
for _, filepath in ipairs(files) do
    local bufnr = vim.fn.bufadd(filepath)
    vim.fn.bufload(bufnr)
    vim.bo[bufnr].filetype = "lua"
    buffers[filepath] = bufnr
end

-- Set first buffer as current to trigger LSP
local first_file = files[1]
vim.api.nvim_set_current_buf(buffers[first_file])
vim.cmd("edit " .. vim.fn.fnameescape(first_file))

if VERBOSE then print("Waiting for LSP...") end

-- Wait for LSP (reduced timeout: 1.5s instead of 2.5s)
local lsp_attached = vim.wait(1500, function()
    local clients = vim.lsp.get_clients({ bufnr = buffers[first_file] })
    return #clients > 0
end, 50)

if not lsp_attached then
    print("Warning: LSP did not attach")
elseif VERBOSE then
    local clients = vim.lsp.get_clients({ bufnr = buffers[first_file] })
    print(string.format("LSP attached: %s", clients[1] and clients[1].name or "unknown"))
end

-- Trigger didOpen for remaining files
for i = 2, #files do
    local filepath = files[i]
    local bufnr = buffers[filepath]
    vim.api.nvim_set_current_buf(bufnr)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

-- Wait for diagnostics (reduced: 1s instead of 1.5s)
local function has_diagnostics()
    for _, bufnr in pairs(buffers) do
        local diagnostics = vim.diagnostic.get(bufnr, { severity = { min = vim.diagnostic.severity.WARN } })
        if #diagnostics > 0 then return true end
    end
    return false
end

if FAIL_FAST then
    local timeout_at = vim.uv.now() + 1000
    while vim.uv.now() < timeout_at do
        vim.wait(100)
        if has_diagnostics() then break end
    end
else
    vim.wait(1000)
end
-- Collect and report diagnostics
local has_errors = false
local diagnostics_by_file = {}

for filepath, bufnr in pairs(buffers) do
    local diagnostics = vim.diagnostic.get(bufnr, { severity = { min = vim.diagnostic.severity.WARN } })
    if #diagnostics > 0 then
        has_errors = true
        diagnostics_by_file[filepath] = diagnostics
        if FAIL_FAST then break end
    end
end

if has_errors then
    print("\n=== Lua Diagnostics Found ===\n")
    for filepath, diagnostics in pairs(diagnostics_by_file) do
        print(string.format("File: %s", filepath))
        for _, diag in ipairs(diagnostics) do
            local severity = vim.diagnostic.severity[diag.severity]
            print(string.format("  %s:%d:%d: [%s] %s", filepath, diag.lnum + 1, diag.col + 1, severity, diag.message))
        end
        print("")
    end
    vim.cmd("cquit 1")
else
    if VERBOSE then
        print(string.format("✓ No diagnostics in %d file%s", #files, #files == 1 and "" or "s"))
    else
        print("✓ No Lua diagnostics found")
    end
    vim.cmd("qall!") -- Explicit clean exit
end
