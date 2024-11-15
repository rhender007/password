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

# Directories and file paths as variables
POTFILE="/home/ubuntu/.local/share/hashcat/hashcat.potfile"
# Set project name
PROJECT_NAME=$(basename "$PWD")
INPUT_DIR="/mnt/c/Users/rhend/Desktop/input/${PROJECT_NAME}"
HYBRID_CANDIDATES_FILE="${INPUT_DIR}/hybrid_candidates.txt"
WL_BEFORE_MASKS="${INPUT_DIR}/wl_beforemasks.txt"
HASHES_FILE="${INPUT_DIR}/hashes.txt"
LOGS_DIR="./logs"  # Set log directory to ./logs

WORD_LIST="${INPUT_DIR}/wordlist.txt"
WORD_LIST_CLEAN="${INPUT_DIR}/wordlist_clean.txt"
WORD_LIST_CLEAN_LESS_THAN_10="${INPUT_DIR}/wordlist_clean_less_than_10.txt"
# Rule variables for use in commands
# TOGGLES_RULE="/mnt/c/Tools/hashcat/rules/toggles${#word}.rule"
TOGGLES_RULE="/mnt/c/Tools/hashcat/rules/toggles10.rule"
INCISIVE_LEET_RULE="/mnt/c/Tools/hashcat/rules/incisive-leet-first.rule"
PARTIAL_LEET_RULE="/mnt/c/Tools/hashcat/rules/incisive-leet-first.rule"
LOWERCASE_RULE="/mnt/c/Tools/hashcat/rules/lowercase.rule"
MASKS_FILE="masks.txt"

# Create the variations directory if it doesn't exist
mkdir -p "$INPUT_DIR"

# Ensure the logs directory exists
mkdir -p "$LOGS_DIR"

# Remove existing hybrid_candidates.txt file if it exists
if [ -f "$HYBRID_CANDIDATES_FILE" ]; then
    rm -f "$HYBRID_CANDIDATES_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Removed existing $HYBRID_CANDIDATES_FILE" | tee -a "$log_file"
fi

# Create a timestamped log file
timestamp=$(date '+%Y%m%d_%H%M%S')
log_file="${LOGS_DIR}/${timestamp}_hashcat_log.txt"
echo "Log started at $(date)" | tee -a "$log_file"

# Prompt user for the base word and set default
read -p "Enter the base word for generation (default: breeze): " input_word
word=${input_word:-breeze}
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Base word set to '$word'" | tee -a "$log_file"

echo "$word" > "$WORD_LIST"
sed 's/\r$//' "$WORD_LIST" | awk '{$1=$1};1' > "$WORD_LIST_CLEAN" | tee -a "$log_file"
awk 'length < 10' "$WORD_LIST_CLEAN" > "$WORD_LIST_CLEAN_LESS_THAN_10" | tee -a "$log_file"

# -r "$LOWERCASE_RULE" -r "$INCISIVE_LEET_RULE" 
hashcat "$WORD_LIST_CLEAN_LESS_THAN_10" --status --status-timer=10 -r "$TOGGLES_RULE" -r "$INCISIVE_LEET_RULE"  --force --stdout | sort -u > "$WL_BEFORE_MASKS"

# crunch goes here
# let's try a smaller list. we'll put the ! back in
word_length=${#word}
max_mask_length=$((10 - word_length))
crunch 1 $max_mask_length 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' -o "$MASKS_FILE"

# a 1 for combinator attack
hashcat -m 500 -a 1 -O -S --status --status-timer=10 -w 3 hashes.txt "$WL_BEFORE_MASKS" "$MASKS_FILE"

$max_mask_length-=1
crunch 1 $max_mask_length 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' -o "$MASKS_FILE"
# a 1 for combinator attack
# need to remove -S here for the !
hashcat -m 500 -a 1 -O --status --status-timer=10 -w 3 --rule-right='$!' hashes.txt "$MASKS_FILE" "$WL_BEFORE_MASKS"

# Dump the contents of the hashcat potfile
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dumping the contents of potfile:" | tee -a "$log_file"
cat "$POTFILE" | tee -a "$log_file"

echo "All batches processed at $(date)" | tee -a "$log_file"
