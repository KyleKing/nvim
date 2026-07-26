local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            vim.cmd("tabonly")
            vim.cmd("%bwipeout!")
        end,
    },
})

local link_open = require("kyleking.utils.link_open")

-- A Lua pattern quantifier (`*`, `+`, `-`) only ever applies to a single
-- character class, never to a parenthesized group, so the nested/overlapping
-- quantifiers behind classic exponential ReDoS (e.g. `(a+)+b`) can't be
-- written here. What several of this config's patterns (link_open's
-- `plugin`/`ssh_git`/`md_link`, editing-support's hipatterns highlighters) do
-- have is multiple unanchored variable-length segments run back to back,
-- which can still backtrack super-linearly on adversarial input. These cases
-- drive the real per-keystroke (`link_open.open`) and per-redraw
-- (mini.hipatterns) entry points with input sized to expose that shape, and
-- assert they still finish inside a generous budget.
local BUDGET_SECONDS = 1.0
local RUN = 50000

local function timed(fn)
    local start = vim.loop.hrtime()
    fn()
    return (vim.loop.hrtime() - start) / 1e9
end

T["redos"] = MiniTest.new_set()

T["redos"]["open() stays fast when a ssh_git-shaped line never closes"] = function()
    vim.cmd("enew")
    -- Matches "git@" plus the first character class but has no ":" to close
    -- it, forcing that "+" to backtrack across the whole run before failing.
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "git@" .. string.rep("a", RUN) .. "X" })

    local original_notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function() end
    local elapsed = timed(link_open.open)
    vim.notify = original_notify

    MiniTest.expect.equality(elapsed < BUDGET_SECONDS, true, string.format("took %.3fs", elapsed))
end

T["redos"]["open() stays fast when a plugin-shaped line never contains nvim"] = function()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(
        0,
        0,
        -1,
        false,
        { string.rep("a", RUN) .. "/" .. string.rep("b", RUN) .. "/" .. string.rep("c", RUN) }
    )

    local original_notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function() end
    local elapsed = timed(link_open.open)
    vim.notify = original_notify

    MiniTest.expect.equality(elapsed < BUDGET_SECONDS, true, string.format("took %.3fs", elapsed))
end

T["redos"]["open() stays fast when a md_link-shaped line never closes"] = function()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "[" .. string.rep("a", RUN) })

    local original_notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function() end
    local elapsed = timed(link_open.open)
    vim.notify = original_notify

    MiniTest.expect.equality(elapsed < BUDGET_SECONDS, true, string.format("took %.3fs", elapsed))
end

T["redos"]["open() stays fast when a real link sits after a long filler run"] = function()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep(" ", RUN) .. "git@github.com:KyleKing/simple-crypt.git" })

    local opened = nil
    local original_open = vim.ui.open
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.open = function(target)
        opened = target
        return true
    end
    local elapsed = timed(link_open.open)
    vim.ui.open = original_open

    MiniTest.expect.equality(opened, "https://github.com/KyleKing/simple-crypt")
    MiniTest.expect.equality(elapsed < BUDGET_SECONDS, true, string.format("took %.3fs", elapsed))
end

T["redos"]["mini.hipatterns highlighting stays fast on an adversarial long line"] = function()
    vim.cmd("enew")
    local hipatterns = require("mini.hipatterns")
    -- Stresses the plugin_ref and md_link highlighters (long non-matching
    -- runs before a real plugin ref at the very end forces an unanchored
    -- search to scan the whole line first).
    local line = "[" .. string.rep("a", RUN) .. string.rep("b", RUN) .. "/" .. "foo-nvim"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })

    local elapsed = timed(function()
        hipatterns.enable(0)
        vim.wait(5000, function() return #hipatterns.get_matches(0) > 0 end, 10)
    end)
    hipatterns.disable(0)

    MiniTest.expect.equality(elapsed < BUDGET_SECONDS * 5, true, string.format("took %.3fs", elapsed))
end

if ... == nil then MiniTest.run() end

return T
