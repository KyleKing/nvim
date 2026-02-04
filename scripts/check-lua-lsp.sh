#!/bin/bash
# Fast Lua LSP diagnostics using lua-language-server directly (no nvim)
# Checks entire workspace in ~1-2 seconds

set -eo pipefail  # Removed -u flag
cd ~/.config/nvim || exit 1

# Run lua-language-server check and capture last line with summary
summary=$(lua-language-server \
    --check="$(pwd)" \
    --check_format=pretty \
    --checklevel=Warning \
    --configpath=.luarc.json \
    2>/dev/null | tail -1) || true  # Don't fail on tail

# Check if problems were found - format is "Diagnosis complete, N problems found"
if echo "$summary" | grep -qE "[1-9][0-9]* problems? found"; then
    # Extract problem count
    count=$(echo "$summary" | grep -oE "[0-9]+ problems? found" | head -1 | grep -oE "^[0-9]+")
    echo "✗ Lua LSP found $count problem(s)" >&2
    echo "  Run: lua-language-server --check=\$(pwd) --check_format=pretty --checklevel=Warning" >&2
    exit 1
else
    echo "✓ No Lua LSP diagnostics found" >&2
    exit 0
fi
