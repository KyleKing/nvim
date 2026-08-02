local pack = require("kyleking.pack")
local add, later = pack.add, pack.later

later(function() add("sindrets/diffview.nvim") end)

later(function()
    local diff = require("mini.diff")
    local git = require("mini.git")

    diff.setup()
    git.setup()

    local K = vim.keymap.set

    -- Visual selection as a mini.diff do_hunks() line range
    local function visual_hunk_range()
        local line_start = vim.fn.line("v")
        local line_end = vim.fn.line(".")
        if line_start > line_end then
            line_start, line_end = line_end, line_start
        end
        return { line_start = line_start, line_end = line_end }
    end

    -- Generic VCS command runner with lazy evaluation
    -- Detects jj or git and runs appropriate command
    local function run_vcs_cmd(git_cmd, jj_cmd, git_fn, jj_fn)
        return function()
            local fre = require("find-relative-executable")
            local vcs = fre.get_vcs_root(vim.api.nvim_buf_get_name(0))

            if not vcs then
                vim.notify("Not in a VCS repository", vim.log.levels.WARN)
                return
            end

            if vcs.type == "jj" then
                if jj_fn then
                    jj_fn()
                elseif jj_cmd then
                    vim.cmd("!" .. jj_cmd)
                end
            else
                if git_fn then
                    git_fn()
                elseif git_cmd then
                    vim.cmd("!" .. git_cmd)
                end
            end
        end
    end

    -- mini.diff: hunk operations (work for both git and jj)
    -- See: https://github.com/nvim-mini/mini.diff
    K(
        "n",
        "<leader>gha",
        function() diff.do_hunks(0, "apply", { line_start = vim.fn.line("."), line_end = vim.fn.line(".") }) end,
        { desc = "VCS: apply hunk" }
    )
    K(
        "x",
        "<leader>gha",
        function() diff.do_hunks(0, "apply", visual_hunk_range()) end,
        { desc = "VCS: apply hunk (visual)" }
    )
    K(
        "n",
        "<leader>ghr",
        function() diff.do_hunks(0, "reset", { line_start = vim.fn.line("."), line_end = vim.fn.line(".") }) end,
        { desc = "VCS: reset hunk" }
    )
    K(
        "x",
        "<leader>ghr",
        function() diff.do_hunks(0, "reset", visual_hunk_range()) end,
        { desc = "VCS: reset hunk (visual)" }
    )
    K("n", "]h", function() diff.goto_hunk("next") end, { desc = "Next hunk" })
    K("n", "[h", function() diff.goto_hunk("prev") end, { desc = "Previous hunk" })
    K("n", "]H", function() diff.goto_hunk("last") end, { desc = "Last hunk" })
    K("n", "[H", function() diff.goto_hunk("first") end, { desc = "First hunk" })

    -- Generic VCS commands (git/jj auto-detected)
    K("n", "<leader>gs", run_vcs_cmd("git status", "jj status"), { desc = "VCS: status" })
    K("n", "<leader>gl", run_vcs_cmd("git log", "jj log"), { desc = "VCS: log" })
    K("n", "<leader>gd", run_vcs_cmd(nil, nil, function() git.show_diff_source() end, nil), { desc = "VCS: diff" })

    -- Blame/history (git only via mini.git, jj uses show_at_cursor equivalent if available)
    K("n", "<leader>gb", run_vcs_cmd(nil, nil, function() git.show_at_cursor() end, nil), { desc = "VCS: blame" })
    K(
        { "n", "x" },
        "<leader>gh",
        run_vcs_cmd(nil, nil, function() git.show_range_history() end, nil),
        { desc = "VCS: range history" }
    )

    -- Commit message (git commit / jj describe)
    K("n", "<leader>gc", function()
        local fre = require("find-relative-executable")
        local vcs = fre.get_vcs_root(vim.api.nvim_buf_get_name(0))
        if not vcs then
            vim.notify("Not in a VCS repository", vim.log.levels.WARN)
            return
        end

        local prompt = vcs.type == "jj" and "jj describe message: " or "git commit message: "
        vim.ui.input({ prompt = prompt }, function(msg)
            if msg then
                local cmd = vcs.type == "jj" and ("jj describe -m " .. vim.fn.shellescape(msg))
                    or ("git commit -m " .. vim.fn.shellescape(msg))
                vim.cmd("!" .. cmd)
            end
        end)
    end, { desc = "VCS: commit/describe" })

    -- mini.diff: toggle overlay
    K("n", "<leader>ugd", function() diff.toggle_overlay(0) end, { desc = "Toggle diff overlay" })
end)
