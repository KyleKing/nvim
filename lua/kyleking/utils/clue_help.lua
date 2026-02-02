-- Helper to show mini.clue for specific triggers
-- Usage: require("kyleking.utils.clue_help").show("<C-w>")

local M = {}

---Show mini.clue for a specific trigger
---@param trigger string The trigger key sequence (e.g., "<C-w>", "[", "g")
function M.show(trigger)
    local keys = vim.api.nvim_replace_termcodes(trigger, true, false, true)
    vim.api.nvim_feedkeys(keys, "n", false)
end

---Show a menu to select which clue trigger to view
function M.show_menu()
    local triggers = {
        { name = "Window commands (<C-w>)", keys = "<C-w>" },
        { name = "Bracket navigation ([)", keys = "[" },
        { name = "Bracket navigation (])", keys = "]" },
        { name = "g commands", keys = "g" },
        { name = "z commands", keys = "z" },
        { name = "Marks (')", keys = "'" },
        { name = "Marks (`)", keys = "`" },
        { name = 'Registers (")', keys = '"' },
        { name = "Leader commands", keys = "<Leader>" },
    }

    vim.ui.select(triggers, {
        prompt = "Show clues for:",
        format_item = function(item) return item.name end,
    }, function(choice)
        if choice then M.show(choice.keys) end
    end)
end

return M
