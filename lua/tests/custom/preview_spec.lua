-- Tests for preview utility
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            vim.cmd("enew")
            vim.bo.filetype = "markdown"
        end,
        post_case = function()
            if vim.api.nvim_buf_is_valid(0) then vim.api.nvim_buf_delete(0, { force = true }) end
        end,
    },
})

-- Helper to create a temp file
local function create_temp_file(content, extension)
    local temp = vim.fn.tempname() .. extension
    local file = io.open(temp, "w")
    if file then
        file:write(content)
        file:close()
    end
    return temp
end

T["setup"] = MiniTest.new_set()

T["setup"]["creates Preview command"] = function()
    local preview = require("kyleking.utils.preview")
    preview.setup()

    local commands = vim.api.nvim_get_commands({})
    MiniTest.expect.no_equality(commands["Preview"], nil, ":Preview command should exist")
end

T["setup"]["creates autocmd for markdown"] = function()
    local preview = require("kyleking.utils.preview")
    preview.setup()

    local autocmds = vim.api.nvim_get_autocmds({ group = "kyleking_preview", event = "FileType" })
    MiniTest.expect.no_equality(#autocmds, 0, "Should create FileType autocmd")

    -- Check pattern includes markdown
    local has_markdown = false
    for _, cmd in ipairs(autocmds) do
        if cmd.pattern and vim.tbl_contains(vim.split(cmd.pattern, ","), "markdown") then has_markdown = true end
    end
    MiniTest.expect.equality(has_markdown, true, "Should include markdown pattern")
end

T["setup"]["creates autocmd for djot"] = function()
    local preview = require("kyleking.utils.preview")
    preview.setup()

    local autocmds = vim.api.nvim_get_autocmds({ group = "kyleking_preview", event = "FileType" })

    -- Check pattern includes djot
    local has_djot = false
    for _, cmd in ipairs(autocmds) do
        if cmd.pattern and vim.tbl_contains(vim.split(cmd.pattern, ","), "djot") then has_djot = true end
    end
    MiniTest.expect.equality(has_djot, true, "Should include djot pattern")
end

T["setup"]["creates keymap in markdown files"] = function()
    local preview = require("kyleking.utils.preview")
    preview.setup()

    -- Trigger the autocmd by setting filetype
    vim.bo.filetype = "markdown"
    vim.cmd("doautocmd FileType markdown")

    -- Check that keymap exists
    local mappings = vim.api.nvim_buf_get_keymap(0, "n")
    local has_preview_map = false

    for _, map in ipairs(mappings) do
        if map.lhs == " cp" or map.lhs:match("cp") then has_preview_map = true end
    end

    MiniTest.expect.equality(has_preview_map, true, "Should map <leader>cp")
end

T["preview"] = MiniTest.new_set()

T["preview"]["function exists"] = function()
    local preview = require("kyleking.utils.preview")
    MiniTest.expect.equality(type(preview.preview), "function", "preview() should be a function")
end

T["preview"]["handles empty buffer name"] = function()
    local preview = require("kyleking.utils.preview")
    preview.setup()

    -- Create buffer without file path
    vim.cmd("enew")
    vim.bo.filetype = "markdown"

    -- Should not error, but won't do anything without a filepath
    -- This just verifies the function handles the case gracefully
    local ok = pcall(preview.preview)
    MiniTest.expect.equality(ok, true, "Should not error on empty buffer")
end

T["preview"]["handles unsupported filetype"] = function()
    local preview = require("kyleking.utils.preview")
    preview.setup()

    vim.cmd("enew")
    vim.bo.filetype = "lua"

    -- Should handle gracefully
    local ok = pcall(preview.preview)
    MiniTest.expect.equality(ok, true, "Should not error on unsupported filetype")
end

T["markdown_to_html"] = MiniTest.new_set()

T["markdown_to_html"]["detects available tools"] = function()
    -- Check if pandoc or python markdown is available
    local has_pandoc = vim.fn.executable("pandoc") == 1
    local has_python = vim.fn.executable("python3") == 1 or vim.fn.executable("python") == 1

    -- At least one should be available for CI/dev environment
    -- This is informational rather than a hard requirement
    if not has_pandoc and not has_python then
        vim.notify("Note: Neither pandoc nor Python found for markdown preview", vim.log.levels.WARN)
    end

    MiniTest.expect.equality(type(has_pandoc), "boolean", "Pandoc detection should return boolean")
    MiniTest.expect.equality(type(has_python), "boolean", "Python detection should return boolean")
end

T["djot_to_html"] = MiniTest.new_set()

T["djot_to_html"]["detects djot CLI"] = function()
    local has_djot = vim.fn.executable("djot") == 1

    if not has_djot then
        vim.notify("Note: djot CLI not found. Install with: npm install -g @djot/djot", vim.log.levels.INFO)
    end

    MiniTest.expect.equality(type(has_djot), "boolean", "Djot detection should return boolean")
end

T["integration"] = MiniTest.new_set()

T["integration"]["works with real markdown file"] = function()
    -- Skip if no tools available
    local has_pandoc = vim.fn.executable("pandoc") == 1
    local has_python = vim.fn.executable("python3") == 1 or vim.fn.executable("python") == 1

    if not has_pandoc and not has_python then
        MiniTest.skip("No markdown converter available")
        return
    end

    local temp_file = create_temp_file("# Test\n\nParagraph", ".md")
    vim.cmd("edit " .. temp_file)

    local preview = require("kyleking.utils.preview")
    preview.setup()

    -- This will attempt to open browser, which we can't test in headless
    -- But we can verify the file operations don't error
    local ok = pcall(preview.preview)
    MiniTest.expect.equality(ok, true, "Should not error with real file")

    -- Cleanup
    vim.fn.delete(temp_file)
end

-- Allow running this file directly
if ... == nil then MiniTest.run() end

return T
