#!/bin/bash
#
# A script to run the tool with all stages

show_help() {
    echo "Usage: ./run_tool.sh [tag1] [tag2]"
    echo "Example: ./run_tool.sh v6.9 v6.10"
    echo
    echo "Options:"
    echo "  tag1    Optional. Specify old_linux_version (default: $DEFAULT_TAG1)"
    echo "  tag2    Optional. Specify new_linux_version (default: $DEFAULT_TAG2)"
    echo "  -h      Display this help message"
    exit 0
}

if [[ "$1" == "-h" ]]; then
    show_help
fi

DEFAULT_TAG1="v6.9"
DEFAULT_TAG2="v6.10"
TAG1="${1:-$DEFAULT_TAG1}"
TAG2="${2:-$DEFAULT_TAG2}"
DEFAULT_CLONE_PATH="linux-clone"
CLONE_PATH="${3:-$DEFAULT_CLONE_PATH}"

# Define the repository URL and the target directory
REPO_URL="https://github.com/gregkh/linux"
TARGET_DIR="linux/scripts/change-impact-tools"

# Clone the repository
git clone $REPO_URL

# Create the target directory if it doesn't exist
mkdir -p $TARGET_DIR

# Copy necessary scripts to the target directory
cp -r build_scripts $TARGET_DIR/
cp -r web_scripts $TARGET_DIR/
cp fixdep-patch.file $TARGET_DIR/
cp generate_build_filelists.sh $TARGET_DIR/
cp generate_web_reports.sh $TARGET_DIR/
mkdir -p $TARGET_DIR/web_source_code
mv web_source_template/* $TARGET_DIR/web_source_code/


# Save the current directory
CUR_DIR=$(pwd)

# Navigate to the target directory and execute the scripts
cd "$TARGET_DIR" || exit
./generate_build_filelists.sh "$TAG1" "$TAG2" "$CLONE_PATH"
./generate_web_reports.sh "$TAG1" "$TAG2"

# Return to the original directory
cd "$CUR_DIR" || exit

# Copy the web source code to the current directory
cp -r $TARGET_DIR/web_source_code .
