#!/bin/sh

if [ $# -eq 0 ]; then
    echo "Missing argument directory"
    exit 1
fi

if [ $# -eq 1 ]; then
    echo "Missing argument search string"
    exit 1
fi

filesdir=$1
searchstr=$2

if [ ! -d $filesdir ]; then
    echo "Expected first argument to be a directory"
    exit 1
fi

files_in_directory=$(find "$filesdir" -type f)
num_files=$(echo "$files_in_directory" | wc -w)
total_num_matches=0

for file in $files_in_directory; do
    num_matches=$(grep -ow "$searchstr" "$file" | wc -l)
    total_num_matches=$((total_num_matches+num_matches))
done

echo "The number of files are $num_files and the number of matching lines are $total_num_matches"

