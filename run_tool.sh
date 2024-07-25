#!/bin/bash
#
# A script to run the tool with all stages

set -e


# Ensure at least two positional parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <tag1> <tag2> [-c clone_path] [-u repo_link] [-s subsystem]"
  echo "error"
  exit 1
fi

TAG1="$1"
TAG2="$2"

CLONE_PATH="linux-clone"
REPO_URL="https://github.com/gregkh/linux"
SUBSYS=""

print_usage() {
  echo "Usage: $0 <tag1> <tag2> [-c clone_path] [-u repo_link] [-s subsystem]"
}

# Shift positional parameters before processing options
shift 2

# Parse optional arguments
while getopts 'c:u:s:' flag; do
  case "${flag}" in
    c) CLONE_PATH="${OPTARG}" ;;
    u) REPO_URL="${OPTARG}" ;;
    s) SUBSYS="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

# Debug information
echo "TAG1: $TAG1"
echo "TAG2: $TAG2"
echo "CLONE_PATH: $CLONE_PATH"
echo "REPO_URL: $REPO_URL"
echo "SUBSYS: $SUBSYS"
# Determine if REPO_URL is a GitHub or GitLab URL
if [[ "$REPO_URL" == "https://github"* ]]; then
  REPO_TYPE="github"
elif [[ "$REPO_URL" == "https://gitlab"* ]]; then
  REPO_TYPE="gitlab"
else
  REPO_TYPE="Unknown"
  echo "Error: The repository URL ($REPO_URL) is neither a GitHub nor a GitLab URL."
  exit 1
fi

echo "Repository URL ($REPO_URL) is identified as: $REPO_TYPE"

TARGET_DIR="linux/scripts/change-impact-tools"

# Clone the repository
if [ ! -d linux/.git ]; then
  git clone "$REPO_URL"
fi


# Create the target directory if it doesn't exist
mkdir -p $TARGET_DIR

# Copy necessary scripts to the target directory
cp -rf build_scripts $TARGET_DIR/
cp -rf web_scripts $TARGET_DIR/
cp -f fixdep-patch.file $TARGET_DIR/
cp -f generate_build_filelists.sh $TARGET_DIR/
cp -f generate_web_reports.sh $TARGET_DIR/
mkdir -p $TARGET_DIR/web_source_code
cp web_source_template/* $TARGET_DIR/web_source_code/

# Save the current directory
CUR_DIR=$(pwd)

# Navigate to the target directory and execute the scripts
cd "$TARGET_DIR" || exit
./generate_build_filelists.sh "$TAG1" "$TAG2" "$CLONE_PATH" "$SUBSYS"
./generate_web_reports.sh "$TAG1" "$TAG2" "$REPO_URL"

# Return to the original directory
cd "$CUR_DIR" || exit

# Copy the web source code to the current directory
cp -rf $TARGET_DIR/web_source_code .
cp -rf $TARGET_DIR/build_data .
