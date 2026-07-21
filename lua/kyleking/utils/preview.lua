-- Preview markdown and djot files using CLI tools

local M = {}

-- Single stable output path so on-demand refresh can reload the same browser tab
local function preview_path() return vim.fn.stdpath("cache") .. "/kyleking-preview.html" end

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
    if pandoc then
        -- gfm for task lists/strikethrough/tables; --embed-resources inlines images as
        -- data URIs (no --standalone, so output stays a fragment for the wrapper below);
        -- --resource-path resolves relative image paths
        local dir = vim.fn.fnamemodify(filepath, ":h")
        return vim.fn.system({
            pandoc,
            "-f",
            "gfm",
            "-t",
            "html",
            "--embed-resources",
            "--resource-path",
            dir,
            filepath,
        })
    end

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

local function generate_html(filepath, ft)
    if ft == "markdown" then return markdown_to_html(filepath) end
    if ft == "djot" then return djot_to_html(filepath) end
    return nil, "Preview not supported for filetype: " .. ft
end

-- Wrap a body fragment in a themed HTML document. The scroll-restore script keeps the
-- viewport in place across an on-demand reload of the same URL.
local function wrap_html(body, filetype)
    return table.concat({
        [[<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Preview - ]],
        filetype,
        [[</title>
    <script>
        addEventListener("beforeunload", function () { sessionStorage.setItem("y", String(scrollY)); });
        addEventListener("load", function () {
            var y = sessionStorage.getItem("y");
            if (y !== null) scrollTo(0, parseInt(y, 10));
        });
    </script>
    <style>
        body {
            max-width: 800px;
            margin: 2rem auto;
            padding: 0 1rem;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #1f2328;
            background: #ffffff;
        }
        a { color: #0969da; }
        img { max-width: 100%; height: auto; }
        hr { border: 0; border-top: 1px solid #d0d7de; margin: 1.5rem 0; }
        blockquote {
            margin: 0 0 1rem 0;
            padding: 0 1em;
            color: #656d76;
            border-left: 0.25em solid #d0d7de;
        }
        pre { background: #f6f8fa; padding: 1rem; overflow-x: auto; border-radius: 6px; }
        code { background: #f6f8fa; padding: 0.2em 0.4em; border-radius: 3px; }
        pre code { background: none; padding: 0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #d0d7de; padding: 8px; text-align: left; }
        th { background-color: #f6f8fa; }
        .sourceCode a { color: inherit; text-decoration: none; }
        .kw, .cf, .op { color: #cf222e; }
        .dt, .bu { color: #953800; }
        .dv, .bn, .fl, .cn { color: #0550ae; }
        .st, .ch, .vs, .ss { color: #0a3069; }
        .co { color: #6e7781; font-style: italic; }
        .fu { color: #8250df; }
        .pp, .im { color: #cf222e; }
        @media (prefers-color-scheme: dark) {
            body { color: #e6edf3; background: #0d1117; }
            a { color: #4493f8; }
            hr { border-top-color: #30363d; }
            blockquote { color: #8b949e; border-left-color: #30363d; }
            pre, code { background: #161b22; }
            pre code { background: none; }
            th, td { border-color: #30363d; }
            th { background-color: #161b22; }
            .kw, .cf, .op { color: #ff7b72; }
            .dt, .bu { color: #ffa657; }
            .dv, .bn, .fl, .cn { color: #79c0ff; }
            .st, .ch, .vs, .ss { color: #a5d6ff; }
            .co { color: #8b949e; }
            .fu { color: #d2a8ff; }
            .pp, .im { color: #ff7b72; }
        }
    </style>
</head>
<body>
]],
        body,
        [[
</body>
</html>
]],
    })
end

local function write_atomic(path, content)
    local tmp = path .. ".tmp"
    local file = io.open(tmp, "w")
    if not file then
        vim.notify("Failed to write preview file: " .. tmp, vim.log.levels.ERROR)
        return false
    end
    file:write(content)
    file:close()
    os.rename(tmp, path)
    return true
end

local function open_url(path)
    if vim.fn.has("mac") == 1 then
        vim.fn.system({ "open", path })
    elseif vim.fn.has("unix") == 1 then
        vim.fn.system({ "xdg-open", path })
    elseif vim.fn.has("win32") == 1 then
        vim.fn.system({ "start", path })
    else
        vim.notify("Preview file created: " .. path, vim.log.levels.INFO)
    end
end

-- Foreground (non-background) app names, used to reload only browsers already running
local function running_apps()
    local out = vim.fn.system({
        "osascript",
        "-e",
        'tell application "System Events" to get name of (processes where background only is false)',
    })
    local names = {}
    for _, name in ipairs(vim.split(out, ",", { trimempty = true })) do
        names[vim.trim(name)] = true
    end
    return names
end

-- Firefox exposes no scriptable tab reload, so activate it and send Cmd-R to the
-- active tab. Steals focus and needs Accessibility permission for System Events.
local function reload_firefox()
    vim.fn.system({
        "osascript",
        "-e",
        'tell application "Firefox" to activate',
        "-e",
        'tell application "System Events" to keystroke "r" using command down',
    })
    if vim.v.shell_error ~= 0 then return 0 end
    return 1
end

-- Safari is scriptable, so reload the matching tab in place without stealing focus.
local function reload_safari(needle)
    local script = string.format(
        [[
tell application "Safari"
    set reloaded to 0
    repeat with w in windows
        repeat with t in tabs of w
            try
                if (URL of t) contains "%s" then
                    set URL of t to (URL of t)
                    set reloaded to reloaded + 1
                end if
            end try
        end repeat
    end repeat
    return reloaded
end tell]],
        needle
    )
    local out = vim.fn.system({ "osascript", "-e", script })
    return tonumber(vim.trim(out)) or 0
end

-- Reload the open preview tab. macOS only; returns tabs reloaded (0 if none).
local function reload_browser(needle)
    if vim.fn.has("mac") ~= 1 then return 0 end

    local running = running_apps()
    if running["Firefox"] then return reload_firefox() end
    if running["Safari"] then return reload_safari(needle) end
    return 0
end

local function render(filepath, ft)
    local html, err = generate_html(filepath, ft)
    if not html or html == "" then
        vim.notify(err or "Failed to generate HTML", vim.log.levels.ERROR)
        return nil
    end
    local path = preview_path()
    if not write_atomic(path, wrap_html(html, ft)) then return nil end
    return path
end

local function current_target()
    local ft = vim.bo.filetype
    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return nil
    end
    if ft ~= "markdown" and ft ~= "djot" then
        vim.notify("Preview not supported for filetype: " .. ft, vim.log.levels.ERROR)
        return nil
    end
    if vim.bo.modified then vim.cmd("write") end
    return filepath, ft
end

-- Open a fresh preview of the current buffer in the browser
function M.preview()
    local filepath, ft = current_target()
    if not filepath then return end
    local path = render(filepath, ft)
    if path then open_url(path) end
end

-- Regenerate and reload the open preview tab; open a new one if none is found
function M.refresh()
    local filepath, ft = current_target()
    if not filepath then return end
    local path = render(filepath, ft)
    if not path then return end
    if reload_browser(vim.fn.fnamemodify(path, ":t")) == 0 then open_url(path) end
end

-- Setup keymaps and commands
function M.setup()
    vim.api.nvim_create_user_command("Preview", M.preview, { desc = "Preview markdown/djot in browser" })
    vim.api.nvim_create_user_command("PreviewRefresh", M.refresh, { desc = "Regenerate and reload the preview" })

    -- Add keymap for markdown and djot files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "djot" },
        callback = function()
            vim.keymap.set("n", "<leader>cp", M.preview, { buffer = true, desc = "Preview in browser" })
            vim.keymap.set("n", "<leader>cr", M.refresh, { buffer = true, desc = "Refresh preview" })
        end,
        group = vim.api.nvim_create_augroup("kyleking_preview", { clear = true }),
    })
end

return M
