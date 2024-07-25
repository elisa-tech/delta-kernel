# Change-impact-analysis Tool

The Change Impact Analysis Tool generates a comprehensive visual report detailing changes in both header files and source code between two Linux versions (tags in the Linux kernel repository: old_tag and new_tag). This tool helps developers view updates from the old version.

The diff report includes a subset of files from the Linux repository that are included in building the kernel, contributing to a focused and detailed report on the compile-time source code in Linux.

## Table of Content

- [How to Use](#how-to-use)
- [Files Generated](#files-generated)
- [Structure of the Tool](#structure-of-the-tool)
  - [I. Compilation File List Generation](#i-compilation-file-list-generation)
  - [II. Git Diff Report Generation](#ii-git-diff-report-generation)
  - [III. Commit Metadata Retrieval](#iii-commit-metadata-retrieval)
  - [IV. Web Script Generation](#iv-web-script-generation)

## How to use

To utilize this tool in your Linux environment (compatible with Ubuntu and Debian), follow these steps:

Clone the repository:

```bash
git clone <repository_url>
```

Navigate to the cloned repository:

```bash
cd <repository_directory>
```

Execute the tool by specifying the old and new tags:

```bash
./run_tool.sh <tag1> <tag2> [-c clone_path] [-u repo_link] [-s subsystem]
```
- `<tag1>`: Specifies the old version tag.
- `<tag2>`: Specifies the new version tag.
- `-c <clone_path>`: Optional. Defines the user-specified path to clone the Linux source code repository.
- `-u <repo_link>`: Optional. Provides the URL for the Linux source code repository.
- `-s <subsystem>`: Optional. Specifies the subsystem for analysis (e.g., -s security).

## Files Generated

**/build_data:**

- `sourcefile.txt` - List of all built source code files
- `headerfile.txt` - List of all built dependency files
- `git_diff_sourcefile.txt` - Git diff report for source code files
- `git_diff_headerfile.txt` - Git diff report for dependency files
- `tokenize_header.json` - Metadata for commit git diff for dependency files
- `tokenize_source.json` - Metadata for commit git diff for source files

**/web_source_codes:**

- `index.html` - Click on to view the result

## Structure of the Tool

The tool operates through a structured process to generate a comprehensive change impact analysis report. Here's a detailed breakdown of its operation:

### I. Compilation File List Generation

#### Header File

During linux kernel compilation, `Makefile.build` calls `$K/scripts/basic/fixdep.c` to generate a .cmd file for each source that collects dependency information during compilation.

This tool incorporates a modification that applies a patch (`patch.file`) to `scripts/basic/fixdep.c`, enabling it to output dependency information into a **list of header files** when building the kernel.

#### Source code

This tool leverages the `$K/scripts/clang-tools/gen_compile_commands.py` script to generate a `compile_commands.json` file. This file documents all source files involved in the compilation process. The `gen_compile_commands.py` script traverses each `.cmd` file to aggregate the list of source files.

Then, the tool invokes `parse_json.py` to parse `compile_commands.json`, generating **a list of source files**.

### II. Git Diff Report Generation

Using the file lists, the tool generates 2 separate git diff reports (dependency diff report & source diff report) for updates from **old_tag** to **new_tag**.

### III. Commit Metadata Retrieval

Based on the git diff reports, the tool retrieves commit metadata for each newly added line in the reports.

- **Tokenization**: If multiple commits modify a single line between two tags, the tool breaks down each commit line into smaller parts and associates commit information with relevant tokens. The results after tokenization are stored in JSON files.

### IV. Web Script Generation

Using the git diff reports and metadata stored in JSON files, the tool generates a web report displaying the changes.

The web report contains three source html:

- `index.html`: with on-click directions to:
  - `sourcecode.html`: renders the content in source diff report, with embedded url and on-hover metadata box for each newly added lines/tokens in new_tag.
  - `header.html`: renders teh content in dependency diff report, with embedded url and on-hover metadata box for each newly added lines/tokens in new_tag.
