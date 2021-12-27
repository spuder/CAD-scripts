#!/bin/bash
# https://cameronnokes.com/blog/how-to-convert-heic-image-files-to-jpg-in-bash-on-macos/

set -eu -o pipefail

find ~+ -type f -name "*.HEIC" -print0 | while read -d '' -r file; do 
    echo "Converting $file"
    magick mogrify -monitor -format jpeg "$file"
done


find ~+ -type f -name "*.jpeg" -print0 | while read -d '' -r file; do 
    dir=$(dirname "$file")
    base=$(basename "$file" .jpeg)

    echo "Checking if $dir/$base.heic exists"
    if [[ -f "$dir/$base.heic" ]]; then
        echo "Removing previously converted file: $dir/$base.heic"
        rm "$dir/$base.heic"
    fi
done

