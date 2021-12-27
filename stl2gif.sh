find ~+ -type f -name "*.stl" -print0 | while read -d '' -r file; do 
	echo "Reading $file"
    MYTMPDIR="$(mktemp -d)"
    trap 'rm -rf -- "$MYTMPDIR"' EXIT

    echo "Creating temp directory ${MYTMPDIR}"

    #TODO: replace with spuder/openscad docker container
    /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD /dev/null -D '$vpr = [60, 0, 360 * $t];' -o "${MYTMPDIR}/foo.png"  -D "import(\"$file\");" --imgsize=300,300 --animate 60 --colorscheme "Tomorrow Night" --viewall --autocenter

    #TODO: replace with docker container
    yes | ffmpeg \
        -framerate 12 \
        -pattern_type glob \
        -i "$MYTMPDIR/*.png" \
        -r 24 \
        -vf scale=512:-1 \
        "${file}.gif" \
        ;
    rm -rf -- "$MYTMPDIR"
done
