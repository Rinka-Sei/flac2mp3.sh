# FLAC to MP3 Converter

This Bash script provides a robust and user-friendly way to convert your entire FLAC music library into high-quality 320kbps MP3s. It preserves your original folder structure, filenames, and audio metadata. The script includes real-time progress updates, color-coded output, and multiple user confirmations to ensure you're in control.

---

![screenshot](https://github.com/Rinka-Sei/flac2mp3.sh/blob/c2a14454d1b59d16dc036cc8d17acc94c8d72a89/example.jpeg)

---

## Features

* **Recursive Conversion:** Converts all `.flac` files found within a specified directory and its subdirectories.
* **Folder Structure Preservation:** Maintains the exact same directory hierarchy for the output MP3 files.
* **Filename & Metadata Retention:** Output MP3s will have the same filenames as their source FLACs (with a `.mp3` extension) and all original metadata (Artist, Album, Title, etc.) will be copied. This also ensures `.lrc` lyrics files remain compatible.
* **320kbps MP3 Output:** Converts to a high-quality 320kbps constant bitrate MP3.
* **Real-time Progress:** Displays a live counter showing how many files have been processed out of the total.
* **Color-Coded Output:** Provides clear, color-coded messages for processing, success, errors, and warnings.
* **Comprehensive Logging:** Records all conversion attempts (successful or failed) to a `flac_to_mp3_conversion_log.txt` file.
* **User Confirmations:** Two confirmation prompts to prevent accidental operations:
    * Before starting the conversion process.
    * After conversion, before deleting any successfully converted FLAC files.
* **Robust Error Handling:** Checks for necessary dependencies (`ffmpeg`, `find`) and handles directory creation failures.
* **Graceful Exit:** Catches `Ctrl+C` interruptions to exit cleanly.

---

## Requirements

Before running the script, make sure you have the following installed on your system:

* **Bash, Zsh, or Ksh:** This script is primarily designed for Bash, Zsh, or Ksh shells. It uses features (like arrays, process substitution, and `[[ ... ]]` conditionals) that are common in these modern shells. While it might run on some other shells, full functionality and stability are guaranteed with Bash, Zsh, or Ksh.
* **FFmpeg:** The powerful open-source multimedia framework that handles the actual audio conversion.
* **`find` utility:** A standard command-line utility for locating files, usually pre-installed on Linux/macOS.
* **`basename` and `dirname` utilities:** Standard commands for extracting file and directory names, also usually pre-installed.

### Installation Instructions for FFmpeg

* **Debian/Ubuntu:**
    ```bash
    sudo apt update
    sudo apt install ffmpeg
    ```
* **Fedora:**
    ```bash
    sudo dnf install ffmpeg
    ```
* **Arch Linux:**
    ```bash
    sudo pacman -S ffmpeg
    ```
* **macOS (using Homebrew):**
    ```bash
    brew install ffmpeg
    ```
* **Windows:**
    For Windows, you can use the Windows Subsystem for Linux (WSL) and install FFmpeg as you would on Ubuntu, or you can download the Windows build of FFmpeg and ensure its executable is in your system's PATH.

---

## How to Use

1.  **Save the Script:**
    Save the script content into a file named `flac2mp3.sh`.

2.  **Make it Executable:**
    Open your terminal, navigate to the directory where you saved the script, and run:
    ```bash
    chmod +x flac2mp3.sh
    ```

3.  **Run the Script:**
    Execute the script by providing the **full path** to the root directory containing your FLAC music library.

    **Example:**
    If your FLAC files are organized under `/home/youruser/Music/My_Awesome_Collection`, you would run:
    ```bash
    ./flac2mp3.sh "/home/youruser/Music/My_Awesome_Collection"
    ```
    **Important:** Always enclose the input directory path in **double quotes**** if it contains any spaces or special characters.

### What to Expect When Running the Script:

* **Initial Scan:** The script will first scan the specified directory to count the total number of FLAC files.
* **First Confirmation:** It will then ask you to confirm if you want to proceed with the conversion. Enter `y` (and press Enter) to continue, or anything else to exit.
* **Conversion Progress:** For each FLAC file, you'll see a line indicating its progress (e.g., `[5/100] Processing: Song Title.flac`). FFmpeg's own progress will also be visible.
    * **Green:** Indicates a successful conversion.
    * **Red:** Indicates a failed conversion or an error.
    * **Yellow:** For in-progress messages and warnings.
    * **Blue:** For general informational messages.
* **Conversion Log:** All success and error messages will also be appended to `flac_to_mp3_conversion_log.txt` in the same directory as the script.
* **Final Summary:** Once all files are processed, the script will show a summary of total, successful, and failed conversions.
* **Second Confirmation (Deletion):** If any files were successfully converted, the script will then ask if you want to **delete the original FLAC files**. This is a critical step, so proceed with caution. Enter `y` (and press Enter) to delete, or anything else to keep the FLAC files.

---

## Customization

You can easily customize the script by editing the `Configuration` section at the top of the `flac2mp3.sh` file:

* **`TARGET_BITRATE="320k"`:** Change this value to adjust the output MP3 quality. For example, use `"256k"` for 256kbps or `"192k"` for 192kbps.
* **`LOG_FILE="flac_to_mp3_conversion_log.txt"`:** Modify the name of the log file if desired.

---

## Troubleshooting

* **"Error: ffmpeg is not installed..."**: Ensure FFmpeg is correctly installed and its executable is in your system's PATH. Refer to the "Installation Instructions for FFmpeg" section above.
* **"Error: Input directory '...' does not exist."**: Double-check the path you provided. Make sure there are no typos and that the directory actually exists. Remember to use double quotes for paths with spaces.
* **Script doesn't run or gives syntax errors:**
    * Make sure you've made the script executable (`chmod +x`).
    * Verify you are running it in a compatible shell (Bash, Zsh, or Ksh). The script will try to warn you if your shell is not compatible.
* **Filenames with special characters causing issues:** The script is designed to handle spaces and most special characters using null-terminated strings (`-print0` and `read -d $'\0'`). If you encounter issues, ensure your `find` and `xargs` utilities support GNU extensions (which is common on Linux).

---

## Contributing

Feel free to open issues or submit pull requests if you have suggestions for improvements or encounter bugs.

---

## License

This project is open-source and available under the [MIT License](LICENSE).
