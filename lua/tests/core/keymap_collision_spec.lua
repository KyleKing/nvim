-- Keymap collision detection tests
local MiniTest = require("mini.test")
local T = MiniTest.new_set()

-- Known acceptable prefix overlaps (where direct binding exists but vim waits for compound bindings)
-- Format: { mode = "n", lhs = "<leader>q", reason = "quickfix operations use <leader>q prefix" }
local ACCEPTABLE_PREFIX_OVERLAPS = {
    -- Example: If <leader>q existed for quit, quickfix would use <leader>qs, <leader>qb, etc.
    -- { mode = "n", lhs = "<leader>q", reason = "quickfix operations (<leader>qs, <leader>qb, etc.)" },
}

-- Get all custom keymaps (exclude default vim mappings and plugin internal mappings)
local function get_custom_keymaps(mode)
    local keymaps = vim.api.nvim_get_keymap(mode)
    local custom = {}

    for _, keymap in ipairs(keymaps) do
        local lhs = keymap.lhs
        -- Filter for custom keymaps (leader-based, control sequences, or function keys)
        -- Exclude vim defaults (single letters, numbers, special keys like j/k/etc that aren't customized)
        if
            lhs:match("^<[Ll]eader>")
            or lhs:match("^<[Cc]%-.>")
            or lhs:match("^<[Aa]%-.>")
            or lhs:match("^<[Ff]%d+>")
            or lhs:match("^<Esc>")
        then
            table.insert(custom, keymap)
        end
    end

    return custom
end

-- Check if lhs1 is a prefix of lhs2
local function is_prefix(lhs1, lhs2)
    if lhs1 == lhs2 then return false end
    return lhs2:sub(1, #lhs1) == lhs1
end

-- Check if overlap is in acceptable list
local function is_acceptable_overlap(mode, lhs)
    for _, overlap in ipairs(ACCEPTABLE_PREFIX_OVERLAPS) do
        if overlap.mode == mode and overlap.lhs == lhs then return true, overlap.reason end
    end
    return false, nil
end

T["collision detection"] = MiniTest.new_set()

T["collision detection"]["no direct collisions in normal mode"] = function()
    local keymaps = get_custom_keymaps("n")
    local seen = {}
    local collisions = {}

    for _, keymap in ipairs(keymaps) do
        local lhs = keymap.lhs
        if seen[lhs] then
            table.insert(collisions, {
                lhs = lhs,
                first = seen[lhs],
                second = keymap,
            })
        else
            seen[lhs] = keymap
        end
    end

    if #collisions > 0 then
        local msg = "Found direct keymap collisions in normal mode:\n"
        for _, collision in ipairs(collisions) do
            msg = msg
                .. string.format(
                    "  %s: '%s' vs '%s'\n",
                    collision.lhs,
                    collision.first.desc or "(no desc)",
                    collision.second.desc or "(no desc)"
                )
        end
        MiniTest.expect.equality(#collisions, 0, msg)
    end
end

T["collision detection"]["no prefix collisions in normal mode"] = function()
    local keymaps = get_custom_keymaps("n")
    local prefix_conflicts = {}

    -- Check each keymap against all others for prefix relationships
    for i = 1, #keymaps do
        for j = i + 1, #keymaps do
            local km1, km2 = keymaps[i], keymaps[j]
            local lhs1, lhs2 = km1.lhs, km2.lhs

            -- Check if one is a prefix of the other
            if is_prefix(lhs1, lhs2) then
                local acceptable = is_acceptable_overlap("n", lhs1)
                if not acceptable then
                    table.insert(prefix_conflicts, {
                        prefix = lhs1,
                        compound = lhs2,
                        prefix_desc = km1.desc or "(no desc)",
                        compound_desc = km2.desc or "(no desc)",
                    })
                end
            elseif is_prefix(lhs2, lhs1) then
                local acceptable = is_acceptable_overlap("n", lhs2)
                if not acceptable then
                    table.insert(prefix_conflicts, {
                        prefix = lhs2,
                        compound = lhs1,
                        prefix_desc = km2.desc or "(no desc)",
                        compound_desc = km1.desc or "(no desc)",
                    })
                end
            end
        end
    end

    if #prefix_conflicts > 0 then
        local msg = "Found prefix keymap collisions in normal mode (causes timeoutlen delay):\n"
        for _, conflict in ipairs(prefix_conflicts) do
            msg = msg
                .. string.format(
                    "  Direct: %s (%s) conflicts with compound: %s (%s)\n",
                    conflict.prefix,
                    conflict.prefix_desc,
                    conflict.compound,
                    conflict.compound_desc
                )
        end
        msg = msg .. "\nPrefix collisions create UX delays: vim waits 'timeoutlen' after direct binding\n"
        msg = msg .. "to see if user wants the compound binding. Either:\n"
        msg = msg .. "  1. Remove the direct binding if compound bindings are more important\n"
        msg = msg .. "  2. Use different prefix for compound bindings\n"
        msg = msg .. "  3. Add to ACCEPTABLE_PREFIX_OVERLAPS if intentional (e.g., mini.clue shows submenu)\n"

        MiniTest.expect.equality(#prefix_conflicts, 0, msg)
    end
end

T["collision detection"]["no direct collisions in visual mode"] = function()
    local keymaps = get_custom_keymaps("x")
    local seen = {}
    local collisions = {}

    for _, keymap in ipairs(keymaps) do
        local lhs = keymap.lhs
        if seen[lhs] then
            table.insert(collisions, {
                lhs = lhs,
                first = seen[lhs],
                second = keymap,
            })
        else
            seen[lhs] = keymap
        end
    end

    if #collisions > 0 then
        local msg = "Found direct keymap collisions in visual mode:\n"
        for _, collision in ipairs(collisions) do
            msg = msg
                .. string.format(
                    "  %s: '%s' vs '%s'\n",
                    collision.lhs,
                    collision.first.desc or "(no desc)",
                    collision.second.desc or "(no desc)"
                )
        end
        MiniTest.expect.equality(#collisions, 0, msg)
    end
end

T["collision detection"]["no direct collisions in insert mode"] = function()
    local keymaps = get_custom_keymaps("i")
    local seen = {}
    local collisions = {}

    for _, keymap in ipairs(keymaps) do
        local lhs = keymap.lhs
        if seen[lhs] then
            table.insert(collisions, {
                lhs = lhs,
                first = seen[lhs],
                second = keymap,
            })
        else
            seen[lhs] = keymap
        end
    end

    if #collisions > 0 then
        local msg = "Found direct keymap collisions in insert mode:\n"
        for _, collision in ipairs(collisions) do
            msg = msg
                .. string.format(
                    "  %s: '%s' vs '%s'\n",
                    collision.lhs,
                    collision.first.desc or "(no desc)",
                    collision.second.desc or "(no desc)"
                )
        end
        MiniTest.expect.equality(#collisions, 0, msg)
    end
end

-- Run tests if executed directly
if vim.fn.expand("%") == vim.fn.expand("<sfile>") then MiniTest.run() end

return T
