#!/usr/bin/env bash
# Regenerate doc/kyleking-neovim.txt from doc/src/main.md
#
# panvimdoc is distributed only as a git repo of shell and pandoc-lua scripts,
# so it is cloned into the gitignored deps/ directory at the pinned tag below.
# Bump PANVIMDOC_TAG to upgrade; the stamp file forces a re-clone on mismatch.
#
# Requires pandoc on PATH (`brew install pandoc`), which is why the hk steps
# that call this are skipped in CI.
set -euo pipefail

PANVIMDOC_TAG="v4.0.1"
PANVIMDOC_DIR="deps/panvimdoc"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [ "$(cat "$PANVIMDOC_DIR/.tag" 2>/dev/null)" != "$PANVIMDOC_TAG" ]; then
    rm -rf "$PANVIMDOC_DIR"
    git clone --depth 1 --branch "$PANVIMDOC_TAG" \
        https://github.com/kdheepak/panvimdoc "$PANVIMDOC_DIR"
    echo "$PANVIMDOC_TAG" >"$PANVIMDOC_DIR/.tag"
fi

bash "$PANVIMDOC_DIR/panvimdoc.sh" \
    --project-name kyleking-neovim \
    --input-file doc/src/main.md \
    --toc true \
    --treesitter true \
    --dedup-subheadings false \
    --demojify true
