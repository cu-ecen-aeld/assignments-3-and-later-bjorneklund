#!/bin/sh

if [ $# -eq 0 ]; then
    echo "Missing argument filepath"
    exit 1
fi

if [ $# -eq 1 ]; then
    echo "Missing text to insert to file"
    exit 1
fi

filepath=$1
writestr=$2
dirpath=$(dirname "$filepath")


if [ ! -d "$dirpath" ]; then
    #directory does not exist
    mkdir -p "$dirpath"    
fi


if [ -e "$filepath" ]; then
    #file exist, remove it
    rm "$filepath"
fi

echo "$writestr" > "$filepath"

if [ $? -ne 0 ]; then  
    #file could not be created
    echo "Could not create $filepath"
    exit 1
fi
