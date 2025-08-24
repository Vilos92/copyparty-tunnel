#!/bin/bash

# --- Configuration ---
GITHUB_OWNER="vilos92"
IMAGE_NAME="copyparty-tunnel"
TAG="" # We will detect this if not provided
PUSH_IMAGE=false

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --push)
        PUSH_IMAGE=true
        shift
        ;;
        --tag)
        TAG="$2"
        shift; shift
        ;;
        *)
        shift
        ;;
    esac
done

# --- Version Detection ---
if [ -z "$TAG" ]; then
    echo "ℹ️ No --tag provided. Detecting latest version from PyPI..."
    DETECTED_TAG=$(curl -s https://pypi.org/pypi/copyparty/json | jq -r '.info.version')
    if [ -z "$DETECTED_TAG" ] || [ "$DETECTED_TAG" == "null" ]; then
        echo "❌ Could not detect version. Exiting."
        exit 1
    fi
    TAG=$DETECTED_TAG
    echo "✅ Detected version: $TAG"
fi

# --- Main Logic ---
FULL_IMAGE_NAME="ghcr.io/$GITHUB_OWNER/$IMAGE_NAME:$TAG"
LATEST_IMAGE_NAME="ghcr.io/$GITHUB_OWNER/$IMAGE_NAME:latest"

# --- Pre-Build Check ---
# Check if the image already exists locally. If it does, skip the build.
if docker image inspect "$FULL_IMAGE_NAME" &>/dev/null; then
    echo "✅ Image $FULL_IMAGE_NAME already exists locally. Skipping build."
else
    echo "▶️ Building image: $FULL_IMAGE_NAME"
    docker build --build-arg COPYPARTY_VERSION=$TAG -t "$FULL_IMAGE_NAME" .
fi

# --- Push Logic ---
if [ "$PUSH_IMAGE" = true ]; then
    echo "▶️ Pushing versioned tag: $FULL_IMAGE_NAME"
    docker push "$FULL_IMAGE_NAME"

    echo "🔎 Checking if this is the newest version..."
    HIGHEST_VERSION=$( (gh api "users/$GITHUB_OWNER/packages/container/$IMAGE_NAME/versions" -q '.[] | .metadata.container.tags[]' 2>/dev/null; echo $TAG) | \
        grep -v "latest" | \
        sort -V | \
        tail -n 1 )

    if [ "$TAG" == "$HIGHEST_VERSION" ]; then
        echo "🏆 This is the newest version! Tagging and pushing 'latest'."
        docker tag "$FULL_IMAGE_NAME" "$LATEST_IMAGE_NAME"
        docker push "$LATEST_IMAGE_NAME"
    else
        echo "ℹ️ Version $TAG is not the latest. The latest version is $HIGHEST_VERSION. Skipping 'latest' tag."
    fi
fi

echo "✅ Script finished."
