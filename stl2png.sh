#!/bin/bash
set -u
if [ -z "$(docker --version)" ]; then
	echo "Docker is not installed. Please install docker before running this script."
	exit 1
fi
echo "Updating docker container"
docker pull openscad/openscad:2021.01

find ~+ -type f -name "*.stl" -print0 | while read -d '' -r file; do 
	echo "Converting ${file} to .PNG"
	filename=$(basename "${file}" ".stl")
	dirname=$(dirname "${file}")
	docker run --init \
		-v "${dirname}:/input" \
		-v "${dirname}:/output" \
		openscad/openscad:2021.01 xvfb-run -a openscad /dev/null -o "/output/${filename}.png" -D "import(\"/input/${filename}.stl\");" --imgsize=600,600 --colorscheme "Tomorrow Night" --autocenter --viewall
done