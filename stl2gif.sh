#!/bin/bash

set -ue
if [ -z "$(docker --version)" ]; then
	echo "Docker is not installed. Please install docker before running this script."
	exit 1
fi
docker pull spuder/stl2origin:latest
docker pull linuxserver/ffmpeg:version-4.4-cli
docker pull openscad/openscad:2021.01

echo "Creating temporary docker volumes stl2gif-input and stl2gif-output"
docker volume create --name stl2gif-input
INPUT_ID=$(docker run -d -v stl2gif-input:/input busybox true)
docker volume create --name stl2gif-output
OUTPUT_ID=$(docker run -d -v stl2gif-output:/output busybox true)

find ~+ -type f -name "*.stl" -print0 | while read -d '' -r file; do 

    filename=$(basename "$file" ".stl")
    dirname=$(dirname "$file")
    echo "Reading $file"
    MYTMPDIR="$(mktemp -d)"
    trap 'rm -rf -- "$MYTMPDIR"' EXIT
    echo "Creating temp directory ${MYTMPDIR}"

    echo "Copying ${filename}.stl to stl2gif-input docker volume"
	docker cp "${dirname}/${filename}.stl" "${INPUT_ID}:/input/${filename}.stl"

    # Detect how offcenter STL file is. Save variable output to foo.sh ($XTRANS, $YTRANS, $ZTRANS)
    echo ""
    echo "Detecting ${filename} offset from origin"
    echo "========================================"

    docker run \
        -e OUTPUT_STDOUT=true \
        -e OUTPUT_BASH_FILE=/output/foo.sh \
        -v stl2gif-input:/input \
        -v stl2gif-output:/output \
        --rm spuder/stl2origin:latest \
        "/input/${filename}.stl"

	docker cp "${OUTPUT_ID}:/output/foo.sh" "${MYTMPDIR}/foo.sh"

    # cp "${file}" "$MYTMPDIR/foo.stl"
    source $MYTMPDIR/foo.sh
    cat ${MYTMPDIR}/foo.sh
    # cat $MYTMPDIR/foo.sh

    echo ""
    echo "Duplicating ${filename} and centering object at origin"
    echo "======================================================"
    docker run \
        --rm \
        -v stl2gif-input:/input \
        -v stl2gif-output:/output \
        openscad/openscad:2021.01 openscad /dev/null -D "translate([$XTRANS-$XMID,$YTRANS-$YMID,$ZTRANS-$ZMID])import(\"/input/${filename}.stl\");" -o "/output/foo-centered.stl"
    docker cp "${OUTPUT_ID}:/output/foo-centered.stl" "${MYTMPDIR}/foo-centered.stl"
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
    # Check openscad version is 2020.01 or later
    openscad_version=$($openscad_path -v 2>&1 | grep -o '\d\d\d\d')
    if [ "$openscad_version" -lt "2021" ]; then
        echo "OpenSCAD 2021.01 or later is required to run this script. Please update openscad before running this script."
        exit 1
    fi

    # vpd defines how far away the camera is. If the camera is too close, increase the value to zoom out
    # use x+y+z as a quick and dirty way to dynamically set the zoom
    # it is likely that this value will need to be tweaked. 
    $openscad_path /dev/null \
        -D '$vpr = [60, 0, 360 * $t];' \
        -D "\$vpd = ${XSIZE}+${YSIZE}+${ZSIZE};" \
        -o "${MYTMPDIR}/foo.png"  \
        -D "import(\"${MYTMPDIR}/foo-centered.stl\");" \
        --imgsize=600,600 \
        --animate 60 \
        --colorscheme "Tomorrow Night" \
        --viewall \
        --autocenter \
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
    echo "Copying .png files to docker volume"
    find ${MYTMPDIR} -type f -name "*.png" -print0 | while read -d '' -r file; do 
        docker cp "${file}" "${INPUT_ID}:/input/" 
    done

    echo ""
    echo "Converting ${filename} .PNG files into .GIF"
    echo "==========================================="
    docker run --rm \
        -v stl2gif-input:/input \
        -v stl2gif-output:/output \
        linuxserver/ffmpeg:version-4.4-cli -y -framerate 15 -pattern_type glob -i 'input/*.png' -r 25 -vf scale=512:-1 "/output/${filename}.gif";
    docker cp "${OUTPUT_ID}:/output/${filename}.gif" "${dirname}/${filename}.gif"
    ls "${MYTMPDIR}"
    echo ""
    echo "Cleaning up temp directory ${MYTMPDIR}"
    echo "======================================"
    rm -rf -- "${MYTMPDIR}"
done

docker rm $INPUT_ID
docker rm $OUTPUT_ID
docker volume rm stl2gif-input
docker volume rm stl2gif-output