#!/bin/bash

WORD=$1
LENGTH=${#WORD}
MAX_LENGTH=10
HASH_FILE="hashes.txt"

# Character sets
UPPER='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
LOWER='abcdefghijklmnopqrstuvwxyz'
DIGITS='0123456789'
SPECIAL='%&!'

ALL_CHARS="${UPPER}${LOWER}${DIGITS}${SPECIAL}"

# Clean start - remove and recreate wordlists directory
rm -rf wordlists
mkdir -p wordlists

generate_toggles() {
    local word=$1
    local prefix=$2
    if [ ${#word} -eq 0 ]; then
        echo "$prefix"
        return
    fi
    local first_char="${word:0:1}"
    local rest="${word:1}"
    generate_toggles "$rest" "$prefix${first_char,,}"
    generate_toggles "$rest" "$prefix${first_char^^}"
}

generate_leet_variants() {
    local word=$1
    local variants=()
    local -A leet_map=(
        [a]="@4"
        [e]="3"
        [i]="1!"
        [o]="0"
        [s]="5\$"
        [t]="7"
        [z]="2"
    )
    
    while IFS= read -r toggled; do
        variants+=("$toggled")
        
        # Full leet
        local full_leet="$toggled"
        for char in $(echo "$toggled" | grep -o .); do
            char_lower="${char,,}"
            if [[ ${leet_map[$char_lower]} ]]; then
                for leet_char in $(echo ${leet_map[$char_lower]} | grep -o .); do
                    full_leet="${full_leet//$char/$leet_char}"
                done
            fi
        done
        variants+=("$full_leet")
        
        # Partial leet
        local word_len=${#toggled}
        for ((i=0; i<word_len; i++)); do
            local char="${toggled:$i:1}"
            char_lower="${char,,}"
            if [[ ${leet_map[$char_lower]} ]]; then
                for leet_char in $(echo ${leet_map[$char_lower]} | grep -o .); do
                    local new_word="${toggled:0:$i}${leet_char}${toggled:$((i+1))}"
                    variants+=("$new_word")
                done
            fi
        done
    done < <(generate_toggles "$word")
    
    printf '%s\n' "${variants[@]}" | sort -u
}

# Generate base variants with leet transformations
variants=$(generate_leet_variants "$WORD")

# Generate base wordlist
echo "$variants" > wordlists/base.txt

# Calculate max mask length
max_mask_len=$((MAX_LENGTH - LENGTH))
[[ $max_mask_len -lt 0 ]] && max_mask_len=0

# Function to generate combinations
generate_combinations() {
    local length=$1
    local prefix=$2
    
    if [ "$length" -eq 0 ]; then
        echo "$prefix"
        return
    fi
    
    for char in $(echo "$ALL_CHARS" | grep -o .); do
        generate_combinations $((length - 1)) "${prefix}${char}"
    done
}

# Generate wordlists with character combinations
for mask_len in $(seq 0 $max_mask_len); do
    if [ $mask_len -gt 0 ]; then
        while IFS= read -r variant; do
            # Generate combinations for current length
            while IFS= read -r combo; do
                # Add chars at beginning
                echo "${combo}${variant}" >> wordlists/with_chars.txt
                # Add chars at end
                echo "${variant}${combo}" >> wordlists/with_chars.txt
            done < <(generate_combinations $mask_len "")
        done < wordlists/base.txt
    fi
done

# Combine and deduplicate
cat wordlists/base.txt >> wordlists/with_chars.txt
sort -u wordlists/with_chars.txt > wordlists/final.txt

# Show sample of the wordlist for verification
echo "Sample of generated wordlist:"
head -n 10 wordlists/final.txt

# Run hashcat
echo "Running hashcat with MD5crypt mode..."
hashcat -m 500 -a 0 "$HASH_FILE" wordlists/final.txt -O -w 3 --status --status-timer 10

# Keep the files for inspection
# rm -rf wordlists/

echo "Attack completed. Generated files are in the wordlists directory."
