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

# Extract the zip file with the found password
mkdir -p "$EXTRACT_DIR"
unzip -P "$CRACKED_PASSWORD" "$ZIP_FILE" -d "$EXTRACT_DIR" >/dev/null 2>&1

# Recursively display all files in the extracted directory
echo "Contents of the extracted files:"
find "$EXTRACT_DIR" -type f -exec cat {} +

# Clean up temporary files
sudo rm "$HASH_FILE" "$FORMATTED_HASH_FILE"
EOF

# Make the script executable
sudo chmod +x "$INSTALL_PATH"

# Confirm installation
if [ -f "$INSTALL_PATH" ]; then
  echo "zip2hashcat utility has been installed to /usr/local/bin."
else
  echo "Installation failed."
fi
