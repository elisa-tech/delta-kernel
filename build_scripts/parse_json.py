"""
The script collects a list of compile-time source files.

Running `$K/scripts/clang-tools/gen_compile_commands.py` post kernel build
generates `compile_commands.json`.

This file is created by parsing `.cmd` files to collect all metadata for the
source code.

This script parses `compile_commands.json` to collect all source files into
a list `sourcefile.txt`.

This script takes three arguments:
1. The root path of the Linux repository.
2. The path to the `compile_commands.json` file.
3. The output path for the list of source files.

Usage:
    parse_json.py <linux_repo_root_path> <path_to_compile_commands.json>
                  <output_path_source_file_list>
"""

import json
import os
import argparse


def load_json(file_path):
    """Load a JSON file."""
    with open(file_path, encoding='utf-8') as file:
        return json.load(file)


def find_common_parent(data):
    """Find the common parent directory dynamically."""
    return os.path.commonpath([entry['file'] for entry in data])


def extract_source_files(data, common_parent):
    """Extract .c files with full paths and store them in a list."""
    return [entry['file'].replace(common_parent, '').lstrip('/')
            for entry in data if entry['file'].endswith('.c')]


def write_to_file(file_list, output_file, common_parent, cloned_repo):
    """Write the list of .c files to the output text file."""
    if os.path.exists(output_file):
        print(f"{output_file} already exists and will be overwritten.")
    with open(output_file, 'w', encoding='utf-8') as file:
        for file_path in file_list:
            # Combine with common_parent
            full_path = os.path.join(common_parent, file_path)
            repo_index = full_path.find(cloned_repo)  # fix
            if repo_index != -1:
                relative_path = full_path[repo_index + len(cloned_repo):]
                file.write(relative_path.strip() + '\n')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process and extract C files from compile_commands.json")
    parser.add_argument('cloned_repo_name', type=str, help="clone repo name")
    parser.add_argument('input_file', type=str,
                        help="Path to the compile_commands.json file")
    parser.add_argument('output_file', type=str,
                        help="Path to the output file to save the list of source files")

    args = parser.parse_args()

    input_data = load_json(args.input_file)
    common_roots = find_common_parent(input_data)
    source_files = extract_source_files(input_data, common_roots)
    write_to_file(source_files, args.output_file,
                  common_roots, args.cloned_repo_name)
    print(f"Source files list saved in {args.output_file}", flush=True)
