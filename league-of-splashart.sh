#!/bin/bash

# Function to display help
display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -d, --directory PATH Specify the directory where to put the results (default is './download')"
    echo "  -f, --force          Force download of all files, even if they already exist"
    echo "  -s, --subdirectories Create subdirectories for each champion"
    echo "  -h, --help           Display this help message"
    exit 0
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed."
    echo "Please install jq to use this script."
    echo "On macOS: brew install jq"
    echo "On Debian/Ubuntu: sudo apt-get install jq"
    echo "On Red Hat/CentOS: sudo yum install jq"
    exit 1
fi

# Default values
force_download=false
download_dir="./download"
use_subdirectories=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--directory) shift; download_dir=$1 ;;
        -f|--force) force_download=true ;;
        -s|--subdirectories) use_subdirectories=true ;;
        -h|--help) display_help ;;
        *) echo "Unknown parameter passed: $1"; display_help ;;
    esac
    shift
done

# Create the download directory if it doesn't exist
mkdir -p "$download_dir"

# Get the latest version of DDragon
latest_version=$(curl -s https://ddragon.leagueoflegends.com/api/versions.json | jq -r '.[0]')
echo "Latest DDragon version: $latest_version"

# Get the list of all champions
champion_list=$(curl -s https://ddragon.leagueoflegends.com/cdn/$latest_version/data/en_US/champion.json | jq -r '.data | keys[]')

# Get the total number of champions
total_champions=$(echo "$champion_list" | wc -w)
echo "Total champions: $total_champions"

# Initialize progress variables
current_champion=0

# Function to display progress bar
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local progress_bar="["
    for ((i = 0; i < 50; i++)); do
        if ((i < percent / 2)); then
            progress_bar+="#"
        else
            progress_bar+=" "
        fi
    done
    progress_bar+="] $percent% ($current/$total)"
    echo -ne "$progress_bar\r"
}

# Loop through all champions
for champion in $champion_list; do
    # Increment current champion counter
    current_champion=$((current_champion + 1))

    # Show progress
    show_progress $current_champion $total_champions

    if [ "$use_subdirectories" = true ]; then
        champion_dir="$download_dir/$champion"
        mkdir -p "$champion_dir"

        # Move existing files to subdirectory
        for skin_num in $(curl -s https://ddragon.leagueoflegends.com/cdn/$latest_version/data/en_US/champion/${champion}.json | jq -r '.data[].skins[].num'); do
            file_name="${champion}_$skin_num.jpg"
            if [ -f "$download_dir/$file_name" ]; then
                mv "$download_dir/$file_name" "$champion_dir/$file_name" 2>> ./error.log
            fi
        done
    else
        champion_dir="$download_dir"
        if [ -d "$download_dir/$champion" ]; then
            mv "$download_dir/$champion/"* "$download_dir/" 2>> ./error.log
            rmdir "$download_dir/$champion"
        fi
    fi

    # Download the champion's official splash artwork
    for skin_num in $(curl -s https://ddragon.leagueoflegends.com/cdn/$latest_version/data/en_US/champion/${champion}.json | jq -r '.data[].skins[].num'); do
        file_path="$champion_dir/${champion}_$skin_num.jpg"
        
        # Check if the file already exists
        if [ "$use_subdirectories" = true ]; then
            if [ ! -f "$file_path" ]; then
                curl -s https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${champion}_$skin_num.jpg -o "$file_path"
            elif [ "$force_download" = true ]; then
                curl -s https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${champion}_$skin_num.jpg -o "$file_path"
            fi
        else
            if [ ! -f "$file_path" ]; then
                curl -s https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${champion}_$skin_num.jpg -o "$file_path"
            elif [ "$force_download" = true ]; then
                curl -s https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${champion}_$skin_num.jpg -o "$file_path"
            fi
        fi
    done
done

echo -ne "\nDownload complete.\n"
