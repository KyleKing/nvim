# Draft: nvim bug report for `start_config` on a deleted buffer

Not filed. Edit and submit yourself if you want it. Everything below was reproduced on this machine against nvim 0.12.4, and the relevant lines on `master` are byte-identical.

## Suggested title

`vim.lsp`: scheduled `start_config` errors when the buffer is deleted before it runs

## Body

**Problem**

When an LSP config uses a function `root_dir`, `lsp_enable_callback` defers the server start with `vim.schedule`. Nothing rechecks the buffer before that callback runs, so closing the buffer in the same tick produces an error from `vim.fs.root`:

```
vim.schedule callback: vim/fs:483: Invalid buffer id: 1
stack traceback:
	[C]: in function '__index'
	vim/fs:483: in function 'root'
	.../share/nvim/runtime/lua/vim/lsp.lua:749: in function 'start_config'
	.../share/nvim/runtime/lua/vim/lsp.lua:564: in function <.../lsp.lua:563>
```

`runtime/lua/vim/lsp.lua:560-566`:

```lua
if type(config.root_dir) == 'function' then
  config.root_dir(bufnr, function(root_dir)
    config.root_dir = root_dir
    vim.schedule(function()
      start_config(bufnr, config)   -- bufnr may be gone by now
    end)
  end)
```

`start_config` reaches `lsp.start`, which at line 749 calls `vim.fs.root(bufnr, opts._root_markers)`. `fs.lua:483` then indexes `vim.bo[source]` on a dead id and throws.

**Steps to reproduce**

With any config where a Lua server is enabled and lazydev.nvim is installed (lazydev injects a function `root_dir` for every enabled Lua server):

```lua
vim.defer_fn(function()
  vim.cmd('edit /tmp/probe.lua')
  vim.cmd('bwipeout!')
end, 3000)
```

The 3s delay matters. lazydev installs its integration inside its own `vim.schedule`, so `vim.lsp.config.lua_ls.root_dir` is still `nil` for the first tick after startup and an immediate probe sees nothing.

**Expected behavior**

No error. The buffer is gone, so the scheduled start should be dropped.

**Impact**

Not limited to that one plugin. nvim-lspconfig ships 58 `lsp/*.lua` files with a function `root_dir`, and three (`gopls`, `rust_analyzer`, `muon`) are genuinely asynchronous — `rust_analyzer` runs `cargo metadata` through `vim.system` before calling `on_dir`, so the window between `FileType` and `start_config` is seconds rather than one tick. Opening a Rust file and `:bd`-ing it, or scrolling a fuzzy-finder preview, lands in it.

This is the same class as #29614 ("LSP handlers do not consistently check if the buffer is still valid"), which was accepted and fixed.

**Suggested fix**

```diff
     vim.schedule(function()
+      if not api.nvim_buf_is_valid(bufnr) then
+        return
+      end
       start_config(bufnr, config)
     end)
```

An equivalent guard at the top of `lsp.start`, after `vim._resolve_bufnr`, would cover every caller rather than this one site. `runtime/lua/vim/lsp.lua` currently contains no `nvim_buf_is_valid` call at all.

**Version**

`NVIM v0.12.4`, macOS. `master` at the time of writing has the same lines 560-566 and the same absence of a validity check.

## Notes before you submit

- Search once more for a duplicate. Nothing turned up for `vim.fs.root Invalid buffer`, `start_config invalid buffer`, or `root_dir function buffer deleted`, but that was some time before you read this.
- A PR is more likely to land than an issue, given the diff is four lines.
- If you would rather not name lazydev, the repro also works with any hand-written `vim.lsp.config('lua_ls', { root_dir = function(bufnr, on_dir) on_dir(nil) end })`.
