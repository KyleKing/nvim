# Plugin Usage Guides

This directory contains usage guides for plugins configured in this nvim setup.

## Available Guides

### Fuzzy Finding & Search

**[Codanna Semantic Search](./codanna-guide.md)**

- Semantic code search with mini.pick integration
- Cross-file impact analysis and call hierarchies
- Natural language code queries
- Configuration: `lua/kyleking/deps/fuzzy-finder.lua:132-150`
- Keybindings: `<leader>ls*` (semantic operations)

### Utilities

**[patch_it.nvim](./patch_it-guide.md)**

- Apply LLM-generated patches with fuzzy matching
- Integration with Claude Code and Code Rabbit
- Preview and apply modes
- Configuration: `lua/kyleking/deps/utility.lua:39-59`
- Keybindings: `<leader>pa*` (patch operations)

## Development Guides

**[Building Claude Skills](./claude-skills-guide.md)**

- Guide for creating custom Claude Code skills
- API integration patterns and workflow automation

**[MiniTest Skill](./minitest-claude-skill-guide.md)** and **[README](./MINITEST_SKILL_README.md)**

- Claude Code skill for running MiniTest tests
- Integration with mini.test framework

## Configuration Structure

Plugin configurations are organized by category in `lua/kyleking/deps/`:

- `fuzzy-finder.lua` - mini.pick, mini.extra, codanna
- `utility.lua` - patch_it, spelling, URL handling
- `lsp.lua` - Language server configurations
- `git.lua` - Git operations and diff tools
- `editing-support.lua` - Text editing enhancements
- `file-explorer.lua` - File navigation
- Additional category-specific files

## Adding New Guides

When adding plugin guides:

1. Create guide in `doc/` directory: `doc/plugin-name-guide.md`
1. Follow structure: Overview → Installation → Keybindings → Usage → Troubleshooting
1. Include configuration file location and line numbers
1. Add entry to this index under appropriate category
1. Use consistent formatting with existing guides
