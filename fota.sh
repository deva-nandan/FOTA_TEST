#!/bin/bash
set -x

# Check if correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <image_directory> <atcmd_path>"
    exit 1
fi

# Check if image directory exists
if [ ! -d "$1" ]; then
    echo "Error: Image directory $1 does not exist."
    exit 1
fi

# Check if ATCMD file exists
if [ ! -f "$2" ]; then
    echo "Error: ATCMD file $2 does not exist."
    exit 1
fi

# Create a directory for storing files
FOTA_DIR="fota_files"
FW_TAR="fw.tar.gz"
MD5_FILE="md5"
FOTA_TAR="fota.tar.gz"

mkdir -p "$FOTA_DIR"

# Copy all files from the image directory
for image_file in "$1"/*; do
    if [ -f "$image_file" ]; then
        filename=$(basename -- "$image_file")
        dest_file="$FOTA_DIR/$filename"
        image_md5="$FOTA_DIR/$filename.txt"
        
        cp "$image_file" "$dest_file"
        md5sum "$dest_file" | cut -d " " -f 1 > "$image_md5"
    fi
done

# Copy the ATCMD file
atcmd_filename=$(basename -- "$2")
atcmd_dest="$FOTA_DIR/$atcmd_filename"
atcmd_md5="$FOTA_DIR/$atcmd_filename.txt"

cp "$2" "$atcmd_dest"
md5sum "$atcmd_dest" | cut -d " " -f 1 > "$atcmd_md5"

# Create a manifest file to track contents
manifest="$FOTA_DIR/manifest.txt"
echo "FOTA Tarball Contents:" > "$manifest"
ls "$FOTA_DIR" >> "$manifest"
echo "Created on: $(date)" >> "$manifest"

echo "Files processed successfully."
echo "Creating FOTA tarball..."

# Create a tarball containing all firmware files and their MD5 files
tar -czvf "$FW_TAR" "$FOTA_DIR"

# Create MD5 hash of fw.tar.gz
md5sum "$FW_TAR" > "$MD5_FILE"

# Create a tarball containing the MD5 file and the fw.tar.gz file
tar -czvf "$FOTA_TAR" "$MD5_FILE" "$FW_TAR"

# Clean up intermediate files
rm "$MD5_FILE" "$FW_TAR"

echo "Done"
