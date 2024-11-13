#!/bin/bash

# Define the installation path and script name
INSTALL_PATH="/usr/local/bin/zip2hashcat"

# Create the script content
cat << 'EOF' > "$INSTALL_PATH"
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
  rm "$HASH_FILE"
  exit 1
fi

# Attempt to crack the password with hashcat
hashcat -m 17210 "$FORMATTED_HASH_FILE" "$WORDLIST" --quiet

# Show the cracked password if found
hashcat -m 17210 --show "$FORMATTED_HASH_FILE"

# Clean up temporary files
rm "$HASH_FILE" "$FORMATTED_HASH_FILE"
EOF

# Make the script executable
chmod +x "$INSTALL_PATH"

# Confirm installation
if [ -f "$INSTALL_PATH" ]; then
  echo "zip2hashcat utility has been installed to /usr/local/bin."
else
  echo "Installation failed."
fi
