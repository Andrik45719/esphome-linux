# Bluetooth Proxy Plugin

Core plugin that provides Bluetooth LE scanning functionality via libblepp HCI interface.

## Overview

This plugin:
- Scans for BLE advertisements using direct HCI access via libblepp
- Forwards advertisements to Home Assistant via ESPHome Native API
- Handles subscription/unsubscription requests from clients
- Caches and batches advertisements for efficient reporting

## Features

- **Passive BLE scanning** - Low power consumption using HCI
- **Advertisement caching** - Deduplicates and batches reports
- **Periodic reporting** - Reports devices every 10 seconds
- **Stale device removal** - Cleans up devices not seen for 60 seconds
- **Full advertisement data** - Manufacturer data, service UUIDs, service data
- **Direct HCI access** - No D-Bus dependency, more efficient

## Requirements

- libblepp library (from ~/github/libblepp)
- Bluetooth adapter (hci0)
- Root/CAP_NET_ADMIN capability (required for HCI socket access)

## ESPHome Messages Handled

- `ESPHOME_MSG_SUBSCRIBE_BLUETOOTH_LE_ADVERTISEMENTS_REQUEST` (66)
  - Starts BLE scanning
  - Client subscribes to advertisement stream

- `ESPHOME_MSG_UNSUBSCRIBE_BLUETOOTH_LE_ADVERTISEMENTS_REQUEST` (80)
  - Stops BLE scanning
  - Client unsubscribes from advertisements

## ESPHome Messages Sent

- `ESPHOME_MSG_BLUETOOTH_LE_RAW_ADVERTISEMENTS_RESPONSE` (93)
  - Contains BLE advertisement data
  - Sent periodically (every 10s) for discovered devices

## Architecture

```
Bluetooth HCI (/dev/hci0)
      │
      ▼ HCI Socket
BLEClientTransport (BlueZ or Nimble)
      │
      ▼ Transport API
libblepp BLEScanner
      │
      ▼ C++ API
BLE Scanner (ble_scanner.cpp)
      │
      ▼ C Callbacks
Bluetooth Proxy Plugin
      │
      ▼ ESPHome API
Home Assistant
```

## Files

- `bluetooth_proxy_plugin.c` - Plugin wrapper, handles ESPHome messages
- `ble_scanner.cpp` - libblepp HCI integration, BLE scanning logic (C++)
- `ble_scanner.h` - BLE scanner C API
- `meson.build` - Build configuration for libblepp integration
- `README.md` - This file

## Building

The plugin requires libblepp to be built first:

```bash
# Build libblepp
cd ~/github/libblepp
mkdir -p build && cd build
cmake .. -DWITH_EXAMPLES=OFF
make

# Build esphome-linux with Bluetooth Proxy
cd ~/github/esphome-linux
meson setup builddir
meson compile -C builddir
```

## Configuration

No configuration needed - automatically starts when Home Assistant subscribes.

## Testing

```bash
# Check for Bluetooth adapter
hciconfig

# Verify HCI access (requires root)
sudo hcitool lescan

# Run esphome-linux (requires root for HCI)
sudo ./builddir/esphome-linux
```

## Troubleshooting

**BLE scanner fails to initialize:**
- Check adapter exists: `hciconfig`
- Ensure running as root or with CAP_NET_ADMIN: `sudo ./esphome-linux`
- Check libblepp is built in ~/github/libblepp/build

**No advertisements received:**
- Ensure BLE devices are advertising nearby
- Check adapter is up: `sudo hciconfig hci0 up`
- Test with: `sudo hcitool lescan`

## Future Enhancements

Potential additions to this plugin:
- GATT client operations (read/write characteristics)
- Device connection management
- Bluetooth pairing
- Multiple adapter support
- Advertisement filtering

## License

MIT - Same as main project
