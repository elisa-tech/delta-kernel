"""
This script parses a git diff report, fetches commit details, and tokenizes the results.

This script takes three arguments:
1. The path to `git_diff_report.txt`.
2. The path to an intermediate file for storing diff information.
3. The path to the output file for storing the tokenized results.

Usage:
    tokenize.py <git_diff_report_path> <intermediate_file_path> <output_file_path>
"""

import subprocess
import re
import json
import argparse
from datetime import datetime

CHUNK_HEADER_PATTERN = r'^@@ -\d+,\d+ \+(\d+),\d+ @@'
COMMIT_REGEX = r'^commit ([0-9a-f]{40})$'
AUTHOR_REGEX = r'^Author: (.+)$'
DATE_REGEX = r'^Date:\s+(.+)$'
OBJECT_ID_REGEX = r'^@@ -\d+,\d+ \+(?P<n3>\d+),(?P<n4>\d+) @@'
diff_info = {}


def run_command(arguments):
    """Run git command in python."""
    result = subprocess.run(arguments, capture_output=True,
                            text=True, check=True)

    return result.stdout


def parse(git_dif_path):
    """Parse git diff report."""
    added_lines_parse = {}
    start_file_content = True
    line_number = 0

    with open(git_dif_path, 'r', encoding='utf-8') as git_diff_report:

        # Parse the git diff report
        current_file = None
        for line in git_diff_report:
            if line.startswith('Diff for '):
                start_file_content = False
                current_file = line.split(' ')[2][:-1]  # get rid of \n
                added_lines_parse[current_file] = []

            if start_file_content and not line.startswith('-'):
                line_number += 1

            if current_file and re.search(CHUNK_HEADER_PATTERN, line):
                # Extract line number from @@ -983,14 +983,19 @@
                match = re.search(CHUNK_HEADER_PATTERN, line)
                start_file_content = True
                line_number = int(match.group(1)) - 1

            if start_file_content and line.startswith('+'):
                added_lines_parse[current_file].append(line_number)

    return added_lines_parse


def get_log_line(tag1, tag2, line_num, file_path, git_blame):
    """Get all log line report for each line."""
    if git_blame:
        command = ['git', 'blame', '-L', f'{line_num},{line_num}', file_path]
    else:
        command = ['git', 'log', f'{tag1}..{tag2}',
                   f'-L{line_num},{line_num}:{file_path}']
    log_commit_info = run_command(command)
    return log_commit_info.splitlines()  # Split the output into lines


def parse_blame_line(blame_line):
    """Parse blame line to retrieve commit metadata."""
    # Regular expression to match the blame line
    if blame_line[0] == '^':
        blame_line = blame_line[1:]

    regex = r'^([0-9a-f]+) \(([^)]+) (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4})' \
        r'\s+\d+\)\s?(.*)$'

    match = re.match(regex, blame_line)
    if match:
        commit_hash = match.group(1)
        author_name = match.group(2)
        date = match.group(3)
        line_content = match.group(4) if match.group(4) else ""
        return {
            "Commit_Hash": commit_hash,
            "Author": author_name,
            "Date": date,
            "Line": line_content
        }

    return None


def parse_git_add(added_lines_parse):
    """Parse git add info."""
    print("Inside parse git add", flush=True)

    for file, line_nums in added_lines_parse.items():
        diff_info[file] = {}
        print(f"Parsing git line info in file: {file}", flush=True)
        for line_num in line_nums:
            log_commit_info = get_log_line(TAG1, TAG2, line_num, file, False)

            if len(log_commit_info) == 0:  # need to use git blame retrieve all commit history
                log_commit_info = get_log_line(
                    TAG1, TAG2, line_num, file, True)
                diff_info.setdefault(file, {}).setdefault(
                    line_num, []).append(parse_blame_line(log_commit_info[0]))

            else:
                process_commit_info(log_commit_info, file, line_num)


def process_commit_info(lines, file, line_num):
    """Process commit info."""
    cnt = -1
    line_cnt = 0
    for line in lines:
        if re.match(COMMIT_REGEX, line):
            cnt += 1
            current_commit = re.match(COMMIT_REGEX, line).group(1)
            diff_info.setdefault(file, {}).setdefault(line_num, []).append({
                'Author': '',
                'Date': '',
                'Commit_Hash': current_commit,
                'Line': ''
            })

        elif re.match(AUTHOR_REGEX, line):
            diff_info[file][line_num][cnt]['Author'] = re.match(
                AUTHOR_REGEX, line).group(1)

        elif re.match(DATE_REGEX, line):
            diff_info[file][line_num][cnt]['Date'] = re.match(
                DATE_REGEX, line).group(1)

        elif re.search(OBJECT_ID_REGEX, line):
            i = 1
            match = re.search(OBJECT_ID_REGEX, line)
            max_cnt = int(match.group('n4'))
            start_line = int(match.group('n3')) - 1
            add_cnt = 1
            while add_cnt <= max_cnt:
                next_line = lines[i + line_cnt]
                if next_line[0] != '-':
                    add_cnt += 1
                    start_line += 1
                if next_line[0] == '+' and start_line == line_num:
                    diff_info[file][line_num][cnt]['Line'] = next_line
                i += 1

        line_cnt += 1


def tokenize(json_path, output_json_path):
    """Tokenize git added line with relevant commit message."""
    result_data = {}
    with open(json_path, encoding='utf-8') as git_history_file:
        data = json.load(git_history_file)

    for file_name in data:
        if file_name not in result_data:
            result_data[file_name] = {}

        for line_num in data[file_name]:
            commit_list = data[file_name][line_num]
            result_data[file_name][line_num] = {}

            try:
                result_data[file_name][line_num]["root_line"] = commit_list[0]["Line"]
            except (TypeError, KeyError) as exception:
                # Parsing Error
                print(f"Error accessing commit_list: {exception}", flush=True)
                continue

            if len(commit_list) > 1:

                result_data[file_name][line_num]["tokenization"] = highlight_substring(
                    commit_list)
            else:
                result_data[file_name][line_num]["tokenization"] = [
                    {
                        "token": commit_list[0]["Line"],
                        "meta": {
                            "commit_hash": commit_list[0]["Commit_Hash"],
                            "author_name": parse_author(commit_list[0]["Author"])[0],
                            "email": parse_author(commit_list[0]["Author"])[1],
                            "time": format_date(commit_list[0]["Date"])
                        }
                    }
                ]

    with open(output_json_path, 'w', encoding='utf-8') as json_output_file:
        json.dump(result_data, json_output_file, ensure_ascii=False, indent=4)


def parse_author(author):
    """Parse author string to extract name and email."""
    match = re.match(r'^(.*)\s*<([^>]+)>$', author)
    if match:
        return [match.group(1).strip(), match.group(2).strip()]
    return [author, "None"]


def format_date(date_str):
    """Format date to 'YYYY-MM-DD HH:MM:SS'."""
    # Define possible date formats
    formats = [
        '%a %b %d %H:%M:%S %Y %z',  # Format: 'Wed Jan 19 18:08:56 2022 -0800'
        '%Y-%m-%d %H:%M:%S %z'       # Format: '2022-01-19 18:08:56 -0800'
    ]

    # Try to parse the date string with the defined formats
    for date_format in formats:
        try:
            date_obj = datetime.strptime(date_str, date_format)
            return date_obj.strftime('%Y-%m-%d %H:%M:%S')
        except ValueError:
            continue  # Try the next format if current one fails

    # If none of the formats match, raise an error
    raise ValueError(f"Date format not recognized: {date_str}")


def highlight_substring(commit_list):
    """Produce tokenized JSON with highlighted substrings based on overlap."""
    # Retrieve lines info for string parsing
    root_line, child_line = commit_list[0]["Line"], commit_list[1]["Line"]
    root_length, child_length = len(root_line), len(child_line)

    # Retrieve other meta info for lines
    meta_root = {
        "commit_hash": commit_list[0]["Commit_Hash"],
        "author_name": parse_author(commit_list[0]["Author"])[0],
        "email": parse_author(commit_list[0]["Author"])[1],
        "time": format_date(commit_list[0]["Date"])
    }

    meta_child = {
        "commit_hash": commit_list[1]["Commit_Hash"],
        "author_name": parse_author(commit_list[1]["Author"])[0],
        "email": parse_author(commit_list[1]["Author"])[1],
        "time": format_date(commit_list[1]["Date"])
    }

    # Return val
    segments = []

    # Find overlap at the start
    start_idx = 0
    for i in range(min(root_length, child_length)):
        if root_line[i] != child_line[i]:
            break
        start_idx = i + 1

    # Find overlap at the end
    end_idx = 0
    for i in range(1, min(root_length, child_length) + 1):
        if root_line[-i] != child_line[-i]:
            break
        end_idx = i

    start_overlap = root_line[:start_idx]
    end_overlap = root_line[-end_idx:] if end_idx > 0 else ""
    mid_segment = root_line[start_idx:root_length -
                            end_idx] if start_idx < root_length - end_idx else ""

    # Case 1: start + mid + end
    if start_overlap and end_overlap and mid_segment:
        segments.append({"token": start_overlap, "meta": meta_child})
        segments.append({"token": mid_segment, "meta": meta_root})
        segments.append({"token": end_overlap, "meta": meta_child})

    # Case 2: start + end (mid is empty)
    elif start_overlap and not mid_segment and end_overlap:
        segments.append({"token": start_overlap, "meta": meta_child})
        segments.append({"token": end_overlap, "meta": meta_child})

    # Case 3: mid + end (start is empty)
    elif not start_overlap and mid_segment and end_overlap:
        segments.append({"token": mid_segment, "meta": meta_root})
        segments.append({"token": end_overlap, "meta": meta_child})
    # Case 4: no overlap
    else:
        segments.append({"token": root_line, "meta": meta_root})

    return segments


# Main execution
if __name__ == '__main__':
    # Parse arguments
    parser = argparse.ArgumentParser(description='Process some files.')
    parser.add_argument('git_diff_report', type=str,
                        help='Path to git_diff_report.txt')
    parser.add_argument('intermediate_file', type=str,
                        help='Path to intermediate_file')
    parser.add_argument('output_file', type=str, help='Path to output_file')
    parser.add_argument('tag1', type=str, help='old version tag')
    parser.add_argument('tag2', type=str, help='new verison tag')

    args = parser.parse_args()

    git_diff_report_path = args.git_diff_report
    intermediate_file_path = args.intermediate_file
    output_file_path = args.output_file
    TAG1 = args.tag1
    TAG2 = args.tag2

    # Identify all the (line number in git diff report)
    added_lines = parse(git_diff_report_path)

    # Retrieve git report
    parse_git_add(added_lines)

    with open(intermediate_file_path, 'w', encoding='utf-8') as the_file:
        json.dump(diff_info, the_file, indent=4)
    print(f"Diff info stored in {intermediate_file_path}")

    # Tokenize
    print("starting tokenize function test", flush=True)
    tokenize(intermediate_file_path, output_file_path)
    print("Result exported to tokenize.json", flush=True)
