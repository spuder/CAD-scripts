#!/bin/bash
# https://cameronnokes.com/blog/how-to-convert-heic-image-files-to-jpg-in-bash-on-macos/

set -eu -o pipefail

#TODO: support .PNG and .JPG

# Convert HEIC to JPEG
find ~+ -type f -name "*.HEIC" -print0 | while read -d '' -r file; do 
    echo "Converting $file"
    magick mogrify -monitor -format jpeg "$file"
done

# Copy all .JPEG to 'cropped' folder then resize to 1280x960 for uplading to thingiverse
find ~+ ! -path "*/cropped/*" -type f -name "*.jpeg" -print0 | while read -d '' -r file; do 
    dir=$(dirname "$file")
    base=$(basename "$file" .jpeg)
    mkdir -p "${dir}/cropped" || true
    cp "${dir}/${base}.jpeg" "${dir}/cropped/${base}.jpeg"
    echo "Cropping $dir/cropped/$base.jpeg"
    mogrify -resize 1280x960 "$dir/cropped/$base.jpeg"
done

# Cleanup all HEIC files that were converted to JPEG
find ~+ -type f -name "*.jpeg" -print0 | while read -d '' -r file; do 
    dir=$(dirname "$file")
    base=$(basename "$file" .jpeg)

    echo "Checking if $dir/$base.heic exists"
    if [[ -f "$dir/$base.heic" ]]; then
        echo "Removing previously converted file: $dir/$base.heic"
        rm "$dir/$base.heic"
    fi
done

