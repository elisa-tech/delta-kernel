#!/bin/bash
#
# A script to run the tool with all stages

# Ensure required arguments (tag1 and tag2) are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <tag1> <tag2> [clone_path] [linux_repo_root_url]"
  exit 1
fi

TAG1="$1"
TAG2="$2"

# Optional arguments
# Default values
DEFAULT_CLONE_PATH="linux-clone"
DEFAULT_LINUX_REPO_URL="https://github.com/gregkh/linux"

# Check the number of arguments and set optional parameters accordingly
if [ -n "$3" ] && [ -n "$4" ]; then
  CLONE_PATH="$3"
  REPO_URL="$4"
elif [ -n "$3" ] && [[ "$3" == *"github.com"* || "$3" == *"gitlab.com"* ]]; then
  CLONE_PATH="$DEFAULT_CLONE_PATH"
  REPO_URL="$3"
elif [ -n "$3" ]; then
  CLONE_PATH="$3"
  REPO_URL="$DEFAULT_LINUX_REPO_URL"
else
  CLONE_PATH="$DEFAULT_CLONE_PATH"
  REPO_URL="$DEFAULT_LINUX_REPO_URL"
fi

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
git clone "$REPO_URL"


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
./generate_web_reports.sh "$TAG1" "$TAG2" "$REPO_URL" # fix later

# Return to the original directory
cd "$CUR_DIR" || exit

# Copy the web source code to the current directory
cp -r $TARGET_DIR/web_source_code .
cp -r $TARGET_DIR/build_data .
