-- Documentation validation script
-- Ensures documented keybindings have corresponding test coverage

local M = {}

---Extract keybindings from generated documentation
---@param doc_path string Path to generated/plugins.md
---@return table<string, string[]> Map of section name to keybindings
function M.extract_documented_keybindings(doc_path)
    local f = io.open(doc_path, "r")
    if not f then
        error("Cannot open " .. doc_path)
        return {}
    end

    local content = f:read("*a")
    f:close()

    local keybindings = {}
    local current_section = nil

    -- Parse markdown sections and extract keybindings
    for line in content:gmatch("[^\r\n]+") do
        -- Track current section
        local section = line:match("^## (.+)$")
        if section then
            current_section = section
            keybindings[current_section] = keybindings[current_section] or {}
        end

        -- Extract keybindings from operator grammar lines
        -- Patterns: "    <leader>xx", "    gx", "    {motion}x"
        local keybinding = line:match("^%s+([%w<>%-_{}/%[%]]+)%s+")
        if keybinding and current_section then
            -- Filter out grammar patterns (contain {})
            if not keybinding:match("[{}]") then table.insert(keybindings[current_section], keybinding) end
        end

        -- Also extract from markdown list items (e.g., "- `<leader>xx` - description")
        local list_keybinding = line:match("^%-%s+`([^`]+)`")
        if list_keybinding and current_section then
            if not list_keybinding:match("[{}]") then table.insert(keybindings[current_section], list_keybinding) end
        end
    end

    return keybindings
end

---Extract tested keybindings from fixture files
---@param fixture_dir string Path to lua/tests/docs/
---@return table<string, string[]> Map of fixture name to tested keys
function M.extract_tested_keybindings(fixture_dir)
    local fixtures = vim.fn.glob(fixture_dir .. "/*.lua", false, true)
    fixtures = vim.tbl_filter(function(f)
        local name = vim.fn.fnamemodify(f, ":t")
        return name ~= "runner.lua"
            and name ~= "generator.lua"
            and name ~= "runner_spec.lua"
            and name ~= "validate_documentation.lua"
    end, fixtures)

    local tested = {}

    for _, fixture_path in ipairs(fixtures) do
        local fixture_name = vim.fn.fnamemodify(fixture_path, ":t:r")
        local fixture = dofile(fixture_path)

        tested[fixture_name] = {}

        for _, grammar in ipairs(fixture.grammars or {}) do
            for _, test in ipairs(grammar.tests or {}) do
                if test.keys then table.insert(tested[fixture_name], test.keys) end
            end
        end
    end

    return tested
end

---Compare documented vs tested keybindings and report gaps
---@param doc_path string Path to generated/plugins.md
---@param fixture_dir string Path to lua/tests/docs/
---@return table Report with documented, tested, and missing keybindings
function M.validate_coverage(doc_path, fixture_dir)
    local documented = M.extract_documented_keybindings(doc_path)
    local tested = M.extract_tested_keybindings(fixture_dir)

    local report = {
        sections = {},
        total_documented = 0,
        total_tested = 0,
        total_missing = 0,
    }

    for section, doc_keys in pairs(documented) do
        local section_report = {
            section = section,
            documented = doc_keys,
            tested = {},
            missing = {},
        }

        -- Find corresponding fixture (normalize names)
        local fixture_name = section:lower():gsub("%s+", "-"):gsub("[()]", ""):gsub("mini%.", ""):gsub("%.nvim", "")

        -- Try various name variations
        for test_name, test_keys in pairs(tested) do
            if test_name:find(fixture_name) or fixture_name:find(test_name) then
                section_report.tested = test_keys
                break
            end
        end

        -- Check for missing coverage
        for _, doc_key in ipairs(doc_keys) do
            local found = false
            for _, test_key in ipairs(section_report.tested) do
                -- Fuzzy match: check if test_key starts with doc_key
                if test_key:find(doc_key, 1, true) == 1 then
                    found = true
                    break
                end
            end
            if not found then table.insert(section_report.missing, doc_key) end
        end

        report.total_documented = report.total_documented + #doc_keys
        report.total_tested = report.total_tested + #section_report.tested
        report.total_missing = report.total_missing + #section_report.missing

        if #section_report.missing > 0 then table.insert(report.sections, section_report) end
    end

    return report
end

---Print validation report
---@param report table Report from validate_coverage
function M.print_report(report)
    print("\n=== Documentation Coverage Report ===\n")

    if #report.sections == 0 then
        print("✓ All documented keybindings have test coverage!")
    else
        print("⚠ Missing test coverage for the following keybindings:\n")
        for _, section in ipairs(report.sections) do
            print(string.format("## %s", section.section))
            print(string.format("  Documented: %d keybindings", #section.documented))
            print(string.format("  Tested: %d keybindings", #section.tested))
            print(string.format("  Missing: %d keybindings", #section.missing))
            for _, key in ipairs(section.missing) do
                print(string.format("    - %s", key))
            end
            print()
        end
    end

    print(string.format("Total documented: %d", report.total_documented))
    print(string.format("Total tested: %d", report.total_tested))
    print(string.format("Coverage: %.1f%%", (report.total_tested / report.total_documented) * 100))
end

---Main validation function
function M.run()
    local config_dir = vim.fn.stdpath("config")
    local doc_path = config_dir .. "/doc/generated/plugins.md"
    local fixture_dir = config_dir .. "/lua/tests/docs"

    -- Generate docs first if they don't exist
    if vim.fn.filereadable(doc_path) ~= 1 then
        print("Generating documentation first...")
        require("tests.docs.generator").generate_all()
    end

    local report = M.validate_coverage(doc_path, fixture_dir)
    M.print_report(report)

    return report
end

return M
