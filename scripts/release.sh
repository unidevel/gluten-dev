#!/bin/bash
set -e

MODE=$1

if [ -z "$MODE" ]; then
  echo "Usage: $0 [prepare|publish]"
  exit 1
fi

# Default organization if not set
ORG=${ORG:-"prestodb"}
# Default docker registry if not set
DOCKERHUB=${DOCKERHUB:-"ghcr.io"}

# --- Get Version ---
POM_PATH="../pom.xml"
if [ ! -f "$POM_PATH" ]; then
  echo "Error: pom.xml not found in ../"
  exit 1
fi
VERSION=$(grep -m 1 '^  <version>' "$POM_PATH" | sed -e 's/.*<version>\([^<]*\)<\/version>.*/\1/' -e 's/-SNAPSHOT//')
echo "Version: $VERSION"

# --- Get Commit ID ---
COMMIT_ID=$(git -C .. rev-parse --short HEAD)
echo "Commit ID: $COMMIT_ID"

# --- Get Architecture ---
# Use ARCH from environment if set, otherwise detect it
if [ -z "$ARCH" ]; then
  ARCH=$(uname -m)
  if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
  elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
  fi
fi
echo "Architecture: $ARCH"

# --- Define images to process ---
# List of (OLD_IMAGE, OS) tuples
IMAGES_TO_PROCESS=(
  "apache/gluten:dev centos"
)

for IMAGE_INFO in "${IMAGES_TO_PROCESS[@]}"; do
  read -r OLD_IMAGE OS <<<"$IMAGE_INFO"
  NEW_TAG="${DOCKERHUB}/${ORG}/gluten-dev:${VERSION}-${COMMIT_ID}-${ARCH}"
  LATEST_TAG="${DOCKERHUB}/${ORG}/gluten-dev:latest-${ARCH}"

  if [ "$MODE" = "prepare" ]; then
    echo "Tagging ${OLD_IMAGE} as ${NEW_TAG}"
    ${DOCKER_CMD:-docker} tag "${OLD_IMAGE}" "${NEW_TAG}" || echo "No image ${OLD_IMAGE}, skipping"
    echo "Tagging ${OLD_IMAGE} as ${LATEST_TAG}"
    ${DOCKER_CMD:-docker} tag "${OLD_IMAGE}" "${LATEST_TAG}" || echo "No image ${OLD_IMAGE}, skipping"
  elif [ "$MODE" = "publish" ]; then
    echo "Pushing ${NEW_TAG}"
    ${DOCKER_CMD:-docker} push "${NEW_TAG}" || echo "No image ${NEW_TAG}, skipping"
    echo "Pushing ${LATEST_TAG}"
    ${DOCKER_CMD:-docker} push "${LATEST_TAG}" || echo "No image ${LATEST_TAG}, skipping"
  fi
done

echo "Done."
