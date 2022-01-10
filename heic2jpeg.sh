#!/bin/bash
# https://cameronnokes.com/blog/how-to-convert-heic-image-files-to-jpg-in-bash-on-macos/

set -eu -o pipefail

docker pull spuder/heic2jpeg:latest
docker volume create --name heic2jpeg-input
INPUT_ID=$(docker run -d -v heic2jpeg-input:/input busybox true)

# Convert HEIC to JPEG
#TODO: support .PNG

find ~+ -type f -name "*.HEIC" -print0 | while read -d '' -r file; do 
    filename=$(basename "$file" ".HEIC")
    dirname=$(dirname "$file")
    echo "Converting $file"
    docker cp "${file}" "${INPUT_ID}:/input/${filename}.HEIC"
    docker run --rm -v heic2jpeg-input:/input dpokidov/imagemagick "/input/${filename}.HEIC" -format jpeg "/input/${filename}.jpeg"
    docker cp ${INPUT_ID}:/input/${filename}.jpeg ${dirname}/${filename}.jpeg
done

# Copy all .JPEG to 'cropped' folder then resize to 1280x960 for uplading to thingiverse
find ~+ ! -path "*/cropped/*" -type f \( -iname "*.jpeg" -o -iname "*.jpg" \) -print0 | while read -d '' -r file; do 
    dir=$(dirname "$file")
    filename=$(basename "$file")
    mkdir -p "${dir}/cropped"
    echo "Cropping $dir/cropped/$filename"
    docker cp "${dir}/${filename}"  "${INPUT_ID}:/input/${filename}"
    docker run --rm -v heic2jpeg-input:/input dpokidov/imagemagick "/input/$filename" -resize 1280x960 "/input/${filename}-cropped.jpeg"
    docker cp "${INPUT_ID}:/input/${filename}-cropped.jpeg" "${dir}/cropped/${filename}"
done

# Cleanup all HEIC files that were converted to JPEG
find ~+ -type f \( -iname "*.jpeg" -o -iname "*.jpg" \) -print0 | while read -d '' -r file; do 
    dir=$(dirname "$file")
    if [[ "$file" == *".jpeg" ]]; then
        base=$(basename "$file" .jpeg)
    else
        base=$(basename "$file" .jpg)
    fi
    echo "Checking if $dir/$base.heic exists"
    if [[ -f "$dir/$base.heic" ]]; then
        echo "Removing previously converted file: $dir/$base.heic"
        rm "$dir/$base.heic"
    fi
done

docker rm $INPUT_ID
docker volume rm heic2jpeg-input