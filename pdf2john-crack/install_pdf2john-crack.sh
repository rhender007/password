#!/bin/bash

# Define the installation path and script name
INSTALL_PATH="/usr/local/bin/pdf2john-crack"

# Create the script content
sudo tee "$INSTALL_PATH" > /dev/null << 'EOF'
#!/bin/bash

# Check if a PDF file was provided
if [ -z "$1" ]; then
  echo "Usage: pdf2john-crack <pdffile>"
  exit 1
fi

# Set variables
PDF_FILE="$1"
HASH_FILE="/tmp/pdfhash.txt"
WORDLIST="/usr/share/wordlists/rockyou.txt"
DECRYPTED_FILE="/tmp/decrypted_pdf.pdf"

# Check if the PDF file exists
if [ ! -f "$PDF_FILE" ]; then
  echo "Error: File $PDF_FILE not found!"
  exit 1
fi

# Generate the hash from the PDF file
pdf2john "$PDF_FILE" > "$HASH_FILE"

# Extract only the $pdf$ hash
grep '\$pdf\$' "$HASH_FILE" | sed -n 's/.*\(\$pdf\$.*\)/\1/p' > "$HASH_FILE.cleaned"

# Display the extracted hash for verification
echo "Hash extracted for john:"
cat "$HASH_FILE.cleaned"

# Check if the hash was correctly isolated
if [ ! -s "$HASH_FILE.cleaned" ]; then
  echo "Error: No valid hash found in $PDF_FILE"
  sudo rm "$HASH_FILE" "$HASH_FILE.cleaned"
  exit 1
fi

# Attempt to crack the password with john using the specified wordlist and PDF format in background
echo "Running john the ripper..."
john --format=pdf "$HASH_FILE.cleaned" --wordlist="$WORDLIST" &

# Store the john process ID
JOHN_PID=$!

# Monitor status by pressing Enter
echo "Press Enter to view the status of john at any time."
while kill -0 "$JOHN_PID" >/dev/null 2>&1; do
  read -t 1 -n 1 key
  if [[ $key = "" ]]; then
    john --status
  fi
done

# Retrieve the cracked password from john's output
CRACKED_PASSWORD=$(john --show --format=pdf "$HASH_FILE.cleaned" | awk -F ':' '{print $2}' | head -n 1)

# Print the cracked password for verification
echo "Password found: '$CRACKED_PASSWORD'"

# Check if a password was found
if [ -z "$CRACKED_PASSWORD" ]; then
  echo "Password could not be cracked."
  sudo rm "$HASH_FILE" "$HASH_FILE.cleaned"
  exit 1
fi

# Use qpdf to create an unencrypted version of the PDF
echo "Creating an unencrypted copy of the PDF..."
qpdf --password="$CRACKED_PASSWORD" --decrypt "$PDF_FILE" "$DECRYPTED_FILE"

# Check if the decrypted file was created
if [ -f "$DECRYPTED_FILE" ]; then
  echo "Decrypted PDF saved to: $DECRYPTED_FILE"
  xdg-open "$DECRYPTED_FILE" &  # Opens the decrypted PDF using the default viewer
else
  echo "Failed to create decrypted PDF."
fi

# Clean up temporary files
sudo rm "$HASH_FILE" "$HASH_FILE.cleaned"

EOF

# Make the script executable
sudo chmod +x "$INSTALL_PATH"

# Confirm installation
if [ -f "$INSTALL_PATH" ]; then
  echo "pdf2john-crack utility has been installed to /usr/local/bin."
else
  echo "Installation failed."
fi
