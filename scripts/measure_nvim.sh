#!/usr/bin/env bash
# Based on: https://github.com/NTBBloodbath/nvim/blob/e0ad6fcd5aae6e9b1599e44953a48a31f865becc/extern/measure_nvim.sh
# Automated version that appends results to BENCHMARKS.md

set -e

# Skip re-measuring if the last commit already updated BENCHMARKS.md
if git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -qx 'BENCHMARKS.md'; then
    echo "BENCHMARKS.md already updated in the last commit, skipping"
    exit 0
fi

get_time() {
    grep "NVIM STARTED" <tmp | cut -d ' ' -f 1
}

pf() {
    printf '%s : ' "$@"
}

get_hw_fingerprint() {
    if [ "$(uname -s)" = "Darwin" ]; then
        local cpu cores
        cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
        cores=$(sysctl -n hw.ncpu 2>/dev/null)
        echo "${cpu} (${cores} cores), macOS $(sw_vers -productVersion 2>/dev/null)"
    else
        local cpu cores
        cpu=$(grep -m1 '^model name' /proc/cpuinfo 2>/dev/null | cut -d ':' -f 2 | sed 's/^ //')
        cores=$(nproc 2>/dev/null)
        echo "${cpu:-unknown} (${cores:-?} cores), $(uname -sr)"
    fi
}

# Run benchmarks and capture output
OUTPUT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/BENCHMARKS.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
HW_FINGERPRINT=$(get_hw_fingerprint)

# Initialize file if it doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    cat >"$OUTPUT_FILE" <<'EOF'
# Startup Performance Benchmarks

Automated measurements from `scripts/measure_nvim.sh`.

## Results

EOF
fi

# Run measurements
pf "No config"
nvim --headless --startuptime tmp --clean -nu NORC -c 'qall!' 2>/dev/null
TIME_NO_CONFIG=$(get_time)
echo "$TIME_NO_CONFIG"
rm tmp

pf "With config"
nvim --headless --startuptime tmp -c 'qall!' 2>/dev/null
TIME_WITH_CONFIG=$(get_time)
echo "$TIME_WITH_CONFIG"
rm tmp

pf "Opening init.lua"
nvim --headless --startuptime tmp "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" -c 'qall!' 2>/dev/null
TIME_INIT_LUA=$(get_time)
echo "$TIME_INIT_LUA"
rm tmp

pf "Opening Python file"
if [ -f ~/Developer/kyleking/corallium/corallium/pretty_process.py ]; then
    nvim --headless --startuptime tmp ~/Developer/kyleking/corallium/corallium/pretty_process.py -c 'qall!' 2>/dev/null
    TIME_PYTHON=$(get_time)
    echo "$TIME_PYTHON"
    rm tmp
else
    TIME_PYTHON="N/A"
    echo "N/A (file not found)"
fi

# Append results to markdown file
cat >>"$OUTPUT_FILE" <<EOF

### $TIMESTAMP

- Commit: ${COMMIT_SHA}
- Machine: ${HW_FINGERPRINT}
- No config: ${TIME_NO_CONFIG}ms
- With config: ${TIME_WITH_CONFIG}ms
- Opening init.lua: ${TIME_INIT_LUA}ms
- Opening Python file: ${TIME_PYTHON}ms
EOF

echo ""
echo "Results appended to $OUTPUT_FILE"
