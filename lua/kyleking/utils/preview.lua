-- Preview markdown and djot files using CLI tools

local M = {}

-- Find available preview tools
local function find_tool(candidates)
    for _, cmd in ipairs(candidates) do
        if vim.fn.executable(cmd) ~= 0 then return cmd end
    end
    return nil
end

-- Get HTML from markdown using available tools
local function markdown_to_html(filepath)
    -- Try tools in order of preference
    local pandoc = find_tool({ "pandoc" })
    if pandoc then return vim.fn.system({ pandoc, "-f", "markdown", "-t", "html", filepath }) end

    -- Python markdown module
    local python = find_tool({ "python3", "python" })
    if python then
        local cmd =
            string.format("%s -c 'import markdown; print(markdown.markdown(open(\"%s\").read()))'", python, filepath)
        return vim.fn.system(cmd)
    end

    return nil, "No markdown converter found. Install pandoc or Python markdown module."
end

-- Get HTML from djot using djot CLI
local function djot_to_html(filepath)
    local djot = find_tool({ "djot" })
    if not djot then return nil, "djot CLI not found. Install with: npm install -g @djot/djot" end

    return vim.fn.system({ djot, filepath })
end

-- Write HTML to temp file and open in browser
local function open_in_browser(html, filetype)
    local temp_file = vim.fn.tempname() .. ".html"
    local file = io.open(temp_file, "w")
    if not file then
        vim.notify("Failed to create temp file: " .. temp_file, vim.log.levels.ERROR)
        return
    end

    -- Wrap in basic HTML structure
    local full_html = string.format(
        [[
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Preview - %s</title>
    <style>
        body {
            max-width: 800px;
            margin: 2rem auto;
            padding: 0 1rem;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
            line-height: 1.6;
        }
        pre { background: #f6f8fa; padding: 1rem; overflow-x: auto; }
        code { background: #f6f8fa; padding: 0.2em 0.4em; border-radius: 3px; }
        table { border-collapse: collapse; width: 100%%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f6f8fa; }
    </style>
</head>
<body>
%s
</body>
</html>
]],
        filetype,
        html
    )

    file:write(full_html)
    file:close()

    -- Open in browser (macOS)
    if vim.fn.has("mac") == 1 then
        vim.fn.system({ "open", temp_file })
    elseif vim.fn.has("unix") == 1 then
        vim.fn.system({ "xdg-open", temp_file })
    elseif vim.fn.has("win32") == 1 then
        vim.fn.system({ "start", temp_file })
    else
        vim.notify("Preview file created: " .. temp_file, vim.log.levels.INFO)
    end
end

-- Preview current buffer
function M.preview()
    local ft = vim.bo.filetype
    local filepath = vim.api.nvim_buf_get_name(0)

    if filepath == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
    end

    -- Save buffer if modified
    if vim.bo.modified then vim.cmd("write") end

    local html, err
    if ft == "markdown" then
        html, err = markdown_to_html(filepath)
    elseif ft == "djot" then
        html, err = djot_to_html(filepath)
    else
        vim.notify("Preview not supported for filetype: " .. ft, vim.log.levels.ERROR)
        return
    end

    if not html or html == "" then
        vim.notify(err or "Failed to generate HTML", vim.log.levels.ERROR)
        return
    end

    open_in_browser(html, ft)
end

-- Setup keymaps and commands
function M.setup()
    vim.api.nvim_create_user_command("Preview", M.preview, { desc = "Preview markdown/djot in browser" })

    -- Add keymap for markdown and djot files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "djot" },
        callback = function()
            vim.keymap.set("n", "<leader>cp", M.preview, { buffer = true, desc = "Preview in browser" })
        end,
        group = vim.api.nvim_create_augroup("kyleking_preview", { clear = true }),
    })
end

return M
