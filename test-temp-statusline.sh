#!/usr/bin/env bash
# Test script to verify temp session statusline with colors
# Run this to open a Claude Code temp file and see the modal colors

set -e

# Create temp claude-prompt file
TEMP_FILE=$(mktemp /tmp/claude-prompt-XXXXXX.md)
echo "# Test Claude Code Statusline" > "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
echo "Try switching between modes to see the colors:" >> "$TEMP_FILE"
echo "- Press 'i' for INSERT mode (green)" >> "$TEMP_FILE"
echo "- Press 'v' for VISUAL mode (orange)" >> "$TEMP_FILE"
echo "- Press ESC for NORMAL mode (gray)" >> "$TEMP_FILE"
echo "- Press ':' for COMMAND mode (blue)" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
echo "The statusline should show: [MODE] filename [CLAUDE]" >> "$TEMP_FILE"
echo "" >> "$TEMP_FILE"
echo "Press <leader>q (space+q) to save and quit when done." >> "$TEMP_FILE"

echo "Opening temp Claude Code file: $TEMP_FILE"
echo "Watch the statusline as you switch modes!"

# Open in nvim
nvim "$TEMP_FILE"

# Cleanup
rm -f "$TEMP_FILE"
echo "Test complete!"
