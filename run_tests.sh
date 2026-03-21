#!/bin/bash
# Run unit tests for the arrow extension

cd "$(dirname "$0")/tests" || exit 1

echo "Running arrows extension tests..."
echo ""

# Try different lua interpreters in order of preference
if command -v lua &> /dev/null; then
    lua test_utils.lua
elif command -v lua5.4 &> /dev/null; then
    lua5.4 test_utils.lua
elif command -v lua5.3 &> /dev/null; then
    lua5.3 test_utils.lua
elif command -v luajit &> /dev/null; then
    luajit test_utils.lua
else
    echo "ERROR: No Lua interpreter found."
    echo ""
    echo "Install Lua with one of:"
    echo "  brew install lua       # macOS"
    echo "  apt install lua5.4     # Ubuntu/Debian"
    echo ""
    exit 1
fi

exit_code=$?
echo ""
exit $exit_code
