# DeltaKernel Change Impact Analysis Tool

## Table of Content

- [Introduction](#introduction)
- [Innovation](#innovation)
- [How to Use](#how-to-use)
- [Intermediate Files Generated](#intermediate-files-generated)
- [Operational Stages of the Tool](#operational-stages-of-the-tool)
  - [I. Compilation File List Generation](#i-compilation-file-list-generation)
  - [II. Git Diff Report Generation](#ii-git-diff-report-generation)
  - [III. Commit Metadata Retrieval](#iii-commit-metadata-retrieval)
  - [IV. Web Script Generation](#iv-web-script-generation)

## Introduction

DeltaKernel Change Impact Analysis Tool generates a visual report detailing changes in both header files and source code between two Linux kernel versions (tags in the Linux kernel repository: old_tag and new_tag). This tool helps developers compare updates between versions.

The diff report includes a subset of files from the Linux kernel repository that are included in building the kernel, contributing to a focused and detailed report on the compile-time source code in Linux.

## Innovation

The idea of generating a web display for Linux kernel version change impact analysis is inspired by [Cregit](https://github.com/cregit/cregit). This tool improves on Cregit by:

- The tool performs a version analysis between two tags to identify updated files, similar to git diff, but focuses only on files used to compile the kernel rather than the entire Linux source code.

- Generating not only web source files but also lists of all source files and dependencies/header files used in kernel compilation, facilitating additional analysis purposes. (More details in [Intermediate Files Generated](#intermediate-files-generated))
- Enabling comparison between two specific tags/releases in the Linux kernel, highlighting all newly added and deleted lines. This provides a clear layout of differences between the tags. While Cregit organizes information by files and embeds the latest commit details in each line/token, it does not support direct comparison between two tags.
- User customization: allows users to define the URL of the Linux kernel repository and specify the specific subsystem for analysis. (More details in [How to Use](#how-to-use))
- Kernel Configuration: The linux kernel is configured with `make olddefconfig` in `build_scripts/build_collect_diff`: Updates the configuration using the existing `.config` file and applies default values for new options.

## How to use

To utilize this tool in your Linux environment (tested successfully on `Ubuntu 22.04`), follow these steps:

**Clone the repository**:

```bash
git clone <repository_url>
```

**Navigate to the cloned repository**:

```bash
cd <repository_directory>
```

**Execute the tool by specifying the old and new tags**:

```bash
./run_tool <tag1> <tag2> [-c clone_path] [-u repo_link] [-s subsystem]
```

**Example Usage**:

```bash
./run_tool "v5.15" "v5.15.100" -c "linux" -u "https://github.com/torvalds/linux" -s "security"
# the tool will generate web update report on linux kernel v5.15.100 from v5.15 for security subsystem.
cd web_source_code # click on index.html to view the result 
```

**Command Line Arguments**:

- `<tag1>`: Specifies the old version tag.
- `<tag2>`: Specifies the new version tag.
- `s <subsystem>`: Specifies the subsystem for analysis (e.g., -s security). Limited to one kernel subsystem folder at a time.
- `c <clone_name>`: Optional. Defines the user-specified repo name to clone the Linux source code repository. Default is linux.
- `u <repo_link>`: Optional. Provides the URL for the Linux source code repository.

**What the Tool Does**:

- Clones the Linux repository from `repo_link` to `linux`.
- Checks out `tag1` and applies `fixdep-patch.file`.
- Configures and compiles the kernel.
- Collects compile-time source files list and dependency files list.
- Generates diff reports based on the file lists.
- Retrieves git metadata for each file inside the lists.
- After execution, `linux` will be in the branch of `tag2`.

If a runtime git conflict is encountered, resolve it with the following steps:

```bash
cd linux # or user-defined clone name
git reset --hard
git checkout master
cd .. # return to delta-kernel
./run_tool # the cloned repository will not be re-cloned
```

**Git Clean Up (Optional)**:

```bash
rm -r linux  # or how you named the cloned dir
```

## Intermediate Files Generated

**/build_data:**

The folder is only cleared at the start of the script execution so that the intermediate files are available after building.

- `sourcefile.txt` - List of all built source code files
- `headerfile.txt` - List of all built dependency files
- `git_diff_sourcefile.txt` - Git diff report for source code files
- `git_diff_headerfile.txt` - Git diff report for dependency files
- `tokenize_header.json` - Metadata for commit git diff for dependency files
- `tokenize_source.json` - Metadata for commit git diff for source files

## Operational Stages of the Tool

The tool operates through the following sequence when generating a change impact analysis report. Here's a detailed breakdown of the steps:

### I. Compilation File List Generation

#### Header File

During linux kernel compilation, `Makefile.build` calls `$K/scripts/basic/fixdep.c` to generate a .cmd file for each source that collects dependency information during compilation.

The `scripts/basic/fixdep.c` file generates a `.cmd` file containing dependency information for each source file that the kernel compiles. This tool includes a modification that applies a patch (fixdep-patch.file) to `fixdep.c`, enabling it to collect dependency files for each source file and output a comprehensive list of all source files and their dependencies for the entire kernel compilation. The resulting `dependency_list.txt`` is generated after kernel compilation.

#### Source code

This tool leverages the `$K/scripts/clang-tools/gen_compile_commands` script to generate a `compile_commands.json` file. This file documents all source files involved in the compilation process. The `gen_compile_commands` script traverses each `.cmd` file to aggregate the list of source files.

Then, the tool invokes `parse_json` to parse `compile_commands.json`, generating **a list of source files**.

### II. Git Diff Report Generation

Using the file lists, the tool generates 2 separate git diff reports (dependency diff report & source diff report) for updates from **old_tag** to **new_tag**.

### III. Commit Metadata Retrieval

Based on the git diff reports, the tool retrieves commit metadata for each newly added line in the reports.

- **Tokenization**: If multiple commits modify a single line between two tags, the tool breaks down each commit line into smaller parts and associates commit information with relevant tokens. The results after tokenization are stored in JSON files.

### IV. Web Script Generation

Using the git diff reports and metadata stored in JSON files, the tool generates a web report displaying the changes.

The web report contains three html files:

- `index.html`: with on-click directions to:
  - `sourcecode.html`: renders the content in source diff report, with embedded url and on-hover metadata box for each newly added lines/tokens in new_tag.
  - `header.html`: renders teh content in dependency diff report, with embedded url and on-hover metadata box for each newly added lines/tokens in new_tag.
