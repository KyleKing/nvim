local MiniTest = require("mini.test")
local helpers = require("tests.helpers")
local motion = require("kyleking.utils.usage.motion")

local handles = {}

--- Collect emitted sequences from a fresh assembler.
local function collector(opts)
    local seen = {}
    local assembler = motion.new_assembler(vim.tbl_extend("force", {
        on_sequence = function(seq) seen[#seen + 1] = seq end,
    }, opts or {}))
    return assembler, seen
end

--- Feed a list of {key, mode} pairs.
local function feed_all(assembler, keys)
    for _, pair in ipairs(keys) do
        assembler.feed(pair[1], pair[2])
    end
end

local T = MiniTest.new_set({
    hooks = {
        post_case = function()
            for _, handle in ipairs(handles) do
                pcall(handle.stop)
            end
            handles = {}
        end,
    },
})

T["assembler"] = MiniTest.new_set()

T["assembler"]["assembles an operator and text object into one sequence"] = function()
    local assembler, seen = collector()
    -- Modes are what vim.on_key observes: the mode *before* each key is processed, so
    -- "c" is seen in normal mode and the rest in operator-pending.
    feed_all(assembler, { { "c", "n" }, { "i", "no" }, { "w", "no" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "ciw" }, "one semantic unit, not three keys")
end

T["assembler"]["emits nothing past the length cap"] = function()
    local assembler, seen = collector({ max_seq_len = 3 })
    feed_all(assembler, { { "d", "n" }, { "i", "no" }, { "2", "no" }, { "a", "no" }, { "w", "no" } })
    assembler.flush()

    MiniTest.expect.equality(seen, {}, "an over-long buffer is discarded, never truncated")
    MiniTest.expect.equality(assembler.pending(), "")
end

T["assembler"]["recovers at the next rest state after an overflow"] = function()
    local assembler, seen = collector({ max_seq_len = 2 })
    feed_all(assembler, { { "d", "n" }, { "i", "no" }, { "a", "no" }, { "w", "no" } })
    feed_all(assembler, { { "x", "n" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "x" }, "the next sequence must not inherit the overflow")
end

T["assembler"]["ignores keys typed outside normal and visual"] = function()
    local assembler, seen = collector()
    feed_all(assembler, { { "h", "i" }, { "e", "i" }, { "y", "R" }, { "w", "c" }, { "q", "t" } })
    assembler.flush()

    MiniTest.expect.equality(seen, {})
    MiniTest.expect.equality(assembler.pending(), "")
end

T["assembler"]["flushes a pending sequence when the mode leaves normal"] = function()
    local assembler, seen = collector()
    feed_all(assembler, { { "c", "n" }, { "i", "no" }, { "w", "no" } })
    -- Typing the replacement text is the first observation of insert mode.
    feed_all(assembler, { { "X", "i" } })

    MiniTest.expect.equality(seen, { "ciw" }, "leaving normal mode resolves the operation")
end

T["assembler"]["starts a new sequence on returning to rest"] = function()
    local assembler, seen = collector()
    feed_all(assembler, { { "d", "n" }, { "d", "no" } })
    feed_all(assembler, { { "j", "n" } })

    MiniTest.expect.equality(seen, { "dd" })
    MiniTest.expect.equality(assembler.pending(), "j", "the key at the boundary opens the next sequence")
end

T["assembler"]["splits repeated navigation into separate sequences"] = function()
    local assembler, seen = collector()
    feed_all(assembler, { { "j", "n" }, { "j", "n" }, { "k", "n" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "j", "j", "k" }, "the denylist has to see one key per row")
end

T["assembler"]["flush emits a pending sequence and nothing when empty"] = function()
    local assembler, seen = collector()
    assembler.flush()
    MiniTest.expect.equality(seen, {}, "an empty buffer must not emit a blank sequence")

    feed_all(assembler, { { "d", "n" }, { "d", "no" } })
    assembler.flush()
    assembler.flush()
    MiniTest.expect.equality(seen, { "dd" }, "flushing twice must not emit twice")
end

T["assembler"]["keeps magic characters literal"] = function()
    local assembler, seen = collector()
    feed_all(assembler, { { "d", "n" }, { "i", "no" }, { "(", "no" } })
    assembler.flush()
    feed_all(assembler, { { "c", "n" }, { "i", "no" }, { '"', "no" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "di(", 'ci"' }, "sequences are plain strings, not patterns")
end

T["assembler"]["keeps a char-argument motion together"] = function()
    local assembler, seen = collector()
    -- f and its argument both land in normal mode: nvim changes no mode while waiting.
    feed_all(assembler, { { "f", "n" }, { ";", "n" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "f;" })
end

T["assembler"]["keeps a g-prefixed operator together"] = function()
    local assembler, seen = collector()
    feed_all(assembler, { { "g", "n" }, { "U", "n" }, { "i", "no" }, { "w", "no" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "gUiw" })
end

T["assembler"]["keeps a visual text object together"] = function()
    local assembler, seen = collector()
    -- Visual mode is not a rest state: "viw" never leaves it, so it would otherwise
    -- split into three rows.
    feed_all(assembler, { { "v", "n" }, { "i", "v" }, { "w", "v" }, { "d", "v" } })
    feed_all(assembler, { { "j", "n" } })

    MiniTest.expect.equality(seen, { "viwd" })
end

T["assembler"]["breaks a count prefix off as its own sequence"] = function()
    local assembler, seen = collector()
    feed_all(assembler, { { "3", "n" }, { "c", "n" }, { "i", "no" }, { "w", "no" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "3", "ciw" }, "documented misattribution: the count is dropped")
end

T["assembler"]["honors a custom rest predicate"] = function()
    local assembler, seen = collector({ is_rest = function() return false end })
    feed_all(assembler, { { "j", "n" }, { "k", "n" } })
    assembler.flush()

    MiniTest.expect.equality(seen, { "jk" }, "nothing rests, so everything accumulates")
end

T["attach"] = MiniTest.new_set()

local function attach(opts)
    local seen = {}
    local handle = motion.attach(vim.tbl_extend("force", {
        idle_ms = 60000,
        on_sequence = function(seq) seen[#seen + 1] = seq end,
    }, opts or {}))
    handles[#handles + 1] = handle
    return handle, seen
end

T["attach"]["detaches its on_key handler and augroup on stop"] = function()
    local before = vim.on_key()
    local handle = attach()

    MiniTest.expect.equality(vim.on_key(), before + 1, "attach registers exactly one listener")
    MiniTest.expect.equality(#vim.api.nvim_get_autocmds({ group = "kyleking_usage_motion" }) > 0, true)

    handle.stop()

    MiniTest.expect.equality(vim.on_key(), before, "stop must leave no listener behind")
    local ok = pcall(vim.api.nvim_get_autocmds, { group = "kyleking_usage_motion" })
    MiniTest.expect.equality(ok, false, "the augroup is gone, so querying it errors")
    MiniTest.expect.equality(pcall(handle.stop), true, "stopping twice must not error")
end

--- Other specs can leave the editor in insert mode with keys still queued, which would
--- otherwise make the keystroke tests below depend on run order.
local function normalize()
    vim.cmd("stopinsert")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)
end

T["attach"]["assembles real keystrokes"] = function()
    local bufnr = helpers.create_test_buffer({ "hello world foo" }, "text")
    normalize()
    local handle, seen = attach()

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("ciwbye<Esc>", true, false, true), "xt", false)
    vim.api.nvim_feedkeys("dd", "xt", false)
    -- Explicit rather than waiting on the idle tick, and so the case does not depend on
    -- ModeChanged, which the headless test runner does not always deliver.
    handle.assembler.flush()

    MiniTest.expect.equality(seen, { "ciw", "dd" }, "insert-mode text must not leak into the log")
    helpers.delete_buffer(bufnr)
end

T["attach"]["skips keys replayed by a mapping"] = function()
    local bufnr = helpers.create_test_buffer({ "hello world" }, "text")
    normalize()
    local handle, seen = attach()

    -- No "t" flag: the keys arrive untyped, the same as a mapping's rhs replaying keys.
    vim.api.nvim_feedkeys("dd", "x", false)
    handle.assembler.flush()

    MiniTest.expect.equality(seen, {}, "a keymap is already counted by the map hook")
    helpers.delete_buffer(bufnr)
end

if MiniTest.current.all_cases == nil then MiniTest.run() end

return T
