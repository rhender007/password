#!/bin/bash

# Disable history expansion to avoid interpreting ! as a special character
set +H

# Set project name
PROJECT_NAME="rush"
POTFILE="/home/ubuntu/.local/share/hashcat/hashcat.potfile"

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
INPUT_DIR="/mnt/c/Users/rhend/Desktop/input/${PROJECT_NAME}"
HYBRID_CANDIDATES_FILE="${INPUT_DIR}/hybrid_candidates.txt"
WL_BEFORE_MASKS="${INPUT_DIR}/wl_beforemasks.txt"
HASHES_FILE="${INPUT_DIR}/hashes.txt"
LOGS_DIR="./logs"  # Set log directory to ./logs

# Remove existing hybrid_candidates.txt file if it exists
if [ -f "$HYBRID_CANDIDATES_FILE" ]; then
    rm -f "$HYBRID_CANDIDATES_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Removed existing $HYBRID_CANDIDATES_FILE" | tee -a "$log_file"
fi

# Ensure the logs directory exists
mkdir -p "$LOGS_DIR"

# Create a timestamped log file
timestamp=$(date '+%Y%m%d_%H%M%S')
log_file="${LOGS_DIR}/${timestamp}_hashcat_log.txt"
echo "Log started at $(date)" | tee -a "$log_file"

# Prompt user for the base word and set default
read -p "Enter the base word for generation (default: breeze): " input_word
word=${input_word:-breeze}
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Base word set to '$word'" | tee -a "$log_file"


# incisive-leet-first.rule
# incisive-leet.rule
# global-leet.rule

# Rule variables for use in commands
# TOGGLES_RULE="/mnt/c/Tools/hashcat/rules/toggles${#word}.rule"
TOGGLES_RULE="/mnt/c/Tools/hashcat/rules/toggles10.rule"
# OPTIONAL_SPECIAL_RULE="/mnt/c/Tools/hashcat/rules/optional_specialv2.rule"
# EXCLAMATION_END_RULE="/mnt/c/Tools/hashcat/rules/exclamation_end.rule"
# LEETSPEAK_RULE="/mnt/c/Tools/hashcat/rules/global-leet.rule"
# LEETSPEAK_RULE="/mnt/c/Tools/hashcat/rules/global-leet-inverse.rule"
INCISIVE_LEET_RULE="/mnt/c/Tools/hashcat/rules/incisive-leet-first.rule"
# PARTIAL_LEET_RULE="/mnt/c/Tools/hashcat/rules/partial-combinations-leet.rule"
PARTIAL_LEET_RULE="/mnt/c/Tools/hashcat/rules/incisive-leet-first.rule"
LOWERCASE_RULE="/mnt/c/Tools/hashcat/rules/lowercase.rule"
# PARTIAL_LEET_RULE="/mnt/c/Tools/hashcat/rules/leetspeak.rule"
# PARTIAL_LEET_RULE="/mnt/c/Tools/hashcat/rules/incisive-leet-first.rule"

# Create the variations directory if it doesn't exist
mkdir -p "$INPUT_DIR"

# Backup wl_beforemasks.txt if it exists
if [ -f "$WL_BEFORE_MASKS" ]; then
    backup_file="${WL_BEFORE_MASKS%.*}_backup_${timestamp}.txt"
    cp "$WL_BEFORE_MASKS" "$backup_file"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup created: $backup_file" | tee -a "$log_file"
fi

rm -f "$WL_BEFORE_MASKS"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Preparing $WL_BEFORE_MASKS for output" | tee -a "$log_file"

# Check if the WL_BEFORE_MASKS file can be created, create it if not exists
touch "$WL_BEFORE_MASKS"
if [ ! -f "$WL_BEFORE_MASKS" ]; then
    echo "Error: Failed to create $WL_BEFORE_MASKS" | tee -a "$log_file"
    countdown_exit
    exit 1
fi

# Generate toggled word list
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating toggled word list..." | tee -a "$log_file"

sed 's/\r$//' rush_songs.txt | awk '{$1=$1};1' > rush_songs_clean.txt
awk 'length < 10' rush_songs_clean.txt > rush_songs_less_than_10.txt
hashcat 'rush_songs_less_than_10.txt' --status --status-timer=10 -r "$TOGGLES_RULE" -r "$INCISIVE_LEET_RULE" -r "$LOWERCASE_RULE" -r "$INCISIVE_LEET_RULE"  --force --stdout | sort -u > "$WL_BEFORE_MASKS"

hashcat -m 500 -a 0 -O -S --status --status-timer=10 hashes.txt wl_beforemasks.txt
# hashcat -m 500 -a 0 -O -S --status --status-timer=10 hashes.txt wl_beforemasks.txt

# Dump the contents of the hashcat potfile
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dumping the contents of potfile:" | tee -a "$log_file"
cat "$POTFILE" | tee -a "$log_file"

echo "All batches processed at $(date)" | tee -a "$log_file"
