#!/bin/bash
#
# Generate the web report source codes (*.html and *.js) for the web report

function show_help {
    echo "Usage: ./generate_build_web_reports.sh [tag1] [tag2]"
    echo "Example: ./generate_build_web_reports.sh tag1 tag2"
    echo
    echo "Options:"
    echo "  tag1    Optional. Specify tag1 (default: $DEFAULT_TAG1)"
    echo "  tag2    Optional. Specify tag2 (default: $DEFAULT_TAG2)"
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

./web_scripts/generate_data.sh "$TAG1" "$TAG2"

echo "finishing generating webpage, report can be viewed in web_source_code/index.html"
