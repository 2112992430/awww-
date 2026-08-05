#!/usr/bin/env bash

# Base directory where version directories reside
base_dir="/home/xuhuan/.wine/drive_c/Program Files/Wuthering Waves/"

# Check if bbe is installed
if ! command -v bbe &> /dev/null; then
    echo "Error: bbe is not installed. Please install bbe and try again."
    exit 1
fi

# Auto-detect the latest version directory (assumes version directories match the pattern X.Y.Z.W)
version_dir=$(find "$base_dir" -maxdepth 1 -type d -name "[0-9]*.[0-9]*.[0-9]*.[0-9]*" | sort -V | tail -n1)

if [ -z "$version_dir" ]; then
    echo "No version directory found in '$base_dir'."
    exit 1
fi

echo "Using version directory: $version_dir"
cd "$version_dir" || { echo "Failed to change directory to $version_dir"; exit 1; }

# Check if the DLL still contains the original pattern
if ! grep -a -q $'\x12AllowsTransparency' launcher_main.dll; then
    echo "launcher_main.dll is already patched or does not contain the expected pattern."
    exit 0
fi

# Backup the original file and apply the patch using bbe
mv launcher_main.dll launcher_main.dll.bak
bbe -e "s/\x12AllowsTransparency/\x09IsEnabled\x1bA\x00\x03AAAAA/" launcher_main.dll.bak > launcher_main.dll

echo "Patch applied successfully."
