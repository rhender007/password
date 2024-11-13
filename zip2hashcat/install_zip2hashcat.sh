#!/bin/bash

# Define the installation path and script name
INSTALL_PATH="/usr/local/bin/zip2hashcat"

# Create the script content
sudo tee "$INSTALL_PATH" > /dev/null << 'EOF'
#!/bin/bash

# Check if a zip file was provided
if [ -z "$1" ]; then
  echo "Usage: zip2hashcat <zipfile>"
  exit 1
fi

# Set variables
ZIP_FILE="$1"
HASH_FILE="/tmp/ziphash.txt"
FORMATTED_HASH_FILE="/tmp/formatted_ziphash.txt"
WORDLIST="/usr/share/wordlists/rockyou.txt"
EXTRACT_DIR="/tmp/extracted_zip_contents"

# Check if the zip file exists
if [ ! -f "$ZIP_FILE" ]; then
  echo "Error: File $ZIP_FILE not found!"
  exit 1
fi

# Generate the hash from the zip file
zip2john "$ZIP_FILE" > "$HASH_FILE"

# Extract and format the hash for hashcat
grep '\$pkzip\$' "$HASH_FILE" | sed -n 's/.*\(\$pkzip\$.*\)\$/\1/p' > "$FORMATTED_HASH_FILE"

# Display the extracted hash
if [ -s "$FORMATTED_HASH_FILE" ]; then
  echo "Hash extracted for hashcat:"
  cat "$FORMATTED_HASH_FILE"
else
  echo "Error: No compatible hash found in the zip file."
  sudo rm "$HASH_FILE"
  exit 1
fi

# Attempt to crack the password with hashcat
echo "Running hashcat..."
hashcat -m 17210 "$FORMATTED_HASH_FILE" "$WORDLIST" --quiet

# Get the cracked password
CRACKED_PASSWORD=$(hashcat -m 17210 --show "$FORMATTED_HASH_FILE" | awk -F ':' '{print $NF}')

# Check if a password was found
if [ -z "$CRACKED_PASSWORD" ]; then
  echo "Password could not be cracked."
  sudo rm "$HASH_FILE" "$FORMATTED_HASH_FILE"
  exit 1
fi

echo "Password found: $CRACKED_PASSWORD"

# Attempt to extract the zip file using the cracked password with overwrite enabled
echo "Extracting zip file with password..."
mkdir -p "$EXTRACT_DIR"
unzip -o -P "$CRACKED_PASSWORD" "$ZIP_FILE" -d "$EXTRACT_DIR"
UNZIP_EXIT_CODE=$?

# Verify if extraction was successful
if [ $UNZIP_EXIT_CODE -ne 0 ]; then
  echo "Error: Extraction failed with exit code $UNZIP_EXIT_CODE."
  sudo rm "$HASH_FILE" "$FORMATTED_HASH_FILE"
  exit 1
elif [ -z "$(ls -A "$EXTRACT_DIR")" ]; then
  echo "Error: Extraction completed but no files found in $EXTRACT_DIR."
  sudo rm "$HASH_FILE" "$FORMATTED_HASH_FILE"
  exit 1
fi

echo "Extraction successful. Contents of the extracted files:"
# Display the contents of text files only
find "$EXTRACT_DIR" -type f | while read -r file; do
  if file --mime-type "$file" | grep -q 'text/'; then
    echo "Displaying contents of: $file"
    cat "$file"
  else
    echo "Skipping non-text file: $file (binary content)"
  fi
done

# Find and open images with EOM if any are found
IMAGE_FILES=$(find "$EXTRACT_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \))
if [ -n "$IMAGE_FILES" ]; then
  echo "Opening images in EOM..."
  eom $IMAGE_FILES &
  EOM_PID=$!  # Capture the EOM process ID
  wait $EOM_PID  # Wait until EOM is closed
fi

# Clean up extracted contents and temporary files
sudo rm "$HASH_FILE" "$FORMATTED_HASH_FILE"
rm -rf "$EXTRACT_DIR"

EOF

# Make the script executable
sudo chmod +x "$INSTALL_PATH"

# Confirm installation
if [ -f "$INSTALL_PATH" ]; then
  echo "zip2hashcat utility has been installed to /usr/local/bin."
else
  echo "Installation failed."
fi
