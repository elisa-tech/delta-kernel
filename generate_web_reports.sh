#!/bin/bash
#
# Generate the web report source codes (*.html and *.js) for the web report

function show_help {
    echo "Usage: ./generate_build_web_reports.sh [tag1] [tag2] [linux_repo_root_url]"
    echo "Example: ./generate_build_web_reports.sh tag1 tag2 linux_url"
    echo
    echo "Options:"
    echo "  tag1    Required: old_linux_version [e.g. v6.8]"
    echo "  tag2    Required: new_linux_version [e.g. v6.9]"
    echo "  -h      Display this help message"
    exit 0
}

if [[ "$1" == "-h" ]]; then
    show_help
fi

# Ensure required arguments (tag1 and tag2) are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <tag1> <tag2> <linux_repo_root_url>"
  exit 1
fi

TAG1="$1"
TAG2="$2"
REPO_URL="$3"

./web_scripts/generate_data.sh "$TAG1" "$TAG2" "$REPO_URL"

echo "finishing generating webpage, report can be viewed in web_source_code/index.html"
