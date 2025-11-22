# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for cross-compiling esphome-linux
# Builds nimble and bluez dependencies before building the application

# =============================================================================
# Stage 1: Build dependencies (nimble and bluez)
# =============================================================================
FROM ubuntu:22.04 AS dependencies

ARG TOOLCHAIN_BIN
ARG CROSS_COMPILE
ARG CC
ARG CXX
ARG AR
ARG AS
ARG LD
ARG RANLIB
ARG STRIP

ENV DEBIAN_FRONTEND=noninteractive

# Install build tools
RUN apt-get update && apt-get install -y \
    bash curl make gcc g++ python3-pip ninja-build cmake \
    pkg-config file git wget \
    && pip3 install --no-cache-dir meson \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Set up cross-compilation environment from build args
ENV PATH="${TOOLCHAIN_BIN}:${PATH}" \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    CC="${CC}" \
    CXX="${CXX}" \
    AR="${AR}" \
    AS="${AS}" \
    LD="${LD}" \
    RANLIB="${RANLIB}" \
    STRIP="${STRIP}"

# Copy dependency build scripts and sources
COPY nimble/ nimble/
# Build nimble dependency (must be built first, as libble depends on it)
RUN --mount=type=bind,from=sdk-mount,source=/,target=/sdk,readonly \
    cd nimble && \
    ./build.sh && \
    cd ..

COPY bluez/ bluez/
# Build bluez dependency
RUN --mount=type=bind,from=sdk-mount,source=/,target=/sdk,readonly \
    cd bluez && \
    ./build.sh && \
    cd ..

COPY libble/ libble/
# Build libble dependency (depends on nimble and bluez, uses cross-compiler)
RUN --mount=type=bind,from=sdk-mount,source=/,target=/sdk,readonly \
    cd libble && \
    ./build.sh && \
    cd ..

# =============================================================================
# Stage 2: Build application (rebuilds when source changes)
# =============================================================================
FROM ubuntu:22.04 AS builder

ARG TOOLCHAIN_BIN

ENV DEBIAN_FRONTEND=noninteractive

# Install Meson and build tools
RUN apt-get update && apt-get install -y \
    python3 python3-pip ninja-build cmake pkg-config file \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir meson

# Copy built dependencies from dependencies stage
COPY --from=dependencies /workspace/nimble/out /deps/nimble
COPY --from=dependencies /workspace/bluez/out /deps/bluez
COPY --from=dependencies /workspace/libble/out /deps/libble

# Set up cross-compilation environment - toolchain path and pkg-config for dependencies
ENV PATH="${TOOLCHAIN_BIN}:${PATH}" \
    PKG_CONFIG_PATH="/deps/nimble/lib/pkgconfig:/deps/bluez/lib/pkgconfig:/deps/libble/usr/lib/pkgconfig"

WORKDIR /workspace

# Copy project files
COPY meson.build .
COPY meson_options.txt .
COPY cross/ cross/
COPY src/ src/
COPY plugins/ plugins/

# Configure and build
RUN --mount=type=bind,from=sdk-mount,source=/,target=/sdk,readonly \
    meson setup build-mips --cross-file cross/ingenic-t31.txt && \
    meson compile -C build-mips && \
    file build-mips/esphome-linux

# Create dependencies archive from dependencies stage with flat lib/include structure and license files
RUN --mount=type=bind,from=dependencies,source=/workspace,target=/deps-src,readonly \
    mkdir -p /deps-archive/lib /deps-archive/include /deps-archive/licenses && \
    cp -r /deps-src/nimble/out/lib/* /deps-archive/lib/ && \
    cp -r /deps-src/nimble/out/include/* /deps-archive/include/ && \
    cp -r /deps-src/bluez/out/lib/* /deps-archive/lib/ && \
    cp -r /deps-src/bluez/out/include/* /deps-archive/include/ && \
    cp -r /deps-src/libble/out/usr/lib/* /deps-archive/lib/ && \
    cp -r /deps-src/libble/out/usr/include/* /deps-archive/include/ && \
    cp /deps-src/nimble/atbm-wifi/ble_host/nimble_v42/LICENSE /deps-archive/licenses/NIMBLE-LICENSE && \
    cp /deps-src/bluez/bluez-5.79/COPYING.LIB /deps-archive/licenses/BLUEZ-COPYING.LIB && \
    cp /deps-src/libble/libblepp/COPYING /deps-archive/licenses/LIBBLEPP-COPYING && \
    cd /deps-archive && \
    tar -czf /workspace/deps.tar.gz lib include licenses

# =============================================================================
# Stage 3: Deps archive (for extracting dependencies)
# =============================================================================
FROM scratch AS deps
COPY --from=builder /workspace/deps.tar.gz /deps.tar.gz

# =============================================================================
# Stage 4: Output (minimal layer with just the binary)
# =============================================================================
FROM scratch AS output
COPY --from=builder /workspace/build-mips/esphome-linux /esphome-linux-mips
