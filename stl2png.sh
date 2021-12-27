#!/bin/bash

if [ -z "$(docker --version)" ]; then
	echo "Docker is not installed. Please install docker before running this script."
	exit 1
fi
echo "Updating docker container"
docker pull spuder/openscad:latest

find ~+ -type f -name "*.stl" -print0 | while read -d '' -r file; do 
	echo "Reading $file"
	# /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD /dev/null -D "import(\"$file\");" -o "$file.png" --imgsize=600,600 --colorscheme "Tomorrow Night" --viewall --autocenter
	filename=$(basename "$file")
	echo "Basename: $filename"
	docker run --rm -v $(PWD):/data spuder/openscad:latest openscad /dev/null -o "/data/CAD/$filename.png" -D "import(\"/data/CAD/$filename\");" --imgsize=600,600 --colorscheme "Tomorrow Night" --autocenter --viewall
done