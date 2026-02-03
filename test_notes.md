Tier 1: High-value tests on custom code

Files like list_editing_spec.lua, file_opener_spec.lua, keybinding_spec.lua, fs_utils_spec.lua -- these test your code with meaningful behavioral assertions. keybinding_spec.lua is the best example: it detects orphan clue groups, missing descriptions, and new upstream generators. These are worth keeping as-is.

Tier 2: Behavioral integration tests

editing_spec.lua, formatting_spec.lua, mini_ai_spec.lua -- these set up buffers, perform operations, and check results. They test your configuration of third-party plugins. Moderate value.

---

## Coverage measurement

For a neovim config, traditional line coverage tools (luacov) are impractical because:

- Most code runs in a neovim runtime, not standalone Lua
- Third-party plugin behavior isn't yours to cover

What you can measure meaningfully:

- Custom module coverage: Your actual code is in lua/kyleking/utils/ and lua/find-relative-executable/. These are pure-ish Lua modules that could be measured with luacov in the mini.test harness. That's roughly 6 modules where coverage numbers would be actionable.
- Configuration regression coverage: Rather than line coverage, track "what configuration changes would break silently?" The keybinding_spec.lua approach (detect orphans, detect new upstream options) is the right model. You could extend this pattern to other plugins -- e.g., detect when conform.nvim adds new formatter options you haven't configured.

For third-party plugin tests, the metric isn't code coverage -- it's "does my configuration produce the expected behavior?" Focus on behavioral assertions over existence checks.
