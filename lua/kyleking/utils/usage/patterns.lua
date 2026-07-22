-- Glob matching for usage keys, shared by capture-time filtering and the retroactive
-- rewrite. `*` matches any run of characters: "c*w" covers "ciw", "caw", "c2w".
--
-- Matching is case-sensitive, which is correct for vim keys ("ciw" and "ciW" are
-- different motions) but means word and WORD families need separate patterns.

local M = {}

local compiled = {}

--- Convert a glob to an anchored Lua pattern.
--- Escapes every magic character (including `*`) first, then un-escapes `%*` into
--- `.*`. Doing it in that order avoids escaping the `.` that expanding `*` introduces.
---@param glob string
---@return string
function M.compile(glob)
    local cached = compiled[glob]
    if cached == nil then
        local escaped = glob:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
        cached = "^" .. escaped:gsub("%%%*", ".*") .. "$"
        compiled[glob] = cached
    end
    return cached
end

---@return boolean
function M.matches(glob, value) return value:match(M.compile(glob)) ~= nil end

--- First glob in `globs` matching `value`, or nil.
---@return string|nil
function M.match_any(globs, value)
    for _, glob in ipairs(globs or {}) do
        if M.matches(glob, value) then return glob end
    end
    return nil
end

local function patterns_path(dir) return dir .. "/patterns.json" end

--- Read the denylist and groups from `dir/patterns.json`.
--- A missing or malformed file yields empty lists rather than an error, so a bad hand
--- edit degrades to "no filtering" instead of losing events.
---@return table {denylist, groups}
function M.load(dir)
    local path = patterns_path(dir)
    if vim.fn.filereadable(path) == 0 then return { denylist = {}, groups = {} } end

    local fh = io.open(path, "r")
    if fh == nil then return { denylist = {}, groups = {} } end
    local raw = fh:read("*a")
    fh:close()

    local ok, decoded = pcall(vim.json.decode, raw)
    if not ok or type(decoded) ~= "table" then return { denylist = {}, groups = {} } end
    return {
        denylist = type(decoded.denylist) == "table" and decoded.denylist or {},
        groups = type(decoded.groups) == "table" and decoded.groups or {},
    }
end

function M.save(dir, patterns)
    local fh = assert(io.open(patterns_path(dir), "w"))
    fh:write(vim.json.encode({ denylist = patterns.denylist or {}, groups = patterns.groups or {} }))
    fh:close()
end

--- Label an event key: nil when denied, otherwise the matching group or the key itself.
---@return string|nil
function M.label(patterns, key)
    if M.match_any(patterns.denylist, key) ~= nil then return nil end
    return M.match_any(patterns.groups, key) or key
end

return M
