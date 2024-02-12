local M = {}

-- From: https://github.com/AstroNvim/AstroNvim/blob/67d6925bac883b7828e9783a2151a30b14d5593f/lua/astronvim/icons/nerd_font.lua
M.icons = {
    ActiveLSP = "",
    ActiveTS = "",
    ArrowLeft = "",
    ArrowRight = "",
    Bookmarks = "",
    BufferClose = "󰅖",
    DefaultFile = "󰈙",
    Diagnostic = "󰒡",
    DiagnosticError = "",
    DiagnosticHint = "󰌵",
    DiagnosticInfo = "󰋼",
    DiagnosticWarn = "",
    Ellipsis = "…",
    FileNew = "",
    FileModified = "",
    FileReadOnly = "",
    FoldClosed = "",
    FoldOpened = "",
    FoldSeparator = " ",
    FolderClosed = "",
    FolderEmpty = "",
    FolderOpen = "",
    Git = "󰊢",
    GitAdd = "",
    GitBranch = "",
    GitChange = "",
    GitConflict = "",
    GitDelete = "",
    GitIgnored = "◌",
    GitRenamed = "➜",
    GitSign = "▎",
    GitStaged = "✓",
    GitUnstaged = "✗",
    GitUntracked = "★",
    LSPLoading1 = "",
    LSPLoading2 = "󰀚",
    LSPLoading3 = "",
    MacroRecording = "",
    Package = "󰏖",
    Paste = "󰅌",
    Refresh = "",
    Search = "",
    Selected = "❯",
    Session = "󱂬",
    Sort = "󰒺",
    Spellcheck = "󰓆",
    Tab = "󰓩",
    TabClose = "󰅙",
    Terminal = "",
    Window = "",
    WordFile = "󰈭",
}

--- Get an icon from the AstroNvim internal icons if it is available and return it
---@param kind string The kind of icon in astroui.icons to retrieve
---@param rpad? integer Padding to add to the right of the icon
---@param no_fallback? boolean Whether or not to disable fallback to text icon
---@return string icon
function M.get_icon(kind, rpad, no_fallback)
    if not vim.g.icons_enabled and no_fallback then return "" end
    local icon = assert(M.icons[kind], "No icon '" .. kind .. "'")
    return icon .. (" "):rep(rpad or 0)
end

return M
