#!/bin/bash

set -ue
if [ -z "$(docker --version)" ]; then
	echo "Docker is not installed. Please install docker before running this script."
	exit 1
fi
docker pull spuder/stl2origin:latest
docker pull linuxserver/ffmpeg:version-4.4-cli
docker pull openscad/openscad:2021.01

find ~+ -type f -name "*.stl" -print0 | while read -d '' -r file; do 

    filename=$(basename "$file" ".stl")
    dirname=$(dirname "$file")
    echo "Reading $file"
    MYTMPDIR="$(mktemp -d)"
    trap 'rm -rf -- "$MYTMPDIR"' EXIT
    echo "Creating temp directory ${MYTMPDIR}"

    # Detect how offcenter STL file is. Save variable output to foo.sh ($XTRANS, $YTRANS, $ZTRANS)
    echo ""
    echo "Detecting ${filename} offset from origin"
    echo "========================================"
    docker run \
        -e OUTPUT_BASH_FILE=/output/foo.sh \
        -v $(dirname "$file"):/input \
        -v $MYTMPDIR:/output \
        --rm spuder/stl2origin:latest \
        "/input/$(basename "$file")"
    cp "${file}" "$MYTMPDIR/foo.stl"
    source $MYTMPDIR/foo.sh
    cat $MYTMPDIR/foo.sh

    echo ""
    echo "Duplicating ${filename} and centering object at origin"
    echo "======================================================"
    docker run \
        -v "$MYTMPDIR:/input" \
        -v "$MYTMPDIR:/output" \
        openscad/openscad:2021.01 openscad /dev/null -D "translate([$XTRANS-$XMID,$YTRANS-$YMID,$ZTRANS-$ZMID])import(\"/input/foo.stl\");" -o "/output/foo-centered.stl"

    # Take temporary (centered) stl and create collection of .png images to be animated
    # TODO: move to docker once opengl issue is solved
    # https://github.com/openscad/openscad/issues/4028
    # This solution is very fast, but is not portable. 
    # Check if openscad is in path
    echo ""
    echo "Converting ${filename} into 360 degree .png files"
    echo "=================================================="
    openscad_path=""
    if [ ! -z "$(which openscad)" ]; then
        openscad_path=$(which openscad)
    elif [ -f "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]; then
        openscad_path='/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD'
    else
        echo "OpenSCAD is not installed. Please install openscad before running this script."
        exit 1
    fi
    $openscad_path /dev/null \
        -D '$vpr = [60, 0, 360 * $t];' \
        -o "${MYTMPDIR}/foo.png"  \
        -D "import(\"${MYTMPDIR}/foo-centered.stl\");" \
        --imgsize=600,600 \
        --animate 60 \
        --colorscheme "Tomorrow Night" \
        --viewall --autocenter \
        --preview \
        --quiet

    # This solution works but is very slow and has some glitches
    # for ((angle=0; angle <=360; angle+=5)); do
    #     echo "Rendering $angle"
    #     ls $MYTMPDIR
    #     # openscad /dev/null -o dump$angle.png  -D "cube([2,3,4]);" --imgsize=250,250 --camera=0,0,0,45,0,$angle,25
    #     docker run \
    #         -v "$MYTMPDIR:/input" \
    #         -v "$MYTMPDIR:/output" \
    #         --init \
    #         openscad/openscad:2021.01 xvfb-run -a openscad /dev/null -D "\$vpr = [60, 0, ${angle}];" -D 'import("/input/foo-centered.stl");' -o "/output/bar${angle}.png" --imgsize=600,600 --autocenter --viewall --quiet
    # done

    # This solution crashes after 4 annimations. 40+ hours of debugging and I haven't found a solution yet
    # https://github.com/openscad/openscad/issues/4028
    # docker run --init --gpus all \
	# 	-v "${dirname}:/input" \
	# 	-v "${MYTMPDIR}:/output" \
	# 	openscad/openscad:2021.01 xvfb-run -a openscad "/input/foo.scad" -o "/output/foo.png" --animate 60
    # ls $MYTMPDIR
    echo ""
    echo "Converting ${filename} .PNG files into .GIF"
    echo "==========================================="
    docker run --rm \
        -v "${MYTMPDIR}:/input" \
        -v "${dirname}:/output" \
        linuxserver/ffmpeg:version-4.4-cli -y -framerate 15 -pattern_type glob -i 'input/*.png' -r 25 -vf scale=512:-1 "/output/${filename}.gif";
    ls "${MYTMPDIR}"
    echo ""
    echo "Cleaning up temp directory ${MYTMPDIR}"
    echo "======================================"
    rm -rf -- "${MYTMPDIR}"
done
