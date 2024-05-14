#!/bin/bash

# Create the download directory if it doesn't exist
mkdir -p ./download

# Get the latest version of DDragon
latest_version=$(curl -s https://ddragon.leagueoflegends.com/api/versions.json | jq -r '.[0]')
echo "Latest DDragon version: $latest_version"

# Get the list of all champions
champion_list=$(curl -s https://ddragon.leagueoflegends.com/cdn/$latest_version/data/en_US/champion.json | jq -r '.data | keys[]')

# Loop through all champions
for champion in $champion_list; do
    # Create a directory for each champion
    mkdir -p ./download/$champion

    # Download the champion's official artwork
    curl -s https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${champion}_0.jpg -o ./download/$champion/${champion}_0.jpg

    # Get the list of skins for the champion
    skin_list=$(curl -s https://ddragon.leagueoflegends.com/cdn/$latest_version/data/en_US/champion/${champion}.json | jq -r '.data[].skins[].num')

    # Loop through all skins and download their artwork
    for skin in $skin_list; do
        curl -s https://ddragon.leagueoflegends.com/cdn/img/champion/splash/${champion}_$skin.jpg -o ./download/$champion/${champion}_$skin.jpg
    done
done

echo "Download complete."
