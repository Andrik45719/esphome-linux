#!/bin/bash
# Cross-compilation build script for Ingenic T31 (MIPS)
# Uses Docker multi-stage build for fast rebuilds with cached dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${SDK_DIR:-$(cd "${SCRIPT_DIR}/../../Ingenic-SDK-T31-1.1.1-20200508" && pwd)}"

# Toolchain configuration
TOOLCHAIN_NAME="${TOOLCHAIN_NAME:-mips-gcc540-glibc222-64bit-r3.3.0}"
TOOLCHAIN_BIN="${SDK_DIR}/toolchain/${TOOLCHAIN_NAME}/bin"
TOOLCHAIN_PREFIX="${TOOLCHAIN_PREFIX:-mips-linux-gnu}"

# Docker image tag
DOCKER_IMAGE="esphome-linux-cross"
DOCKER_TAG="${DOCKER_TAG:-latest}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Cross-compiling esphome-linux for Ingenic T31 (MIPS)${NC}"

# Verify SDK exists
if [ ! -d "${SDK_DIR}" ]; then
    echo -e "${RED}Error: Ingenic SDK not found at: ${SDK_DIR}${NC}"
    echo -e "${YELLOW}Set SDK_DIR environment variable or place SDK at ../Ingenic-SDK-T31-1.1.1-20200508${NC}"
    echo -e "${YELLOW}or run scripts/setup-ingenic-sdk.sh to install the appropriate files"
    exit 1
fi

echo -e "${GREEN}Using SDK: ${SDK_DIR}${NC}"
echo -e "${YELLOW}Building with Docker (dependencies cached in layers)...${NC}"

# Clean previous build
rm -rf "${SCRIPT_DIR}/esphome-linux-mips"

# Build with Docker using BuildKit (required for bind mounts)
echo -e "${GREEN}Building Docker image with multi-stage caching...${NC}"
DOCKER_BUILDKIT=1 docker build \
    --platform linux/amd64 \
    --progress plain \
    -f cross.Dockerfile \
    -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
    --build-context sdk-mount="${SDK_DIR}" \
    --build-arg TOOLCHAIN_BIN="/sdk/toolchain/${TOOLCHAIN_NAME}/bin" \
    --build-arg CROSS_COMPILE="${TOOLCHAIN_PREFIX}-" \
    --build-arg CC="${TOOLCHAIN_PREFIX}-gcc" \
    --build-arg CXX="${TOOLCHAIN_PREFIX}-g++" \
    --build-arg AR="${TOOLCHAIN_PREFIX}-ar" \
    --build-arg AS="${TOOLCHAIN_PREFIX}-as" \
    --build-arg LD="${TOOLCHAIN_PREFIX}-ld" \
    --build-arg RANLIB="${TOOLCHAIN_PREFIX}-ranlib" \
    --build-arg STRIP="${TOOLCHAIN_PREFIX}-strip" \
    --target builder \
    .

# Extract binary from the build stage
echo -e "${GREEN}Extracting binary...${NC}"
container_id=$(docker create ${DOCKER_IMAGE}:${DOCKER_TAG})
docker cp ${container_id}:/workspace/build-mips/esphome-linux "${SCRIPT_DIR}/../esphome-linux-mips"
docker rm ${container_id}

# Extract dependencies archive from the deps stage
echo -e "${GREEN}Extracting dependencies archive...${NC}"
rm -rf "${SCRIPT_DIR}/../output-mips-deps"
DOCKER_BUILDKIT=1 docker build \
    --platform linux/amd64 \
    --progress plain \
    -f cross.Dockerfile \
    --build-context sdk-mount="${SDK_DIR}" \
    --build-arg TOOLCHAIN_BIN="/sdk/toolchain/${TOOLCHAIN_NAME}/bin" \
    --build-arg CROSS_COMPILE="${TOOLCHAIN_PREFIX}-" \
    --build-arg CC="${TOOLCHAIN_PREFIX}-gcc" \
    --build-arg CXX="${TOOLCHAIN_PREFIX}-g++" \
    --build-arg AR="${TOOLCHAIN_PREFIX}-ar" \
    --build-arg AS="${TOOLCHAIN_PREFIX}-as" \
    --build-arg LD="${TOOLCHAIN_PREFIX}-ld" \
    --build-arg RANLIB="${TOOLCHAIN_PREFIX}-ranlib" \
    --build-arg STRIP="${TOOLCHAIN_PREFIX}-strip" \
    --target deps \
    --output type=local,dest="${SCRIPT_DIR}/../output-mips-deps" \
    . > /dev/null 2>&1

if [ -f "${SCRIPT_DIR}/../output-mips-deps/deps.tar.gz" ]; then
    mv "${SCRIPT_DIR}/../output-mips-deps/deps.tar.gz" "${SCRIPT_DIR}/../deps-mips.tar.gz"
    rm -rf "${SCRIPT_DIR}/../output-mips-deps"
fi

# Check if binary exists
if [ -f "${SCRIPT_DIR}/../esphome-linux-mips" ]; then
    echo -e "${GREEN}✓ Cross-compilation successful!${NC}"
    echo -e "Binary location: ${SCRIPT_DIR}/../esphome-linux-mips"
    file "${SCRIPT_DIR}/../esphome-linux-mips"

    # Show dependencies
    echo -e "${GREEN}Dependencies:${NC}"
    docker run --rm \
        -v "${SDK_DIR}":/sdk:ro \
        -v "${SCRIPT_DIR}":/work \
        ${DOCKER_IMAGE}:${DOCKER_TAG} \
        /sdk/toolchain/mips-gcc540-glibc222-64bit-r3.3.0/bin/mips-linux-gnu-readelf -d /work/esphome-linux-mips | grep NEEDED || true
else
    echo -e "${RED}✗ Binary not found. Check the build output above.${NC}"
    exit 1
fi

# Check if dependencies archive exists
if [ -f "${SCRIPT_DIR}/../deps-mips.tar.gz" ]; then
    echo -e "${GREEN}✓ Dependencies archive: ${SCRIPT_DIR}/../deps-mips.tar.gz${NC}"
else
    echo -e "${YELLOW}⚠ Dependencies archive not found${NC}"
fi
