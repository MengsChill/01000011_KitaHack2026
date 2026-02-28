#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./change_icon.sh <image_url>"
    exit 1
fi

IMAGE_URL="$1"
TARGET_PATH="assets/launcher_icon.png"

echo "Downloading image from $IMAGE_URL..."
curl -sL "$IMAGE_URL" -o "$TARGET_PATH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download the image."
    exit 1
fi

echo "Image downloaded to $TARGET_PATH."
echo "Updating app icon..."

flutter pub run flutter_launcher_icons

if [ $? -ne 0 ]; then
    echo "Error: Failed to update the app icon."
    exit 1
fi

echo "App icon updated successfully!"
echo "To display the image in the mobile phone, run the application:"
echo "flutter run"
