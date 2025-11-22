#!/usr/bin/env bash
set -e

BLUEZ_VERSION="5.79"
BLUEZ_URL="https://github.com/bluez/bluez/archive/refs/tags/${BLUEZ_VERSION}.tar.gz"
BLUEZ_DIR="bluez-${BLUEZ_VERSION}"
BLUEZ_ARCHIVE="${BLUEZ_VERSION}.tar.gz"

# Download BlueZ source if not already present
if [ ! -d "$BLUEZ_DIR" ]; then
    echo "Downloading BlueZ ${BLUEZ_VERSION}..."
    wget -O "$BLUEZ_ARCHIVE" "$BLUEZ_URL" || curl -L -o "$BLUEZ_ARCHIVE" "$BLUEZ_URL"

    echo "Extracting BlueZ source..."
    tar -xzf "$BLUEZ_ARCHIVE"
fi

# Copy Makefile into the source directory
echo "Copying Makefile to ${BLUEZ_DIR}..."
cp Makefile "${BLUEZ_DIR}/"

# Build and install libbluetooth inside the source directory
echo "Building libbluetooth..."
cd "${BLUEZ_DIR}"
make clean
make
make install

echo "BlueZ library built and installed successfully"
echo "Library: $(pwd)/../out/lib/libbluetooth.so.3"
echo "Headers: $(pwd)/../out/include/bluetooth"