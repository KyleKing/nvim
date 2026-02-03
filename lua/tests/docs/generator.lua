-- Documentation generator for plugin fixtures
-- Converts test fixtures into markdown documentation for vimdoc

local M = {}

--- Generate markdown from a fixture file
--- @param fixture_path string Path to fixture file
--- @return string Markdown content
function M.generate_markdown(fixture_path)
    local fixture = dofile(fixture_path)
    local lines = {}

    -- Title
    table.insert(lines, "## " .. fixture.title)
    table.insert(lines, "")

    -- Description
    if fixture.desc then
        table.insert(lines, fixture.desc)
        table.insert(lines, "")
    end

    -- Grammar patterns
    if fixture.grammars and #fixture.grammars > 0 then
        -- Check if we have a simple operator grammar or more complex structure
        local has_tests = false
        for _, grammar in ipairs(fixture.grammars) do
            if grammar.tests and #grammar.tests > 0 then
                has_tests = true
                break
            end
        end

        if has_tests then
            table.insert(lines, "Operator grammar:")
            table.insert(lines, "")
            for _, grammar in ipairs(fixture.grammars) do
                local desc = grammar.desc or ""
                -- Add example from first test case if available
                local example = ""
                if grammar.tests and #grammar.tests > 0 then
                    local test = grammar.tests[1]
                    if test.keys and test.name then example = string.format(" (e.g., %s %s)", test.keys, test.name) end
                end
                table.insert(lines, string.format("    %-20s %s%s", grammar.pattern, desc, example))
            end
            table.insert(lines, "")
        end
    end

    -- Notes
    if fixture.notes and #fixture.notes > 0 then
        for _, note in ipairs(fixture.notes) do
            table.insert(lines, note)
            table.insert(lines, "")
        end
    end

    -- Source
    if fixture.source then
        table.insert(lines, "Source: `" .. fixture.source .. "`")
        table.insert(lines, "")
    end

    -- See also
    if fixture.see_also and #fixture.see_also > 0 then
        local see_also_str = "See also: "
            .. table.concat(vim.tbl_map(function(ref) return "`" .. ref .. "`" end, fixture.see_also), ", ")
        table.insert(lines, see_also_str)
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

--- Generate markdown from all fixture files in docs directory
--- @return table<string, string> Map of fixture names to markdown content
function M.generate_all()
    local config_dir = vim.fn.stdpath("config")
    local test_dir = config_dir .. "/lua/tests/docs"
    local output_dir = config_dir .. "/doc/generated"
    local output_file = output_dir .. "/plugins.md"

    local fixture_files = vim.fn.glob(test_dir .. "/*.lua", false, true)

    -- Filter out non-fixture files
    fixture_files = vim.tbl_filter(function(f)
        local name = vim.fn.fnamemodify(f, ":t")
        return name ~= "runner.lua" and name ~= "generator.lua" and name ~= "init.lua" and not name:match("_spec%.lua$")
    end, fixture_files)

    -- Sort fixture files for deterministic output
    table.sort(fixture_files)

    -- Generate markdown for each fixture
    local sections = {}
    for _, path in ipairs(fixture_files) do
        local markdown = M.generate_markdown(path)
        table.insert(sections, markdown)
    end

    -- Combine all sections
    local combined = "# Plugin Guides\n\n" .. table.concat(sections, "---\n\n")

    -- Create output directory if needed
    vim.fn.mkdir(output_dir, "p")

    -- Write to file
    local file = io.open(output_file, "w")
    if not file then error("Failed to open output file: " .. output_file) end

    file:write(combined)
    file:close()

    print("Generated: " .. output_file)

    -- Also return the map for backwards compatibility
    local result = {}
    for _, path in ipairs(fixture_files) do
        local name = vim.fn.fnamemodify(path, ":t:r")
        result[name] = M.generate_markdown(path)
    end

    return result
end

--- Print markdown for a fixture (for manual inspection)
--- @param fixture_name string Name of fixture file (without .lua)
function M.print_markdown(fixture_name)
    local test_dir = vim.fn.stdpath("config") .. "/lua/tests/docs"
    local fixture_path = string.format("%s/%s.lua", test_dir, fixture_name)

    if vim.fn.filereadable(fixture_path) == 0 then error(string.format("Fixture not found: %s", fixture_path)) end

    local markdown = M.generate_markdown(fixture_path)
    print(markdown)
    return markdown
end

return M
