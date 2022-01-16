#!/bin/bash
set -u
if [ -z "$(docker --version)" ]; then
	echo "Docker is not installed. Please install docker before running this script."
	exit 1
fi
echo "Updating docker container: openscad/openscad:2021.01"
docker pull openscad/openscad:2021.01

# Use docker volumes as /input and /output. Docker volumes are required because
# bind mounts will be mounted read-only.
echo "Creating temporary docker volumes stl2png-input and stl2png-output"
docker volume create --name stl2png-input
INPUT_ID=$(docker run -d -v stl2png-input:/input busybox true)
docker volume create --name stl2png-output
OUTPUT_ID=$(docker run -d -v stl2png-output:/output busybox true)

# Find all files ending in *.stl
# For each file copy it into the `stl2png-input` docker volume
# Run the openscad docker container to convert it to a PNG and save to stl2png-output 
# docker volume.
# Then copy the png back to the host
find ~+ -type f -name "*.stl" -print0 | while read -d '' -r file; do 
	echo "Converting ${file} to .PNG"
	filename=$(basename "${file}" ".stl")
	dirname=$(dirname "${file}")

	docker cp "${file}" "${INPUT_ID}:/input/"
	docker run --init --rm \
		-v "stl2png-input:/input" \
		-v "stl2png-output:/output" \
		openscad/openscad:2021.01 xvfb-run -a openscad /dev/null -o "/output/${filename}.png" -D "import(\"/input/${filename}.stl\");" --imgsize=600,600 --colorscheme "Tomorrow Night" --autocenter --viewall
	docker cp "${OUTPUT_ID}:/output/${filename}.png" "${dirname}"
done

docker rm $INPUT_ID
docker rm $OUTPUT_ID
docker volume rm stl2png-input
docker volume rm stl2png-output