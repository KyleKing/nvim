---@class SortOpts
---@field mode? "auto"|"treesitter"|"indent"|"line" Sort mode (default: "auto")
---@field case_sensitive? boolean Case-sensitive sorting (default: false)
---@field numeric? boolean Natural sort for numbers (default: false)
---@field reverse? boolean Reverse sort order (default: false)

local M = {}

---Extract sort key from text (first non-whitespace token)
---@param text string
---@param opts SortOpts
---@return string
local function extract_sort_key(text, opts)
    -- Extract first meaningful token (skip whitespace and common prefixes)
    local key = text:match("^%s*[\"'`]?([^\"'`%s:,]+)") or text
    if not opts.case_sensitive then key = key:lower() end
    return key
end

---Compare function for sorting with numeric support
---@param a string
---@param b string
---@param opts SortOpts
---@return boolean
local function compare_keys(a, b, opts)
    if opts.numeric then
        -- Extract numbers from the strings for natural sort
        local num_a = tonumber(a:match("%d+"))
        local num_b = tonumber(b:match("%d+"))
        if num_a and num_b and num_a ~= num_b then
            if opts.reverse then
                return num_a > num_b
            else
                return num_a < num_b
            end
        end
    end
    if opts.reverse then
        return a > b
    else
        return a < b
    end
end

---Find sortable container nodes using treesitter
---@param bufnr number
---@param start_row number 0-indexed
---@param end_row number 0-indexed
---@return table[] List of {node, type, children}
local function find_sortable_containers(bufnr, start_row, end_row)
    local parser = vim.treesitter.get_parser(bufnr)
    if not parser then return {} end

    local containers = {}
    local query_strings = {
        lua = [[
            (table_constructor) @container
        ]],
        python = [[
            (list) @container
            (dictionary) @container
            (argument_list) @container
        ]],
        json = [[
            (array) @container
            (object) @container
        ]],
        yaml = [[
            (block_mapping) @container
            (flow_sequence) @container
        ]],
        javascript = [[
            (array) @container
            (object) @container
            (arguments) @container
        ]],
        typescript = [[
            (array) @container
            (object) @container
            (arguments) @container
        ]],
        go = [[
            (literal_value) @container
        ]],
    }

    local lang = parser:lang()
    local query_string = query_strings[lang]
    if not query_string then return {} end

    local ok, query = pcall(vim.treesitter.query.parse, lang, query_string)
    if not ok then return {} end

    parser:parse()
    local tree = parser:trees()[1]
    if not tree then return {} end

    for id, node in query:iter_captures(tree:root(), bufnr, start_row, end_row + 1) do
        local capture = query.captures[id]
        if capture == "container" then
            local node_start_row, _, node_end_row = node:range()

            -- Check if node is within selection range
            if node_start_row >= start_row and node_end_row <= end_row + 1 then
                -- Get child nodes that represent items to sort
                local children = {}
                for child in node:iter_children() do
                    local child_type = child:type()
                    -- Skip delimiters and whitespace
                    if
                        child_type ~= ","
                        and child_type ~= "{"
                        and child_type ~= "}"
                        and child_type ~= "["
                        and child_type ~= "]"
                        and child_type ~= "("
                        and child_type ~= ")"
                        and not child_type:match("^%s*$")
                    then
                        table.insert(children, child)
                    end
                end

                if #children > 1 then
                    table.insert(containers, {
                        node = node,
                        type = node:type(),
                        children = children,
                    })
                end
            end
        end
    end

    return containers
end

---Sort using line-by-line mode (like :sort)
---@param bufnr number
---@param start_row number 0-indexed
---@param end_row number 0-indexed
---@param opts SortOpts
---@return boolean success
local function sort_by_lines(bufnr, start_row, end_row, opts)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    if #lines <= 1 then return false end

    local items = {}
    for _, line in ipairs(lines) do
        local key = extract_sort_key(line, opts)
        table.insert(items, { text = line, key = key })
    end

    table.sort(items, function(a, b) return compare_keys(a.key, b.key, opts) end)

    local sorted_lines = {}
    for _, item in ipairs(items) do
        table.insert(sorted_lines, item.text)
    end

    -- Check if changed
    local changed = false
    for i = 1, #lines do
        if lines[i] ~= sorted_lines[i] then
            changed = true
            break
        end
    end

    if not changed then return false end

    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, sorted_lines)
    return true
end

---Sort a treesitter container node
---@param bufnr number
---@param container table {node, type, children}
---@param opts SortOpts
---@return boolean success
local function sort_container(bufnr, container, opts)
    if #container.children < 2 then return false end

    -- Get the rows covered by the container's children
    local first_child = container.children[1]
    local last_child = container.children[#container.children]

    local first_row = first_child:range()
    local last_row = (select(3, last_child:range()))

    -- Fall back to line-based sorting for the child rows
    return sort_by_lines(bufnr, first_row, last_row, opts)
end

---Sort using indentation-based grouping
---@param bufnr number
---@param start_row number 0-indexed
---@param end_row number 0-indexed
---@param opts SortOpts
---@return boolean success
local function sort_by_indentation(bufnr, start_row, end_row, opts)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    if #lines <= 1 then return false end

    -- Find minimum indentation level (excluding blank lines)
    local min_indent = math.huge
    for _, line in ipairs(lines) do
        if not line:match("^%s*$") then
            local indent_len = #line:match("^%s*")
            min_indent = math.min(min_indent, indent_len)
        end
    end

    if min_indent == math.huge then return false end

    -- Group lines by indentation blocks
    local groups = {}
    local current_group = nil

    for _, line in ipairs(lines) do
        local is_blank = line:match("^%s*$") ~= nil

        if is_blank then
            -- Blank lines belong to previous group if one exists
            if current_group then table.insert(current_group.lines, line) end
        else
            local indent_len = #line:match("^%s*")

            if current_group and indent_len > min_indent then
                -- Continuation line (indented more than base)
                table.insert(current_group.lines, line)
            else
                -- Start new group (either at base indentation or less indented than base)
                if current_group then table.insert(groups, current_group) end
                current_group = {
                    lines = { line },
                    key = extract_sort_key(line, opts),
                }
            end
        end
    end

    if current_group then table.insert(groups, current_group) end

    if #groups <= 1 then return false end

    -- Sort groups
    local sorted_groups = vim.deepcopy(groups)
    table.sort(sorted_groups, function(a, b) return compare_keys(a.key, b.key, opts) end)

    -- Check if order changed
    local changed = false
    for i = 1, #groups do
        if groups[i].key ~= sorted_groups[i].key then
            changed = true
            break
        end
    end

    if not changed then return false end

    -- Build sorted lines
    local sorted_lines = {}
    for _, group in ipairs(sorted_groups) do
        for _, line in ipairs(group.lines) do
            table.insert(sorted_lines, line)
        end
    end

    -- Replace lines
    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, sorted_lines)

    return true
end

---Sort a range in a buffer
---@param bufnr number
---@param start_row number 0-indexed
---@param end_row number 0-indexed
---@param opts SortOpts
---@return boolean success
function M.sort_range(bufnr, start_row, end_row, opts)
    opts = opts or {}
    opts.mode = opts.mode or "auto"

    if opts.mode == "auto" then
        -- Try treesitter first
        local containers = find_sortable_containers(bufnr, start_row, end_row)
        if #containers > 0 then
            local success = false
            for _, container in ipairs(containers) do
                if sort_container(bufnr, container, opts) then success = true end
            end
            if success then return true end
        end

        -- Fall back to indentation-based
        if sort_by_indentation(bufnr, start_row, end_row, opts) then return true end

        -- Fall back to line-by-line
        return sort_by_lines(bufnr, start_row, end_row, opts)
    elseif opts.mode == "treesitter" then
        local containers = find_sortable_containers(bufnr, start_row, end_row)
        if #containers == 0 then
            vim.notify("No sortable containers found", vim.log.levels.WARN)
            return false
        end
        local success = false
        for _, container in ipairs(containers) do
            if sort_container(bufnr, container, opts) then success = true end
        end
        return success
    elseif opts.mode == "indent" then
        return sort_by_indentation(bufnr, start_row, end_row, opts)
    elseif opts.mode == "line" then
        return sort_by_lines(bufnr, start_row, end_row, opts)
    else
        error("Invalid sort mode: " .. opts.mode)
    end
end

---Sort visual selection
---@param opts? SortOpts
function M.sort_visual(opts)
    opts = opts or {}
    local bufnr = vim.api.nvim_get_current_buf()

    -- Get visual selection range
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_row = start_pos[2] - 1 -- Convert to 0-indexed
    local end_row = end_pos[2] - 1

    M.sort_range(bufnr, start_row, end_row, opts)
end

---Check if current file should be excluded from sorting
---@param bufnr number
---@return boolean should_exclude
---@return string? reason
local function should_exclude_file(bufnr)
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    local filetype = vim.bo[bufnr].filetype

    -- EXTENSION POINT: Add file-level exclusions here
    -- Example: return true, "generated file" for auto-generated files

    -- Exclude TOML files (user has separate TOML sorting tool)
    if filetype == "toml" or filepath:match("%.toml$") then
        return true, "TOML files excluded (use dedicated TOML sorter)"
    end

    return false, nil
end

---Detect import section in Python/JS/TS files
---Returns the last line number of the import section (0-indexed)
---@param bufnr number
---@return number last_import_line
local function find_import_section_end(bufnr)
    local filetype = vim.bo[bufnr].filetype
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Only check for imports in languages that have them
    if
        not (
            filetype == "python"
            or filetype == "javascript"
            or filetype == "typescript"
            or filetype == "javascriptreact"
            or filetype == "typescriptreact"
        )
    then
        return 0
    end

    local last_import_line = 0
    local in_import_section = false

    for i, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")

        -- Skip blank lines and early file headers (shebangs, docstrings, comments)
        local is_early_header = i <= 3
            and (trimmed:match("^#!") or trimmed:match("^#") or trimmed:match('^"""') or trimmed:match("^'''"))
        local should_skip = trimmed == "" or is_early_header

        if not should_skip then
            if trimmed:match("^import ") or trimmed:match("^from .+ import") or trimmed:match("^import%s*{") then
                -- Detect import lines
                in_import_section = true
                last_import_line = i - 1
            elseif in_import_section and (trimmed:match("^%s+") or trimmed:match("^%)")) then
                -- Continuation of multiline import
                last_import_line = i - 1
            else
                -- Non-import, non-blank line - imports section is over
                break
            end
        end
    end

    return last_import_line
end

---Check if a line range is in a sortable context
---@param _bufnr number
---@param _start_row number 0-indexed
---@param _end_row number 0-indexed
---@return boolean is_sortable
---@return string? reason
local function is_sortable_range(_bufnr, _start_row, _end_row)
    -- EXTENSION POINT: Add opt-out markers here
    -- Future: Check for comments like "# sort: skip" or "# nosort"
    -- Example implementation:
    --   local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    --   for _, line in ipairs(lines) do
    --     if line:match("# sort: skip") or line:match("# nosort") then
    --       return false, "manual opt-out marker"
    --     end
    --   end

    -- Skip import sections (detected earlier in sort_file)
    -- This is handled by the caller, but kept here for clarity

    return true, nil
end

---Identify sortable blocks in a file using treesitter and patterns
---Returns list of ranges that should be sorted
---@param bufnr number
---@param start_row number 0-indexed (start of sortable region)
---@param end_row number 0-indexed (end of file)
---@return table[] sortable_ranges List of {start_row, end_row} ranges
local function find_sortable_blocks(bufnr, start_row, end_row)
    local sortable_ranges = {}

    -- STRATEGY: Use treesitter to identify sortable constructs
    -- These patterns are based on the codebase analysis:
    -- 1. Enum members (Python StrEnum, TypeScript enum)
    -- 2. String arrays (const x = [...], origins = [...])
    -- 3. Dictionary/object literals with string keys
    -- 4. YAML service blocks (docker-compose services)
    -- 5. Config object properties (dataclass fields, interface fields)

    local parser = vim.treesitter.get_parser(bufnr)
    if not parser then
        -- Fallback: try to find obvious sortable blocks by indentation
        -- EXTENSION POINT: Add pattern-based detection here
        return sortable_ranges
    end

    local lang = parser:lang()
    local queries = {
        -- Python: Enum classes, list literals, dict literals
        python = [[
            (class_definition
              body: (block
                (expression_statement
                  (assignment
                    left: (identifier)
                    right: (_) @enum_value)))) @enum_class

            (expression_statement
              (assignment
                left: (identifier)
                right: (list) @list_literal))

            (expression_statement
              (assignment
                left: (identifier)
                right: (dictionary) @dict_literal))
        ]],

        -- JavaScript/TypeScript: const arrays, object literals, enums
        javascript = [[
            (lexical_declaration
              (variable_declarator
                value: (array) @array_literal))

            (lexical_declaration
              (variable_declarator
                value: (object) @object_literal))
        ]],

        typescript = [[
            (lexical_declaration
              (variable_declarator
                value: (array) @array_literal))

            (lexical_declaration
              (variable_declarator
                value: (object) @object_literal))

            (enum_declaration
              body: (enum_body) @enum_body)
        ]],

        -- YAML: service blocks, mapping values
        yaml = [[
            (block_mapping_pair
              value: (block_node
                (block_mapping) @service_block))
        ]],
    }

    local query_string = queries[lang]
    if not query_string then return sortable_ranges end

    local ok, query = pcall(vim.treesitter.query.parse, lang, query_string)
    if not ok then return sortable_ranges end

    parser:parse()
    local tree = parser:trees()[1]
    if not tree then return sortable_ranges end

    -- Find all sortable nodes within the range
    for id, node in query:iter_captures(tree:root(), bufnr, start_row, end_row + 1) do
        local capture = query.captures[id]
        local node_start_row, _, node_end_row = node:range()

        -- Only include nodes that are fully within the sortable range
        if node_start_row >= start_row and node_end_row <= end_row + 1 then
            -- Check if this range is sortable (respects opt-out markers)
            local sortable, _ = is_sortable_range(bufnr, node_start_row, node_end_row - 1)
            if sortable then
                table.insert(sortable_ranges, {
                    start_row = node_start_row,
                    end_row = node_end_row - 1,
                    type = capture,
                })
            end
        end
    end

    return sortable_ranges
end

---Sort entire file by discovering sortable blocks
---@param opts? SortOpts
function M.sort_file(opts)
    opts = opts or {}
    local bufnr = vim.api.nvim_get_current_buf()

    -- If explicit mode is set (not "auto"), use traditional range sorting
    -- This allows sort_file({ mode = "line" }) to sort the entire file line-by-line
    if opts.mode and opts.mode ~= "auto" then
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        M.sort_range(bufnr, 0, line_count - 1, opts)
        return
    end

    -- Check if file should be excluded
    local exclude, reason = should_exclude_file(bufnr)
    if exclude then
        vim.notify(string.format("File sorting skipped: %s", reason), vim.log.levels.INFO)
        return
    end

    local line_count = vim.api.nvim_buf_line_count(bufnr)

    -- Find and skip import section for relevant languages
    local sortable_start = find_import_section_end(bufnr)
    if sortable_start > 0 then
        vim.notify(string.format("Skipping import section (lines 1-%d)", sortable_start + 1), vim.log.levels.INFO)
    end

    -- IMPLEMENTATION NOTES:
    --
    -- Current approach: Sort each sortable block independently
    -- This identifies specific constructs (enums, arrays, dicts) and sorts them.
    --
    -- EXTENSION POINTS for future enhancements:
    --
    -- 1. ADD OPT-OUT MARKERS:
    --    Implement comment-based exclusions in is_sortable_range():
    --      # sort: skip  or  # nosort  or  // nosort
    --
    -- 2. ADD OPT-IN MARKERS:
    --    For blocks that shouldn't be auto-sorted but can be manually marked:
    --      # sort: start
    --      ... sortable content ...
    --      # sort: end
    --
    -- 3. ADD CONFIGURATION FILE:
    --    Read .sort-config.yaml for project-specific rules:
    --      exclude_patterns: ["^from.*import", "# no-sort"]
    --      sortable_constructs: [enums, arrays, dicts]
    --      file_exclusions: ["**/generated/**"]
    --
    -- 4. ENHANCE PATTERN DETECTION:
    --    Add more sophisticated detection for:
    --      - Route registration order (should NOT be sorted)
    --      - Test method ordering (setup -> happy -> edge cases)
    --      - Dependency relationships in configs
    --
    -- 5. ADD SORT STRATEGIES:
    --    Different constructs may need different sorting:
    --      - Enums: alphabetical by name
    --      - CORS origins: localhost first, then alphabetical
    --      - Dependencies: alphabetical but respect groups
    --      - Config fields: group by prefix (AWS_*, DB_*, etc.)

    -- Find all sortable blocks in the file
    local sortable_blocks = find_sortable_blocks(bufnr, sortable_start, line_count - 1)

    if #sortable_blocks == 0 then
        vim.notify("No sortable blocks found in file", vim.log.levels.INFO)
        return
    end

    -- Sort each block independently
    local sorted_count = 0
    for _, block in ipairs(sortable_blocks) do
        local success = M.sort_range(bufnr, block.start_row, block.end_row, opts)
        if success then sorted_count = sorted_count + 1 end
    end

    vim.notify(string.format("Sorted %d/%d blocks", sorted_count, #sortable_blocks), vim.log.levels.INFO)
end

---Sort with operator
---@param opts? SortOpts
function M.sort_operator(opts)
    opts = opts or {}

    vim.o.operatorfunc = "v:lua.require'kyleking.utils.sorting'._operator_callback"
    vim.g.sorting_opts = opts
    vim.api.nvim_feedkeys("g@", "n", false)
end

---Operator callback (internal)
function M._operator_callback()
    local opts = vim.g.sorting_opts or {}
    vim.g.sorting_opts = nil

    local bufnr = vim.api.nvim_get_current_buf()
    local start_pos = vim.fn.getpos("'[")
    local end_pos = vim.fn.getpos("']")
    local start_row = start_pos[2] - 1
    local end_row = end_pos[2] - 1

    M.sort_range(bufnr, start_row, end_row, opts)
end

return M
