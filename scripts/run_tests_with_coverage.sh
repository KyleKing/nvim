#!/usr/bin/env bash
# Run tests with luacov coverage tracking
# Usage: ./scripts/run_tests_with_coverage.sh [custom|all|specific_test.lua]

set -e

# Check if luacov is installed
if ! command -v luacov &> /dev/null; then
    echo "Error: luacov not found. Install with: luarocks install luacov"
    exit 1
fi

# Clean up previous coverage data
rm -f .luacov.*.out luacov.*.out

TARGET="${1:-all}"
CONFIG_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Running tests with coverage tracking ==="
echo "Target: $TARGET"
echo "Config: $CONFIG_DIR"
echo

cd "$CONFIG_DIR"

# Run tests with luacov loaded
if [ "$TARGET" = "all" ]; then
    MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
        -c "lua package.loaded.luacov = require('luacov'); luacov.init()" \
        -c "lua MiniTest.run()" \
        +qall || true
elif [ "$TARGET" = "custom" ]; then
    # Run only custom module tests
    MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
        -c "lua package.loaded.luacov = require('luacov'); luacov.init()" \
        -c "lua local files = vim.fn.glob('lua/tests/custom/*_spec.lua', false, true); for _, f in ipairs(files) do MiniTest.run_file(f, {verbose=false}) end" \
        +qall || true
else
    # Run specific test file
    MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
        -c "lua package.loaded.luacov = require('luacov'); luacov.init()" \
        -c "lua MiniTest.run_file('$TARGET')" \
        +qall || true
fi

# Generate coverage report
echo
echo "=== Generating coverage report ==="
luacov

# Display coverage summary for custom modules
echo
echo "=== Coverage Summary (custom modules) ==="
echo

if [ -f ".luacov.report.out" ]; then
    # Extract coverage for custom modules
    awk '
        /^kyleking\/utils|^kyleking\/core|^find-relative-executable/ {
            in_custom = 1
            print
            next
        }
        in_custom && /^$/ {
            in_custom = 0
        }
        in_custom {
            print
        }
        /^Summary/ {
            in_summary = 1
        }
        in_summary {
            print
        }
    ' .luacov.report.out

    echo
    echo "Full report: .luacov.report.out"
else
    echo "Warning: Coverage report not generated"
fi
