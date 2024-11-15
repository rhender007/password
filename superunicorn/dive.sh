#!/bin/bash

# Disable history expansion to avoid interpreting ! as a special character
set +H

# Trap to handle interrupts (CTRL+C)
trap 'echo "Interrupt received. Stopping processes..."; pkill -f "/usr/bin/hashcat"; countdown_exit; exit' INT

# Countdown function for 5 seconds before exit
countdown_exit() {
    echo "Exiting in 5 seconds..."
    for i in {5..1}; do
        echo "Exiting in $i..."
        sleep 1
    done
}

# Kill any existing hashcat processes before starting
pkill -f '/usr/bin/hashcat' > /dev/null 2>&1

POTFILE="/home/ubuntu/.local/share/hashcat/hashcat.potfile"
PROJECT_NAME=$(basename "$PWD")
INPUT_DIR=$(pwd)
HASHES_FILE="${INPUT_DIR}/hashes.txt"
DIVE_RULE="/mnt/c/Tools/hashcat/rules/dive.rule"
WORD_LIST="${INPUT_DIR}/wordlist.txt"
WORD_LIST_CLEAN="${INPUT_DIR}/wordlist_clean.txt"
WORD_LIST_CLEAN_LESS_THAN_10="${INPUT_DIR}/wordlist_clean_less_than_10.txt"

LOGS_DIR="./logs"  # Set log directory to ./logs

# Ensure the logs directory exists
mkdir -p "$LOGS_DIR"

# Create a timestamped log file
timestamp=$(date '+%Y%m%d_%H%M%S')
log_file="${LOGS_DIR}/${timestamp}_hashcat_log.txt"
echo "Log started at $(date)" | tee -a "$log_file"

sed 's/\r$//' "$WORD_LIST" | awk '{$1=$1};1' > "$WORD_LIST_CLEAN" | tee -a "$log_file"
awk 'length < 10' "$WORD_LIST_CLEAN" > "$WORD_LIST_CLEAN_LESS_THAN_10" | tee -a "$log_file"

hashcat -m 500 -a 0 -O -S --status --status-timer=10 "$HASHES_FILE" -r "$DIVE_RULE" "$WORD_LIST_CLEAN_LESS_THAN_10" | tee -a "$log_file"

# Dump the contents of the hashcat potfile
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dumping the contents of potfile:" | tee -a "$log_file"
cat "$POTFILE" | tee -a "$log_file"

echo "All batches processed at $(date)" | tee -a "$log_file"
