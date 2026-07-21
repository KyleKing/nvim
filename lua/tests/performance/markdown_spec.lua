-- Markdown performance and regression benchmarks
-- Guards the "many injected code blocks" edge case: Neovim's built-in markdown ftplugin
-- calls vim.treesitter.start() directly, so the large_buf highlight guard must stop it.
local MiniTest = require("mini.test")
local constants = require("kyleking.utils.constants")

local T = MiniTest.new_set({ hooks = { pre_case = function() end } })

local LANGS = { "bash", "go", "json", "lua", "python", "rust", "sql", "typescript", "yaml" }

local function markdown_blocks(n_blocks)
    local lines = { "# Fixture", "" }
    for i = 1, n_blocks do
        local lang = LANGS[(i % #LANGS) + 1]
        vim.list_extend(lines, {
            "## Section " .. i,
            "",
            "Prose " .. i .. " with `inline` code.",
            "",
            "```" .. lang,
            "value = " .. i,
            "```",
            "",
        })
    end
    return lines
end

local function open_markdown_buffer(n_blocks)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, markdown_blocks(n_blocks))
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = "markdown"
    return buf
end

T["large_buf guard"] = MiniTest.new_set()

T["large_buf guard"]["stops treesitter on oversized markdown"] = function()
    local n_blocks = math.ceil(constants.LARGE_BUF.MAX_LINES / 4)
    local buf = open_markdown_buffer(n_blocks)

    MiniTest.expect.equality(vim.b[buf].large_buf, true, "Oversized markdown should be flagged")
    MiniTest.expect.equality(
        vim.treesitter.highlighter.active[buf],
        nil,
        "Treesitter highlight should be stopped on oversized markdown"
    )

    vim.api.nvim_buf_delete(buf, { force = true })
end

T["large_buf guard"]["keeps highlight on normal markdown"] = function()
    local buf = open_markdown_buffer(30)

    MiniTest.expect.equality(vim.b[buf].large_buf == nil, true, "Normal markdown should not be flagged")
    MiniTest.expect.equality(
        vim.treesitter.highlighter.active[buf] ~= nil,
        true,
        "Treesitter highlight should stay active on normal markdown"
    )

    vim.api.nvim_buf_delete(buf, { force = true })
end

T["injection rendering"] = MiniTest.new_set()

T["injection rendering"]["parses many code blocks without errors"] = function()
    local tmpfile = vim.fn.tempname() .. ".md"
    local lines = markdown_blocks(300)
    vim.fn.writefile(lines, tmpfile)

    local start = vim.loop.now()
    local result = vim.system({
        "nvim",
        "--headless",
        "-c",
        "edit " .. tmpfile,
        -- Force injected-language trees to parse; surfaces any parser/injection error
        "-c",
        "lua vim.treesitter.get_parser(0):parse(true)",
        "-c",
        "messages",
        "-c",
        "qall!",
    }, { text = true }):wait(10000)
    local elapsed = vim.loop.now() - start

    print(string.format("Parsed 300-block markdown in %.0fms", elapsed))

    MiniTest.expect.equality(result.code, 0, "Should open complex markdown: " .. (result.stderr or ""))
    local stderr = result.stderr or ""
    local has_error = stderr:match("[Ee]rror") ~= nil or stderr:match("E%d+:") ~= nil
    MiniTest.expect.equality(has_error, false, "Should have no errors on complex markdown: " .. stderr)
    MiniTest.expect.equality(elapsed < 10000, true, "Should parse complex markdown under 10s")

    vim.fn.delete(tmpfile)
end

if ... == nil then MiniTest.run() end

return T
