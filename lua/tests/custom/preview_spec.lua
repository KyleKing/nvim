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
    -- Exercise the pandoc path only: the Python fallback needs the importable
    -- `markdown` module, which is not guaranteed even when python3 is on PATH.
    if vim.fn.executable("pandoc") ~= 1 then
        MiniTest.skip("pandoc not available for markdown preview integration test")
        return
    end

    local temp_file = create_temp_file("# Test\n\nParagraph", ".md")
    vim.cmd("edit " .. temp_file)
    -- Force the filetype: this test exercises the convert->open pipeline, not
    -- filetype autodetection, which is order-sensitive under the full test suite.
    vim.bo.filetype = "markdown"

    local preview = require("kyleking.utils.preview")
    preview.setup()

    -- Mock vim.fn.system to prevent actually opening browser
    local original_system = vim.fn.system
    local system_calls = {}
    vim.fn.system = function(cmd)
        table.insert(system_calls, cmd)
        -- If it's a markdown conversion call, actually run it
        if type(cmd) == "table" and (cmd[1] == "pandoc" or cmd[1]:match("python")) then return original_system(cmd) end
        -- If it's an "open" command, just record it
        return ""
    end

    local ok = pcall(preview.preview)
    MiniTest.expect.equality(ok, true, "Should not error with real file")

    -- Verify browser open was attempted
    local had_open_call = false
    for _, call in ipairs(system_calls) do
        if type(call) == "table" and (call[1] == "open" or call[1] == "xdg-open" or call[1] == "start") then
            had_open_call = true
            break
        end
    end
    MiniTest.expect.equality(had_open_call, true, "Should attempt to open browser")

    -- Restore original function
    vim.fn.system = original_system

    -- Cleanup
    vim.fn.delete(temp_file)
end

T["integration"]["embeds relative images as data URIs"] = function()
    if vim.fn.executable("pandoc") ~= 1 then
        MiniTest.skip("pandoc not available for image embedding test")
        return
    end

    -- 1x1 transparent PNG so pandoc has a real relative resource to inline
    local png = vim.base64.decode(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    )
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    local img = dir .. "/pixel.png"
    local img_file = assert(io.open(img, "wb"))
    img_file:write(png)
    img_file:close()

    local md = dir .. "/doc.md"
    local md_file = assert(io.open(md, "w"))
    md_file:write("# Title\n\n![pixel](pixel.png)\n")
    md_file:close()

    vim.cmd("edit " .. md)
    vim.bo.filetype = "markdown"

    local preview = require("kyleking.utils.preview")
    preview.setup()

    local original_system = vim.fn.system
    local opened_html = nil
    vim.fn.system = function(cmd)
        if type(cmd) == "table" and cmd[1] == "pandoc" then return original_system(cmd) end
        if type(cmd) == "table" and (cmd[1] == "open" or cmd[1] == "xdg-open" or cmd[1] == "start") then
            opened_html = cmd[2]
        end
        return ""
    end

    local ok = pcall(preview.preview)
    vim.fn.system = original_system

    MiniTest.expect.equality(ok, true, "Should not error")
    MiniTest.expect.no_equality(opened_html, nil, "Should open generated HTML")

    local html = table.concat(vim.fn.readfile(opened_html), "\n")
    MiniTest.expect.equality(
        html:match('src="data:image') ~= nil,
        true,
        "Relative image should be inlined as a data URI"
    )

    vim.fn.delete(dir, "rf")
    vim.fn.delete(opened_html)
end

T["refresh"] = MiniTest.new_set()

T["refresh"]["preview output has no auto-refresh polling"] = function()
    if vim.fn.executable("pandoc") ~= 1 then
        MiniTest.skip("pandoc not available for refresh test")
        return
    end

    local temp_file = create_temp_file("# One\n", ".md")
    vim.cmd("edit " .. temp_file)
    vim.bo.filetype = "markdown"

    local preview = require("kyleking.utils.preview")
    preview.setup()

    local original_system = vim.fn.system
    local opened_html = nil
    vim.fn.system = function(cmd)
        if type(cmd) == "table" and cmd[1] == "pandoc" then return original_system(cmd) end
        if type(cmd) == "table" and (cmd[1] == "open" or cmd[1] == "xdg-open" or cmd[1] == "start") then
            opened_html = cmd[2]
        end
        return ""
    end

    local ok = pcall(preview.preview)
    vim.fn.system = original_system

    MiniTest.expect.equality(ok, true, "preview should not error")
    MiniTest.expect.no_equality(opened_html, nil, "preview should open generated HTML")

    local html = table.concat(vim.fn.readfile(opened_html), "\n")
    MiniTest.expect.equality(html:match('http%-equiv="refresh"'), nil, "should not poll with meta refresh")
    MiniTest.expect.equality(html:match("sessionStorage") ~= nil, true, "should restore scroll on reload")

    vim.fn.delete(temp_file)
    vim.fn.delete(opened_html)
end

T["refresh"]["re-renders the stable output on repeat invocation"] = function()
    if vim.fn.executable("pandoc") ~= 1 then
        MiniTest.skip("pandoc not available for refresh test")
        return
    end

    local temp_file = create_temp_file("# One\n", ".md")
    vim.cmd("edit " .. temp_file)
    vim.bo.filetype = "markdown"

    local preview = require("kyleking.utils.preview")
    preview.setup()

    local out_path = vim.fn.stdpath("cache") .. "/kyleking-preview.html"

    local original_system = vim.fn.system
    vim.fn.system = function(cmd)
        if type(cmd) == "table" and cmd[1] == "pandoc" then return original_system(cmd) end
        -- Swallow osascript/open so no real browser is touched
        return ""
    end

    pcall(preview.preview)
    local first = table.concat(vim.fn.readfile(out_path), "\n")
    MiniTest.expect.equality(first:match("One") ~= nil, true, "preview should write initial content")

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# Two" })
    local ok = pcall(preview.preview)
    MiniTest.expect.equality(ok, true, "second preview should not error")

    local second = table.concat(vim.fn.readfile(out_path), "\n")
    MiniTest.expect.equality(second:match("Two") ~= nil, true, "repeat preview should regenerate content")

    vim.fn.system = original_system
    vim.fn.delete(temp_file)
    vim.fn.delete(out_path)
end

-- Allow running this file directly
if ... == nil then MiniTest.run() end

return T
