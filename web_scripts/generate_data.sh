#!/bin/bash
#
# Generate metadata *.js files for web report

echo "Generating metadata js files ..."

# Ensure required arguments (tag1 and tag2) are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <tag1> <tag2> <linux_repo_root_url>"
  exit 1
fi

TAG1="$1"
TAG2="$2"
REPO_URL="$3"

# Determine if REPO_URL is a GitHub or GitLab URL
if [[ "$REPO_URL" == "https://github"* ]]; then
  REPO_TYPE="github"
else
  REPO_TYPE="gitlab"
fi

echo "Repository URL ($REPO_URL) is identified as: $REPO_TYPE"


# Generate front-end commit info metadata
echo "Generating source_data.js ..."
if [ ! -f "build_data/tokenize_source.json" ]; then
  echo "Error: build_data/tokenize_source.json not found!"
  exit 1
fi
TOKEN_DATA_SOURCE=$(cat build_data/tokenize_source.json)
echo "let token_data_source = $TOKEN_DATA_SOURCE;" > web_source_code/source_data.js

echo "Generating header_data.js ..."
if [ ! -f "build_data/tokenize_header.json" ]; then
  echo "Error: build_data/tokenize_header.json not found!"
  exit 1
fi
TOKEN_DATA_HEADER=$(cat build_data/tokenize_header.json)
echo "let token_data_header = $TOKEN_DATA_HEADER;" > web_source_code/header_data.js

# Generate front-end git diff report metadata
echo "Generating git_diff_source.js ..."
DIFF_OUTPUT_SOURCE=$(cat build_data/filtered_diff_source_replace.txt)
SOURCE_TRIM=${DIFF_OUTPUT_SOURCE//\`/\\\`}
# shellcheck disable=SC2001
SOURCE_TRIM_ESCAPED=$(echo "$SOURCE_TRIM" | sed 's/\$/\\$/g')
echo "let diffs_source = \`
$SOURCE_TRIM_ESCAPED
\`.trim();" > web_source_code/git_diff_source.js

echo "Generating git_diff_header.js ..."
DIFF_OUTPUT_HEADER=$(cat build_data/filtered_diff_header_replace.txt)
HEADER_TRIM=${DIFF_OUTPUT_HEADER//\`/\\\`}
# shellcheck disable=SC2001
HEADER_TRIM_ESCAPED=$(echo "$HEADER_TRIM" | sed 's/\$/\\$/g')
echo "let diffs_header = \`
$HEADER_TRIM_ESCAPED
\`.trim();" > web_source_code/git_diff_header.js


cat <<EOF > web_source_code/versions.js
let tag1 = "$TAG1";
let tag2 = "$TAG2";
let root_linux_url = "$REPO_URL";
let repo_type = "$REPO_TYPE";
EOF

echo "SUCCESS generated metadata js files"
