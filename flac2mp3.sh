#!/usr/bin/env bash

# Set strict mode for better script robustness (for Bash, Zsh, Ksh)
set -euo pipefail

# --- Configuration ---
TARGET_BITRATE="320k" # Output MP3 bitrate (e.g., "320k", "256k", "192k")
LOG_FILE="flac_to_mp3_conversion_log.txt" # Log file for all conversions (success/fail)

# --- Color Codes ---
GREEN='\033[0;32m' # For success messages
RED='\033[0;31m'   # For error/failure messages
YELLOW='\033[0;33m' # For in-progress messages / warnings
BLUE='\033[0;34m' # For informational messages
WHITE='\033[1;37m' # For script crash/exit
NC='\033[0m'       # No Color - resets text to default

# --- Global Counters and Lists ---
TOTAL_FILES=0
PROCESSED_FILES=0
SUCCESS_COUNT=0
FAILED_COUNT=0
SUCCESSFULLY_CONVERTED_FLAC_FILES=() # Array to store paths of successfully converted FLACs

# --- Functions ---

# Function to display usage
usage() {
    printf "%bUsage: %s <input_directory>%b\n" "$BLUE" "$0" "$NC"
    printf "%b  <input_directory>: The root directory containing your FLAC files.%b\n" "$BLUE" "$NC"
    printf "\n"
    printf "This script will convert all .flac files within the specified directory\n"
    printf "and its subdirectories to %s MP3, maintaining the original\n" "$TARGET_BITRATE"
    printf "directory structure and filenames. Metadata will be preserved.\n"
    printf "A detailed log of conversions (success/failure) will be written to %s.%b\n" "$LOG_FILE" "$NC"
    exit 1
}

# Trap CTRL+C to ensure a clean exit message
trap 'printf "\n%bSCRIPT INTERRUPTED BY USER (Ctrl+C)! Exiting.%b\n" "$WHITE" "$NC"; exit 1' INT TERM

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

# --- Main Script Logic ---

# Initial Shell Compatibility Check
case "$BASH_VERSION" in
    '') # Not Bash. Check Zsh/Ksh
        case "$ZSH_VERSION" in
            '') # Not Zsh. Check Ksh
                case "$KSH_VERSION" in
                    '') # Not Ksh. Potentially sh or fish or something else.
                        printf "%bWarning: This script is designed for Bash, Zsh, or Ksh. Your shell is '%s'.\n" "$YELLOW" "$(basename "$SHELL")"
                        printf "Some features might not work as expected or the script may fail.%b\n" "$NC"
                        ;;
                esac
                ;;
        esac
        ;;
esac

# 1. Initial Checks
if [ "$#" -ne 1 ]; then
    usage
fi

INPUT_DIR="$1"

if [ ! -d "$INPUT_DIR" ]; then
    printf "%bError: Input directory '%s' does not exist.%b\n" "$RED" "$INPUT_DIR" "$NC"
    usage
fi

if ! command_exists "ffmpeg"; then
    printf "%bError: ffmpeg is not installed or not found in your PATH.%b\n" "$RED" "$NC"
    printf "%bPlease install ffmpeg before running this script.%b\n" "$RED" "$NC"
    printf "%bE.g., sudo apt install ffmpeg (Debian/Ubuntu) or brew install ffmpeg (macOS).%b\n" "$RED" "$NC"
    exit 1
fi

if ! command_exists "find"; then
    printf "%bError: 'find' command is not available. This is highly unusual for a Linux/macOS system.%b\n" "$RED" "$NC"
    exit 1
fi

# 2. Pre-processing and Setup
printf "%bStarting FLAC to MP3 conversion in '%s'...%b\n" "$BLUE" "$INPUT_DIR" "$NC"
printf "%bOutput bitrate: %s%b\n" "$BLUE" "$TARGET_BITRATE" "$NC"
printf "%bLog file: %s%b\n" "$BLUE" "$LOG_FILE" "$NC"
printf "%b----------------------------------------------------%b\n" "$BLUE" "$NC"
printf "\n"

# Clear or create log file
> "$LOG_FILE"

# Get total number of FLAC files for progress counter
printf "%bScanning for FLAC files...%b\n" "$YELLOW" "$NC"
ALL_FLAC_FILES=()
# Using -print0 and read -d $'\0' for robust handling of filenames with spaces/special characters
while IFS= read -r -d $'\0' file; do
    ALL_FLAC_FILES+=("$file")
done < <(find "$INPUT_DIR" -type f -name "*.flac" -print0)
TOTAL_FILES=${#ALL_FLAC_FILES[@]}

if [ "$TOTAL_FILES" -eq 0 ]; then
    printf "%bNo FLAC files found in '%s' or its subdirectories.%b\n" "$YELLOW" "$INPUT_DIR" "$NC"
    printf "%b----------------------------------------------------%b\n" "$BLUE" "$NC"
    printf "%bConversion process completed.%b\n" "$BLUE" "$NC"
    exit 0
fi

printf "%bFound %d FLAC files.%b\n" "$BLUE" "$TOTAL_FILES" "$NC"
printf "\n"

# FIRST CONFIRMATION: Before starting conversion
printf "%b----------------------------------------------------%b\n" "$YELLOW" "$NC"
printf "%bDo you want to proceed with converting %d FLAC files to MP3? (y/N)%b\n" "$YELLOW" "$TOTAL_FILES" "$NC"
read -p "Enter 'y' to confirm conversion: " -n 1 -r REPLY_CONVERT
printf "\n" # Newline after read input

if [[ ! "$REPLY_CONVERT" =~ ^[Yy]$ ]]; then
    printf "%bConversion process cancelled by user. Exiting.%b\n" "$BLUE" "$NC"
    exit 0
fi

printf "%bProceeding with conversion...%b\n" "$BLUE" "$NC"
printf "%b----------------------------------------------------%b\n" "$BLUE" "$NC"
printf "\n"

# 3. Main Conversion Loop
for flac_file in "${ALL_FLAC_FILES[@]}"; do
    PROCESSED_FILES=$((PROCESSED_FILES + 1))

    # Construct output paths
    mp3_file="${flac_file%.flac}.mp3"
    output_dir=$(dirname "$mp3_file")
    filename_only=$(basename "$flac_file")

    printf "%b[%d/%d] Processing: %s%b\n" "$YELLOW" "$PROCESSED_FILES" "$TOTAL_FILES" "$filename_only" "$NC"
    printf "%b  Output to: %s%b\n" "$BLUE" "$mp3_file" "$NC"

    # Create output directory
    if ! mkdir -p "$output_dir"; then
        current_datetime=$(date +"%Y-%m-%d_%H:%M:%S")
        log_message="$current_datetime $filename_only FAILED to create output directory '$output_dir'"
        printf "%bError: %s%b\n" "$RED" "$log_message" "$NC" | tee -a "$LOG_FILE"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        printf "\n"
        continue # Skip to next file
    fi

    # Execute FFmpeg command
    # -i "$flac_file": Input FLAC file
    # -ab "$TARGET_BITRATE": Sets the audio bitrate for MP3
    # -map_metadata 0: Copies all metadata from the input stream (0) to the output
    # -id3v2_version 3: Sets ID3v2 tag version to 3, for broad compatibility
    # -v quiet: Suppresses verbose FFmpeg output to keep the console clean
    # -stats: Shows real-time conversion progress from FFmpeg itself
    if ! ffmpeg -i "$flac_file" -ab "$TARGET_BITRATE" -map_metadata 0 -id3v2_version 3 -v quiet -stats -y "$mp3_file" 2>&1; then
        current_datetime=$(date +"%Y-%m-%d_%H:%M:%S")
        log_message="$current_datetime $filename_only FAILED to convert to mp3"
        printf "%b  ERROR: %s%b\n" "$RED" "$log_message" "$NC" | tee -a "$LOG_FILE"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    else
        current_datetime=$(date +"%Y-%m-%d_%H:%M:%S")
        log_message="$current_datetime $filename_only successfully converted to mp3"
        printf "%b  SUCCESS: %s%b\n" "$GREEN" "$log_message" "$NC" | tee -a "$LOG_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        SUCCESSFULLY_CONVERTED_FLAC_FILES+=("$flac_file") # Add to list for potential deletion
    fi
    printf "\n" # Add an empty line for better readability
done

# 4. Final Summary
printf "%b----------------------------------------------------%b\n" "$BLUE" "$NC"
printf "%bConversion process completed.%b\n" "$BLUE" "$NC"
printf "%bTotal Files Scanned: %d%b\n" "$BLUE" "$TOTAL_FILES" "$NC"
printf "%bSuccessfully Converted: %d%b\n" "$GREEN" "$SUCCESS_COUNT" "$NC"
printf "%bFailed Conversions: %d%b\n" "$RED" "$FAILED_COUNT" "$NC"
printf "%bCheck '%s' for a detailed log of conversions.%b\n" "$BLUE" "$LOG_FILE" "$NC"

# 5. Second Confirmation: Optional FLAC File Deletion
if [ "$SUCCESS_COUNT" -gt 0 ]; then
    printf "\n"
    printf "%b----------------------------------------------------%b\n" "$YELLOW" "$NC"
    printf "%bDo you want to delete the %d original FLAC files\n" "$YELLOW" "$SUCCESS_COUNT"
    printf "that were successfully converted to MP3s? (y/N)%b\n" "$NC"
    read -p "Enter 'y' to confirm deletion: " -n 1 -r REPLY_DELETE
    printf "\n" # Newline after read input

    if [[ "$REPLY_DELETE" =~ ^[Yy]$ ]]; then
        printf "%bInitiating deletion of successfully converted FLAC files...%b\n" "$YELLOW" "$NC"
        for flac_to_delete in "${SUCCESSFULLY_CONVERTED_FLAC_FILES[@]}"; do
            if [ -f "$flac_to_delete" ]; then
                if rm -v "$flac_to_delete"; then
                    current_datetime=$(date +"%Y-%m-%d_%H:%M:%S")
                    log_message="$current_datetime $(basename "$flac_to_delete") successfully deleted."
                    printf "%b  DELETED: %s%b\n" "$GREEN" "$log_message" "$NC" | tee -a "$LOG_FILE"
                else
                    current_datetime=$(date +"%Y-%m-%d_%H:%M:%S")
                    log_message="$current_datetime $(basename "$flac_to_delete") FAILED to delete."
                    printf "%b  ERROR: %s%b\n" "$RED" "$log_message" "$NC" | tee -a "$LOG_FILE"
                fi
            else
                current_datetime=$(date +"%Y-%m-%d_%H:%M:%S")
                log_message="$current_datetime $(basename "$flac_to_delete") not found for deletion (already removed?)."
                printf "%b  WARNING: %s%b\n" "$YELLOW" "$log_message" "$NC" | tee -a "$LOG_FILE"
            fi
        done
        printf "%bDeletion process completed.%b\n" "$YELLOW" "$NC"
    else
        printf "%bDeletion skipped. Original FLAC files remain.%b\n" "$BLUE" "$NC"
    fi
fi

printf "%b----------------------------------------------------%b\n" "$BLUE" "$NC"
printf "%bScript finished.%b\n" "$BLUE" "$NC"
