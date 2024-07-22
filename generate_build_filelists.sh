#!/bin/bash
#
# This script compiles kernel and collects a list of complite-time files and related Git metadata
# for each newly added line from tag 1 to tag 2.

show_help() {
    echo "Usage: ./generate_build_filelists.sh [tag1] [tag2]"
    echo "Example: ./generate_rugenerate_build_filelistsntime_web_reports.sh tag1 tag2"
    echo
    echo "Options:"
    echo "  tag1    Optional. Specify tag1 (default: $DEFAULT_TAG1)"
    echo "  tag2    Optional. Specify tag2 (default: $DEFAULT_TAG2)"
    echo "  -h      Display this help message"
    exit 0
}

clone_and_goto_cloned_repo() {
    clone_dir=${1:-"linux-clone"}

    # Capture the absolute path of the root directory
    root_path=$(cd ../.. && pwd)
    parent_root_path=$(cd ../../.. && pwd)
    clone_root_path="$parent_root_path/$clone_dir"
    echo "root_path: $root_path"
    echo "clone root path: $clone_root_path"
    export clone_root_path
    export root_path
    export clone_dir

    mkdir -p "$clone_root_path"

    if [ ! -d "$clone_root_path/.git" ]; then
        git clone "$root_path" "$clone_root_path"
    fi
    cd "$clone_root_path" || exit
}

check_and_create_dir() {
    local new_dir_name="$1"

    if [ ! -d "$new_dir_name" ]; then
        mkdir -p "$new_dir_name"
        echo "Folder '$new_dir_name' created."
    else
        echo "Folder '$new_dir_name' already exists."
    fi
}

display_file_head() {
    local dir_name="$1"
    local file_name="$2"
    local line_num="$3"

    echo "First $line_num lines of $file_name:"
    head -n "$line_num" "$dir_name/$file_name"
    echo
}

export -f display_file_head

if [[ "$1" == "-h" ]]; then
    show_help
fi

DEFAULT_TAG1="v6.9"
DEFAULT_TAG2="v6.10"
TAG1="${1:-$DEFAULT_TAG1}"
TAG2="${2:-$DEFAULT_TAG2}"
DEFAULT_CLONE_PATH="linux-clone"
CLONE_PATH="${3:-$DEFAULT_CLONE_PATH}"

mkdir -p "build_data"

curr_dir=$(pwd)
echo "$curr_dir"
export curr_dir

clone_and_goto_cloned_repo "$CLONE_PATH"

bash "$curr_dir"/build_scripts/build_collect_diff.sh "$TAG1" "$TAG2"
echo "Finishing generating build source file lists"

# Fetch email and name pairing information for linux contributor
bash "$curr_dir"/build_scripts/git_shortlog.sh "$TAG2"
display_file_head "$curr_dir/build_data" "name_list.txt" 3
echo "finished generating email and name list"


# Reframe the git diff report for javascript front-end syntax
input_file="$curr_dir/build_data/filtered_diff_header.txt"
output_file="$curr_dir/build_data/filtered_diff_header_replace.txt"
sed 's/\\/\\\\/g' "$input_file" > "$output_file"
display_file_head "$curr_dir/build_data" "filtered_diff_header_replace.txt" 3

input_file="$curr_dir/build_data/filtered_diff_source.txt"
output_file="$curr_dir/build_data/filtered_diff_source_replace.txt"
sed 's/\\/\\\\/g' "$input_file" > "$output_file"
display_file_head "$curr_dir/build_data" "filtered_diff_source_replace.txt" 3


# Retrieve and tokenize commit info per added line
echo "tokenizing each commit line ..."
git checkout "$TAG2"
python3 "$curr_dir"/build_scripts/tokenize.py "$curr_dir/build_data/filtered_diff_header.txt" "$curr_dir/build_data/parse_git_header.json" "$curr_dir/build_data/tokenize_header.json" "$TAG1" "$TAG2"
python3 "$curr_dir"/build_scripts/tokenize.py "$curr_dir/build_data/filtered_diff_source.txt" "$curr_dir/build_data/parse_git_source.json" "$curr_dir/build_data/tokenize_source.json" "$TAG1" "$TAG2"
display_file_head "$curr_dir/build_data" "tokenize_source.json" 3
display_file_head "$curr_dir/build_data" "tokenize_header.json" 3
echo "finished tokenization"
