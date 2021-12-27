
# Loops over every file in the templates/directory that ends in .erb
# Goes and finds the corresponding _rendered_ file and deletes it (assumes that rendered files are always in root of repo)
find templates -type f -name *.erb -print0 | while read -d '' -r file; do 
    echo "Found template: $file"
    # Remove .erb extension and strip path to just filename
    file=$(basename ${file%.erb})
    echo "Removing:  $file"
    rm -f "./$file"
done