local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("RRethy/vim-illuminate")
    require("illuminate").configure({
        delay = 200,
        min_count_to_highlight = 2,
        large_file_overrides = { providers = { "lsp" } },
    })

    local K = vim.keymap.set
    K("n", "]r", function() require("illuminate")["goto_next_reference"](false) end, { desc = "Next reference" })
    K("n", "[r", function() require("illuminate")["goto_prev_reference"](false) end, { desc = "Previous reference" })
    K("n", "<leader>ur", function() require("illuminate").toggle() end, { desc = "Toggle reference highlighting" })
    K(
        "n",
        "<leader>uR",
        function() require("illuminate").toggle_buf() end,
        { desc = "Toggle reference highlighting (buffer)" }
    )
end)

-- Check for temp session BEFORE scheduling later()
local utils = require("kyleking.utils")
local is_temp_session = utils.detect_temp_session()

if not is_temp_session then
    later(function()
        local MiniStatusline = require("mini.statusline")

        MiniStatusline.setup({
            content = {
                active = function()
                    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
                    local git = MiniStatusline.section_git({ trunc_width = 75 })
                    local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })

                    -- Custom filename section with dynamic width calculation
                    local filename_section = function()
                        local path = vim.fn.expand("%:p")
                        if path == "" then return "[No Name]" end

                        local filename = vim.fn.expand("%:t")
                        local dir = vim.fn.expand("%:h")

                        -- Calculate available space
                        local constants = require("kyleking.utils.constants")
                        local mode_width = vim.fn.strdisplaywidth(mode)
                        local git_width = vim.fn.strdisplaywidth(git)
                        local diag_width = vim.fn.strdisplaywidth(diagnostics)
                        local available = vim.o.columns
                            - (mode_width + git_width + diag_width + constants.CHAR_LIMIT.PATH_PADDING)

                        -- Max width for path (reserve space for filename)
                        local max_path =
                            math.max(constants.CHAR_LIMIT.FILENAME_MIN, available - constants.CHAR_LIMIT.FILENAME_MIN)
                        local full_path = dir .. "/" .. filename

                        -- Truncate from left if too long
                        if vim.fn.strdisplaywidth(full_path) > max_path then
                            local dir_space = max_path
                                - vim.fn.strdisplaywidth(filename)
                                - constants.CHAR_LIMIT.TRUNCATION_INDICATOR
                            if dir_space > 0 then
                                local truncated_dir = string.sub(dir, -dir_space)
                                return ".../" .. truncated_dir .. "/" .. filename
                            else
                                return ".../" .. filename
                            end
                        end

                        -- File status indicators
                        local modified = vim.bo.modified and " [+]" or ""
                        local readonly = vim.bo.readonly and " []" or ""

                        return full_path .. modified .. readonly
                    end

                    local filename = filename_section()
                    local location = MiniStatusline.section_location({ trunc_width = 75 })

                    return MiniStatusline.combine_groups({
                        { hl = mode_hl, strings = { mode } },
                        { hl = "MiniStatuslineDevinfo", strings = { git, diagnostics } },
                        "%<", -- Mark truncation point
                        { hl = "MiniStatuslineFilename", strings = { filename } },
                        "%=", -- End left alignment
                        { hl = "MiniStatuslineFileinfo", strings = { location } },
                    })
                end,
            },
            use_icons = true,
            set_vim_settings = true,
        })

        -- Apply nightfly-inspired theme colors
        local colors = require("kyleking.theme").get_colors()

        -- Mode colors (similar to lualine nightfly theme)
        vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = colors.bg0, bg = colors.fg1, bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = colors.bg0, bg = colors.green, bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = colors.bg0, bg = colors.orange, bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = colors.bg0, bg = "#e06c75", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = colors.bg0, bg = "#61afef", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeOther", { fg = colors.bg0, bg = colors.fg3, bold = true })

        -- Other sections
        vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { fg = colors.fg2, bg = colors.bg2 })
        vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { fg = colors.fg1, bg = colors.bg1 })
        vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { fg = colors.fg2, bg = colors.bg2 })
        vim.api.nvim_set_hl(0, "MiniStatuslineInactive", { fg = colors.fg3, bg = colors.bg1 })
    end)

    later(function()
        local MiniTabline = require("mini.tabline")

        MiniTabline.setup({
            show_icons = true,
            set_vim_settings = true,
            tabpage_section = "right",
        })

        -- Apply nightfly-inspired theme colors
        local colors = require("kyleking.theme").get_colors()

        -- Tabline colors matching statusline theme
        vim.api.nvim_set_hl(0, "MiniTablineCurrent", { fg = colors.fg1, bg = colors.bg2, bold = true })
        vim.api.nvim_set_hl(0, "MiniTablineVisible", { fg = colors.fg2, bg = colors.bg1 })
        vim.api.nvim_set_hl(0, "MiniTablineHidden", { fg = colors.fg3, bg = colors.bg0 })
        vim.api.nvim_set_hl(0, "MiniTablineModifiedCurrent", { fg = colors.orange, bg = colors.bg2, bold = true })
        vim.api.nvim_set_hl(0, "MiniTablineModifiedVisible", { fg = colors.orange, bg = colors.bg1 })
        vim.api.nvim_set_hl(0, "MiniTablineModifiedHidden", { fg = colors.orange, bg = colors.bg0 })
        vim.api.nvim_set_hl(0, "MiniTablineFill", { bg = colors.bg0 })
        vim.api.nvim_set_hl(0, "MiniTablineTabpagesection", { fg = colors.fg1, bg = colors.bg2, bold = true })
    end)
end

later(function()
    add("fmbarina/multicolumn.nvim")

    require("multicolumn").setup({
        use_default_set = true,
        sets = {
            lua = {
                full_column = true,
                rulers = { 120 },
            },
            python = function()
                -- PLANNED: consider reading line length from pyproject.toml and caching result
                local rulers = function() return { 80, 120 } end
                return {
                    full_column = true,
                    rulers = rulers(),
                }
            end,
        },
    })
end)
