#!/bin/bash
cat << 'EOF' > skyhash
#!/bin/bash
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: skyhash 'uuuu' hashfile"
    echo "Example: skyhash 'LRNB' hashes.txt"
    exit 1
fi

MIDDLE_CHARS="$1"
HASH_FILE="$2"

if [[ ! $MIDDLE_CHARS =~ ^[A-Z]{4}$ ]]; then
    echo "Error: Invalid format for middle characters. Expected 4 uppercase letters."
    exit 1
fi

# Read first hash from file
FIRST_HASH=$(head -n 1 "$HASH_FILE")

# Determine hash mode based on format
if [[ $FIRST_HASH == '$1$'* ]]; then
    HASH_MODE=500  # md5crypt
else
    HASH_MODE=0    # MD5
fi

BASE_CRIB="SKY-${MIDDLE_CHARS}-"
MASK="${BASE_CRIB}?d?d?d?d"
echo "Running Hashcat with pattern: $BASE_CRIB and mask: ${MASK}"
hashcat -a 3 -m $HASH_MODE --status --status-timer=10 --outfile=cracked_passwords.txt "$HASH_FILE" "$MASK"

if [ $? -eq 0 ]; then
    echo "Hashcat finished successfully. Displaying cracked passwords:"
    hashcat -m $HASH_MODE --show "$HASH_FILE"
else
    echo "Hashcat encountered an error. Check your settings and try again."
fi
EOF
chmod +x skyhash
sudo mv skyhash /usr/local/bin/
echo "skyhash has been installed to /usr/local/bin and is ready to use."
