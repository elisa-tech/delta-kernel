#!/bin/bash
#
# Generate metadata *.js files for web report

echo "Generating metadata js files ..."
DEFAULT_TAG1="v6.9"
DEFAULT_TAG2="v6.10"
# shellcheck disable=SC2034
TAG1="${1:-$DEFAULT_TAG1}"
# shellcheck disable=SC2034
TAG2="${2:-$DEFAULT_TAG2}"

# Generate front-end commit info metadata
echo "Generating source_data.js ..."
if [ ! -f "build_data/tokenize_source.json" ]; then
  echo "Error: build_data/tokenize_source.json not found!"
  exit 1
fi
TOKEN_DATA_SOURCE=$(cat build_data/tokenize_source.json)
echo "let token_data = $TOKEN_DATA_SOURCE;" > web_source_code/source_data.js

echo "Generating header_data.js ..."
if [ ! -f "build_data/tokenize_header.json" ]; then
  echo "Error: build_data/tokenize_header.json not found!"
  exit 1
fi
TOKEN_DATA_HEADER=$(cat build_data/tokenize_header.json)
echo "let token_data = $TOKEN_DATA_HEADER;" > web_source_code/header_data.js

# Generate front-end git diff report metadata
echo "Generating git_diff_source.js ..."
DIFF_OUTPUT_SOURCE=$(cat build_data/filtered_diff_source_replace.txt)
SOURCE_TRIM=${DIFF_OUTPUT_SOURCE//\`/\\\`}
# shellcheck disable=SC2001
SOURCE_TRIM_ESCAPED=$(echo "$SOURCE_TRIM" | sed 's/\$/\\$/g')
echo "let diffs = \`
$SOURCE_TRIM_ESCAPED
\`.trim();" > web_source_code/git_diff_source.js

echo "Generating git_diff_header.js ..."
DIFF_OUTPUT_HEADER=$(cat build_data/filtered_diff_header_replace.txt)
HEADER_TRIM=${DIFF_OUTPUT_HEADER//\`/\\\`}
# shellcheck disable=SC2001
HEADER_TRIM_ESCAPED=$(echo "$HEADER_TRIM" | sed 's/\$/\\$/g')
echo "let diffs = \`
$HEADER_TRIM_ESCAPED
\`.trim();" > web_source_code/git_diff_header.js

echo "let tag1 = \"$TAG1\"; let tag2 = \"$TAG2\";" > web_source_template/versions.js

echo "SUCCESS generated metadata js files"
