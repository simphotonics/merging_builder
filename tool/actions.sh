#!/bin/bash --

# Defining colours
BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
RESET='\033[0m'


# Exit immediately if a command exits with a non-zero status.
set -e

# =====================
# Running local scripts
# =====================

# Directories to be processed
# directories="example/researcher_builder/ example/researcher/"

# for directory in $directories; do
#   cd $directory
#   ./tool/actions.sh
#   cd ../..
# done


# Resolving dependencies
echo
echo -e "${BLUE}=== Resolving dependencies $PWD...${RESET}"
echo

# Make sure .dart_tool/package_config.json exists.
dart pub get

# Upgrade packages.
dart pub upgrade

echo
echo -e "${PURPLE}=== Checking Source Code Formatting${RESET} $PWD..."
echo
# Overwrite files with formatted content: -w
# Dry run: -n
dart format lib test

# Analyze dart files
echo
echo -e "${BLUE}=== Analyzing $PWD...${RESET}"
echo
dart analyze \
    --fatal-warnings \
    --fatal-infos
    # \
    # --packages="$PWD/.packages" \
    # $(find bin lib test -name \*.dart 2>/dev/null)

# Running tests
echo
echo -e "${CYAN}=== Testing $PWD...${RESET}"
echo
dart test -r expanded
