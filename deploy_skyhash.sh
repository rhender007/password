#!/bin/bash

# Define the content of the skyhash script
cat << 'EOF' > skyhash
#!/bin/bash

# Check for correct usage
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: skyhash 'SKY-uuuu-' hashfile"
    echo "Example: skyhash 'SKY-LRNB-' hashes.txt"
    exit 1
fi

# Input variables
BASE_CRIB="$1"          # SKY-uuuu- pattern, e.g., SKY-LRNB-
HASH_FILE="$2"          # Hash file containing the hashes to be cracked

# Validate base crib format
if [[ ! $BASE_CRIB =~ ^SKY-[A-Z]{4}-$ ]]; then
    echo "Error: Invalid format for base crib. Expected format: SKY-uuuu-, where uuuu is uppercase."
    exit 1
fi

# Create the mask directly within Hashcat command
MASK="${BASE_CRIB}?d?d?d?d" # Using the base crib with the trailing dash as part of the mask

# Run Hashcat command with status display and custom mask
echo "Running Hashcat with base crib: $BASE_CRIB and mask: ${MASK}"
hashcat -a 3 -m 0 --status --status-timer=10 --outfile=cracked_passwords.txt "$HASH_FILE" "$MASK"

# Check if cracking was successful
if [ $? -eq 0 ]; then
    echo "Hashcat finished successfully. Displaying cracked passwords:"
    # Use --show to display cracked passwords
    hashcat -m 0 --show "$HASH_FILE"
else
    echo "Hashcat encountered an error. Check your settings and try again."
fi
EOF

# Make the script executable
chmod +x skyhash

# Move the script to /usr/local/bin for global use
sudo mv skyhash /usr/local/bin/

echo "skyhash has been installed to /usr/local/bin and is ready to use."
