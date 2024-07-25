#!/bin/bash
#
# Fetch name email information for linux kernel contributors
set -e

TAG="$1"
git checkout "$TAG"

echo "Starting to generate the email name list ..."
# shellcheck disable=SC2154
git shortlog -e -s -n HEAD > "$curr_dir"/build_data/name_list.txt

# shellcheck disable=SC2154
if [ -s "$curr_dir"/build_data/name_list.txt ]; then
    echo "build_data/name_list.txt created successfully"
else
    echo "build_data/name_list.txt is empty or not created"
fi

echo "Finished generating name list"
