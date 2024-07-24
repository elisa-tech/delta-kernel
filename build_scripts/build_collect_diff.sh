#!/bin/bash
#
# Script to build the kernel, collect compiled file lists using modified kernel scripts,
# and generate a git diff report based on the collected lists.

set -e

DEFAULT_TAG1="v5.15"
DEFAULT_TAG2="v5.15.100"
TAG1="${TAG1_ENV:-$DEFAULT_TAG1}"
TAG2="${TAG2_ENV:-$DEFAULT_TAG2}"

# check and install gcc-11 if not already installed
install_package_safe() {
    if ! command -v gcc-11 &> /dev/null; then
        sudo apt update
        sudo apt install gcc-11
    else
        echo "GCC-11 is already installed."
    fi
    if ! command -v libssl-dev &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y libssl-dev
    else
        echo "libssl-dev is already installed."
    fi
}

# safely apply a patch to linux kernel
apply_patch() {
    # shellcheck disable=SC2154
    local patch_path="$root_path/scripts/change-impact-tools/fixdep-patch.file"

    # Stash any changes if there is any
    if ! git diff --quiet; then
        git stash
    fi

    # Abort `git am` only if there is a patch being applied
    if git am --show-current-patch &> /dev/null; then
        git am --abort
    fi
    echo "path check: $(pwd)"
    git apply < "$patch_path"
    echo "applied the git patch"
    echo "path check: $(pwd)"
}

# parse the JSON file
parse_source_json_file() {
    local python_path="$root_path/scripts/change-impact-tools/build_scripts/parse_json.py"
    # shellcheck disable=SC2154
    local cloned_repo_name="/$clone_dir/"
    local input_path="$root_path/scripts/change-impact-tools/build_data/compile_commands.json"
    local output_path="$root_path/scripts/change-impact-tools/build_data/sourcefile.txt"

    python3 "$python_path" "$cloned_repo_name" "$input_path" "$output_path"
    display_file_head "$root_path/scripts/change-impact-tools/build_data" "sourcefile.txt" 3
}

# generate the build file list after building the kernel
generate_compiled_file_lists() {
    # Generate compiled source files list
    local json_output_path="$root_path/scripts/change-impact-tools/build_data/compile_commands.json"
    echo "path check: $(pwd)"
    python3 scripts/clang-tools/gen_compile_commands.py -o "$json_output_path"

    parse_source_json_file
    echo "source compiled filelist generated to sourcefile.txt"

    # Generate compiled header files list

    local output_list="$root_path/scripts/change-impact-tools/build_data/headerfile.txt"
    local output_json="$root_path/scripts/change-impact-tools/build_data/source_dep.json"
    local dep_path="dependency_file.txt"
    local python_tool_path="$root_path/scripts/change-impact-tools/build_scripts/parse_dep_list.py"

    python3 "$python_tool_path" "$dep_path" "$output_json" "$output_list"
    echo "dependency compiled filelist generated to headerfile.txt$"

}

# clean up the working directory
cleanup_working_directory() {
    git reset --hard
    git clean -fdx
}

# generate diff for build between TAG1 and TAG2
generate_git_diff() {

    # collect and setup input & output file
    file_type=${1:-source}
    local root_build_data_path="$root_path/scripts/change-impact-tools/build_data"
    local diff_input="$root_build_data_path/sourcefile.txt"
    local diff_output="$root_build_data_path/filtered_diff_source.txt"

    if [ "$file_type" = "header" ]; then
        echo "[generate_git_diff] Generating dependency git diff report ..."
        diff_input="$root_build_data_path/headerfile.txt"
        diff_output="$root_build_data_path/filtered_diff_header.txt"
    else
        echo "[generate_git_diff] Generating source git diff report ..."
    fi

    while IFS= read -r file
    do
        if git show "$TAG2:$file" &> /dev/null; then
            local diff_result
            diff_result=$(git diff "$TAG1" "$TAG2" -- "$file")
            if [[ -n "$diff_result" ]]; then
                {
                    echo "Diff for $file"
                    echo "$diff_result"
                    echo ""
                } >> "$diff_output"

            fi
        fi
    done < "$diff_input"
    echo "[generate_git_diff] Git diff report for $file_type files save to compiled_data"

}


if [ $# -eq 2 ]; then
    TAG1="$1"
    TAG2="$2"
fi

# Fetch tags from the repository
git fetch --tags
echo "Generating source file list for $TAG1"
git checkout "$TAG1"
echo "starting to run make olddefconfig"
make olddefconfig
echo "finished make olddefconfig"


# Preparation before running make
apply_patch
install_package_safe

# Build linux kernel
echo "the current os-linux version: "
cat /etc/os-release

echo "start running make"
make HOSTCC=gcc-11 CC=gcc-11
echo "finished compile kernel using gcc 11"


# Collect build metadata
generate_compiled_file_lists

# Generate git diff report
generate_git_diff source
generate_git_diff header

# Clean up the working directory
cleanup_working_directory
