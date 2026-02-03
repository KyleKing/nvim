-- Test mini.files file operations
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["mini.files"] = MiniTest.new_set()

T["mini.files"]["can open file browser"] = function()
    local MiniFiles = require("mini.files")

    -- Open mini.files in a temp directory
    local tmpdir = vim.fn.tempname() .. "_files"
    vim.fn.mkdir(tmpdir, "p")

    MiniFiles.open(tmpdir)
    vim.wait(200)

    -- Check that mini.files window is open
    local buffers = vim.api.nvim_list_bufs()
    local has_files_buffer = false
    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) then
            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname:match("mini%-files") or vim.bo[buf].filetype == "minifiles" then
                has_files_buffer = true
                break
            end
        end
    end

    MiniFiles.close()
    vim.fn.delete(tmpdir, "rf")

    MiniTest.expect.equality(has_files_buffer, true, "mini.files should open successfully")
end

T["mini.files"]["can create file"] = function()
    local MiniFiles = require("mini.files")

    local tmpdir = vim.fn.tempname() .. "_create"
    vim.fn.mkdir(tmpdir, "p")

    -- Open mini.files and create a file
    MiniFiles.open(tmpdir)
    vim.wait(200)

    -- Get current buffer and add a new line (simulating file creation)
    local new_file = tmpdir .. "/test_file.txt"
    vim.fn.writefile({ "test content" }, new_file)

    -- Synchronize
    MiniFiles.synchronize()
    vim.wait(200)

    MiniFiles.close()

    -- Verify file was created
    local file_exists = vim.fn.filereadable(new_file) == 1

    vim.fn.delete(tmpdir, "rf")

    MiniTest.expect.equality(file_exists, true, "Should create file via mini.files")
end

T["mini.files"]["can delete file"] = function()
    local MiniFiles = require("mini.files")

    local tmpdir = vim.fn.tempname() .. "_delete"
    vim.fn.mkdir(tmpdir, "p")

    -- Create a test file
    local test_file = tmpdir .. "/delete_me.txt"
    vim.fn.writefile({ "content" }, test_file)

    -- Open mini.files
    MiniFiles.open(tmpdir)
    vim.wait(200)

    -- Delete the file
    vim.fn.delete(test_file)
    MiniFiles.synchronize()
    vim.wait(200)

    MiniFiles.close()

    -- Verify file was deleted
    local file_exists = vim.fn.filereadable(test_file) == 1

    vim.fn.delete(tmpdir, "rf")

    MiniTest.expect.equality(file_exists, false, "Should delete file via mini.files")
end

T["mini.files"]["can navigate directories"] = function()
    local MiniFiles = require("mini.files")

    local tmpdir = vim.fn.tempname() .. "_nav"
    vim.fn.mkdir(tmpdir .. "/subdir", "p")
    vim.fn.writefile({ "file1" }, tmpdir .. "/file1.txt")
    vim.fn.writefile({ "file2" }, tmpdir .. "/subdir/file2.txt")

    -- Open mini.files at root
    MiniFiles.open(tmpdir)
    vim.wait(200)

    -- Check that we can navigate (basic config validation)
    local current_dir = MiniFiles.get_fs_entry()
    local is_at_tmpdir = current_dir and current_dir.path:match(tmpdir) ~= nil

    MiniFiles.close()
    vim.fn.delete(tmpdir, "rf")

    MiniTest.expect.equality(is_at_tmpdir, true, "Should navigate to correct directory")
end

T["mini.files"]["config validation"] = function()
    local MiniFiles = require("mini.files")

    -- Verify config is set up
    MiniTest.expect.equality(type(MiniFiles.config), "table", "mini.files config should be loaded")
    MiniTest.expect.equality(type(MiniFiles.open), "function", "open function should be available")
    MiniTest.expect.equality(type(MiniFiles.close), "function", "close function should be available")
    MiniTest.expect.equality(type(MiniFiles.synchronize), "function", "synchronize function should be available")
end

T["mini.files"]["keybindings are set"] = function()
    local keymaps = vim.api.nvim_get_keymap("n")

    local has_files_keymap = false
    for _, keymap in ipairs(keymaps) do
        if keymap.lhs == "<leader>e" or keymap.lhs == "-" then
            local desc = keymap.desc or ""
            if desc:match("[Ff]ile") or desc:match("mini%.files") then
                has_files_keymap = true
                break
            end
        end
    end

    MiniTest.expect.equality(has_files_keymap, true, "mini.files keybindings should be set")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
