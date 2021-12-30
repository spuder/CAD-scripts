#!/bin/bash

set -u
docker pull spuder/stl2origin:latest

find ~+ -type f -name "*.stl" -print0 | while read -d '' -r file; do 

    echo "Reading $file"
    MYTMPDIR="$(mktemp -d)"
    trap 'rm -rf -- "$MYTMPDIR"' EXIT

    echo "Creating temp directory ${MYTMPDIR}"

    # Detect how offcenter STL file is. Save variable output to foo.sh ($XTRANS, $YTRANS, $ZTRANS)
    echo "Centering the STL file ${file}"
    docker run \
        -e OUTPUT_BASH_FILE=/output/foo.sh \
        -v $(dirname "$file"):/input \
        -v $MYTMPDIR:/output \
        --rm spuder/stl2origin:latest \
        "/input/$(basename "$file")"
    cp "${file}" "$MYTMPDIR/foo.stl"
    source $MYTMPDIR/foo.sh
    cat $MYTMPDIR/foo.sh
    # Create new (temporary) STL that has been centered
    docker run \
        -v "$MYTMPDIR:/input" \
        -v "$MYTMPDIR:/output" \
        openscad/openscad:2021.01 openscad /dev/null -D "translate([$XTRANS-$XMID,$YTRANS-$YMID,$ZTRANS-$ZMID])import(\"/input/foo.stl\");" -o "/output/foo-centered.stl"

    #TODO: replace with openscad/openscad docker container
    # https://github.com/openscad/openscad/issues/4028
    /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD /dev/null \
        -D '$vpr = [60, 0, 360 * $t];' \
        -o "${MYTMPDIR}/foo.png"  \
        -D "import(\"${MYTMPDIR}/foo-centered.stl\");" \
        --imgsize=600,600 \
        --animate 60 \
        --colorscheme "Tomorrow Night" \
        --viewall --autocenter \
        --preview \
        --quiet

    #TODO: replace with docker container
    yes | ffmpeg \
        -framerate 15 \
        -pattern_type glob \
        -i "${MYTMPDIR}/*.png" \
        -r 25 \
        -vf scale=512:-1 \
        "${file}.gif" \
        ;
    rm -rf -- "${MYTMPDIR}"
done
