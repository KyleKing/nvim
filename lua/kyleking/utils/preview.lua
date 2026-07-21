-- Preview markdown and djot files using CLI tools

local M = {}

-- Browser auto-refresh interval while watching (ms). No local server, so this
-- polls via <meta refresh>; scroll position is preserved across reloads.
M.refresh_ms = 1000

local watch = { augroup = nil, timer = nil, path = nil, mtimes = {} }

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

-- Wrap a body fragment in a themed HTML document. When refresh_ms is set, inject a
-- meta-refresh poller plus scroll restoration so watched previews reload in place.
local function wrap_html(body, filetype, refresh_ms)
    local refresh = ""
    if refresh_ms and refresh_ms > 0 then
        refresh = string.format(
            [[
    <meta http-equiv="refresh" content="%s">
    <script>
        addEventListener("beforeunload", function () { sessionStorage.setItem("y", String(scrollY)); });
        addEventListener("load", function () {
            var y = sessionStorage.getItem("y");
            if (y !== null) scrollTo(0, parseInt(y, 10));
        });
    </script>]],
            refresh_ms / 1000
        )
    end

    return table.concat({
        [[<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Preview - ]],
        filetype,
        [[</title>]],
        refresh,
        [[
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

-- Local image paths referenced in the buffer, resolved against the source dir.
-- Used to detect when an embedded image changes on disk.
local function referenced_images(bufnr, dir)
    local images = {}
    for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        for path in line:gmatch("!%[.-%]%((.-)%)") do
            images[#images + 1] = path
        end
        for path in line:gmatch("src%s*=%s*[\"'](.-)[\"']") do
            images[#images + 1] = path
        end
    end

    local resolved = {}
    for _, path in ipairs(images) do
        path = path:gsub("%s.*$", "")
        if not path:match("^%a[%w+.-]*://") and not path:match("^data:") and path ~= "" then
            if not path:match("^/") then path = dir .. "/" .. path end
            resolved[#resolved + 1] = path
        end
    end
    return resolved
end

-- Preview current buffer once
function M.preview()
    local ft = vim.bo.filetype
    local filepath = vim.api.nvim_buf_get_name(0)

    if filepath == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
    end

    if vim.bo.modified then vim.cmd("write") end

    local html, err = generate_html(filepath, ft)
    if not html or html == "" then
        vim.notify(err or "Failed to generate HTML", vim.log.levels.ERROR)
        return
    end

    local path = vim.fn.tempname() .. ".html"
    if write_atomic(path, wrap_html(html, ft)) then open_url(path) end
end

-- Stop watching and tear down the timer and autocmds
function M.watch_stop()
    if watch.timer then
        watch.timer:stop()
        watch.timer:close()
        watch.timer = nil
    end
    if watch.augroup then
        pcall(vim.api.nvim_del_augroup_by_id, watch.augroup)
        watch.augroup = nil
    end
end

-- Preview current buffer and keep it refreshed on save and on image changes
function M.watch()
    local ft = vim.bo.filetype
    local filepath = vim.api.nvim_buf_get_name(0)

    if filepath == "" then
        vim.notify("Buffer has no file path", vim.log.levels.ERROR)
        return
    end
    if ft ~= "markdown" and ft ~= "djot" then
        vim.notify("Preview not supported for filetype: " .. ft, vim.log.levels.ERROR)
        return
    end
    if vim.bo.modified then vim.cmd("write") end

    M.watch_stop()

    local bufnr = vim.api.nvim_get_current_buf()
    local dir = vim.fn.fnamemodify(filepath, ":h")
    local path = vim.fn.stdpath("cache") .. "/kyleking-preview.html"
    watch.path = path

    local function regen()
        local html, err = generate_html(filepath, ft)
        if not html or html == "" then
            vim.notify(err or "Failed to generate HTML", vim.log.levels.ERROR)
            return
        end
        write_atomic(path, wrap_html(html, ft, M.refresh_ms))
    end

    local function snapshot()
        local mtimes = {}
        local files = referenced_images(bufnr, dir)
        files[#files + 1] = filepath
        for _, file in ipairs(files) do
            local stat = vim.uv.fs_stat(file)
            if stat then mtimes[file] = stat.mtime.sec .. "." .. stat.mtime.nsec end
        end
        return mtimes
    end

    regen()
    open_url(path)

    watch.mtimes = snapshot()
    watch.augroup = vim.api.nvim_create_augroup("kyleking_preview_watch", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", { group = watch.augroup, buffer = bufnr, callback = regen })
    vim.api.nvim_create_autocmd("BufUnload", { group = watch.augroup, buffer = bufnr, callback = M.watch_stop })

    watch.timer = vim.uv.new_timer()
    watch.timer:start(
        M.refresh_ms,
        M.refresh_ms,
        vim.schedule_wrap(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                M.watch_stop()
                return
            end
            local mtimes = snapshot()
            local changed = false
            for file, mtime in pairs(mtimes) do
                if watch.mtimes[file] ~= mtime then
                    changed = true
                    break
                end
            end
            if changed then
                watch.mtimes = mtimes
                regen()
            end
        end)
    )

    vim.notify(
        string.format("Preview watching (refresh %dms). :PreviewWatchStop to end.", M.refresh_ms),
        vim.log.levels.INFO
    )
end

-- Setup keymaps and commands
function M.setup()
    vim.api.nvim_create_user_command("Preview", M.preview, { desc = "Preview markdown/djot in browser" })
    vim.api.nvim_create_user_command("PreviewWatch", M.watch, { desc = "Preview and auto-refresh on change" })
    vim.api.nvim_create_user_command("PreviewWatchStop", M.watch_stop, { desc = "Stop preview auto-refresh" })

    -- Add keymap for markdown and djot files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "djot" },
        callback = function()
            vim.keymap.set("n", "<leader>cp", M.preview, { buffer = true, desc = "Preview in browser" })
            vim.keymap.set("n", "<leader>cP", M.watch, { buffer = true, desc = "Preview (watch)" })
        end,
        group = vim.api.nvim_create_augroup("kyleking_preview", { clear = true }),
    })
end

return M
