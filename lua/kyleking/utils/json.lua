-- Based on: https://github.com/windwp/nvim-projectconfig/blob/e22e4c12885d1eab1e5e999ab924260fa0bfa1c3/lua/nvim-projectconfig.lua#L104C1-L130C9

local M = {}

---@return table json JSON data
function M.load_json()
    local json_decode = vim.json and vim.json.decode or vim.fn.json_decode
    local jsonfile = M.get_config_by_ext("json")
    if vim.fn.filereadable(jsonfile) == 1 then
        local f = io.open(jsonfile, "r")
        if f then
            local data = f:read("*a")
            f:close()
            if data then
                local check, jdata = pcall(json_decode, data)
                if check and jdata then return jdata end
            end
        end
    end
    return {}
end

---@param json_table table JSON data
function M.save_json(json_table)
    local jsonfile = M.get_config_by_ext("json")
    local json_encode = vim.json and vim.json.encode or vim.fn.json_encode
    local fp = assert(io.open(jsonfile, "w"), "No JSON file")
    fp:write(json_encode(json_table))
    fp:close()
end

return M
