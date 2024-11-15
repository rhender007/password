#!/bin/bash

# Disable history expansion to avoid interpreting ! as a special character
set +H

# Set project name
PROJECT_NAME="variations"
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

# Rule variables for use in commands
RULES_VAR="/mnt/c/Tools/hashcat/rules/toggles${#word}.rule"
# OPTIONAL_SPECIAL_RULE="/mnt/c/Tools/hashcat/rules/optional_specialv2.rule"
# EXCLAMATION_END_RULE="/mnt/c/Tools/hashcat/rules/exclamation_end.rule"
LEETSPEAK_RULE="/mnt/c/Tools/hashcat/rules/leetspeak.rule"
INCISIVE_LEET_RULE="/mnt/c/Tools/hashcat/rules/Incisive-leetspeak.rule"

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
# removed optional special here
# -r "$OPTIONAL_SPECIAL_RULE"
toggled_words_output=$(echo "$word" | /usr/bin/hashcat -r "$RULES_VAR"  --stdout)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Toggled words generated: $(echo "$toggled_words_output" | wc -l)" | tee -a "$log_file"

# Append lowercase version
toggled_words_output+=$'\n'"${word,,}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Lowercase version of the base word added" | tee -a "$log_file"

# Generate leet transformations
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating leet transformations..." | tee -a "$log_file"
leet_words_output=$(printf "%s\n" "$toggled_words_output" | /usr/bin/hashcat -r "$LEETSPEAK_RULE" --stdout)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Leet transformations generated: $(echo "$leet_words_output" | wc -l)" | tee -a "$log_file"

# Generate incisive leet transformations
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating incisive leet transformations..." | tee -a "$log_file"
incisive_leet_output=$(printf "%s\n" "$toggled_words_output" | /usr/bin/hashcat -r "$INCISIVE_LEET_RULE" --stdout)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Incisive leet transformations generated: $(echo "$incisive_leet_output" | wc -l)" | tee -a "$log_file"

# Combine and deduplicate word variations in WL_BEFORE_MASKS
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Combining generated word variations and deduplicating..." | tee -a "$log_file"
{
    printf "%s\n" "$toggled_words_output" "$leet_words_output" "$incisive_leet_output" | sort -u
} > "$WL_BEFORE_MASKS"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Full deduplicated list written to $WL_BEFORE_MASKS" | tee -a "$log_file"

# Append incisive leet transformations to hybrid candidates for mask processing
# echo "$incisive_leet_output" >> "$HYBRID_CANDIDATES_FILE"

# Generate masks up to max_mask_length
word_length=${#word}
max_mask_length=$((10 - word_length))
options=("?d" "?l" "?u")

# skip mask generation for now. only use crunch and greedy list
# generate_masks() {
#     local prefix="$1"
#     local length="$2"
#     local -a masks
#     if [ "$length" -gt 0 ] && [ "$length" -le "$max_mask_length" ]; then
#         masks+=("$prefix")
#     fi
#     if [ "$length" -lt "$max_mask_length" ]; then
#         for option in "${options[@]}"; do
#             masks+=($(generate_masks "$prefix$option" $((length + 1))))
#         done
#     fi
#     printf "%s\n" "${masks[@]}"
# }

# # Generate and randomize masks
# mapfile -t standard_masks < <(generate_masks "" 0)
# all_masks=($(shuf -e "${standard_masks[@]}"))

# # Set loop count threshold and calculate total batches
# batch_size=3
# total_batches=$(( (${#all_masks[@]} + batch_size - 1) / batch_size ))

# mask_count=0
# batch_count=0

# full list
# crunch 1 $max_mask_length 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()-_=+[]{}|;:,.<>?/\' -o crunch_mask.txt

# greedy list - try common ones 
# crunch 1 $max_mask_length 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_?' -o crunch_mask.txt

# let's try a smaller list. we'll put the ! back in
crunch 1 $max_mask_length 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' -o crunch_mask.txt
hashcat -m 500 -a 1 -O -S --status --status-timer=10 hashes.txt wl_beforemasks.txt crunch_mask.txt
hashcat -m 500 -a 1 -O -S --status --status-timer=10 hashes.txt crunch_mask.txt wl_beforemasks.txt


# EXCLAMATION_END_RULE
# crunch 1 $max_mask_length 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' -o crunch_mask.txt
# hashcat -m 500 -a 1 -O -S --status --status-timer=10 hashes.txt wl_beforemasks.txt crunch_mask.txt

# # Append exclamation end rule to the end of each word in wl_beforemasks.txt
# using -k instead to append the exclamation mark to the end of each word in wl_beforemasks.txt
# sed -i 's/$/!/' wl_beforemasks.txt
# 1 less mask length because of the exclamation mark
max_mask_length=$((max_mask_length - 1))
crunch 1 $max_mask_length 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ' -o crunch_mask.txt

# use the --rule-right to append the ! to the end of each word in the wl_beforemasks.txt
# if i use -S it removes the ! from the end of the word
hashcat -m 500 -O -a 1 --status --status-timer=1 --rule-right='$!' hashes.txt crunch_mask.txt wl_beforemasks.txt
# hashcat -m 500 -a 1 -O -S --status --status-timer=10 hashes.txt crunch_mask.txt wl_beforemasks.txt

# Dump the contents of the hashcat potfile
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dumping the contents of potfile:" | tee -a "$log_file"
cat "$POTFILE" | tee -a "$log_file"

echo "All batches processed at $(date)" | tee -a "$log_file"
