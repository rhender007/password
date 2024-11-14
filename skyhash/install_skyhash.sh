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

BASE_CRIB="SKY-${MIDDLE_CHARS}-"
MASK="${BASE_CRIB}?d?d?d?d"

echo "Running Hashcat with pattern: $BASE_CRIB and mask: ${MASK}"
hashcat -a 3 -m 500 --status --status-timer=10 --outfile=cracked_passwords.txt "$HASH_FILE" "$MASK"

if [ $? -eq 0 ]; then
    echo "Hashcat finished successfully. Displaying cracked passwords:"
    hashcat -m 500 --show "$HASH_FILE"
else
    echo "Hashcat encountered an error. Check your settings and try again."
fi
EOF

chmod +x skyhash
sudo mv skyhash /usr/local/bin/
echo "skyhash has been installed to /usr/local/bin and is ready to use."
