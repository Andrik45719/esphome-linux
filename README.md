# ESPHome BlueZ BLE Proxy

A lightweight Bluetooth Low Energy proxy that bridges BlueZ D-Bus API to the ESPHome Native API, enabling Home Assistant integration on embedded Linux devices.

## Features

- **ESPHome Native API compatibility** - Full protobuf-based protocol implementation
- **BLE scanning via BlueZ** - Uses system Bluetooth stack (BlueZ 5.x)
- **Periodic batch reporting** - Efficient device discovery with configurable intervals
- **Device caching** - Intelligent advertisement aggregation
- **Multi-client support** - Handle multiple Home Assistant connections
- **Cross-platform** - Works on x86, ARM, MIPS, and other architectures
- **Zero configuration** - Automatic mDNS advertisement (via external tools)

## Use Cases

- Embedded IP cameras with Bluetooth (e.g., Thingino firmware)
- Single-board computers (Raspberry Pi, Orange Pi, etc.)
- IoT gateways and edge devices
- Any Linux device with Bluetooth hardware

## Dependencies

### Build Dependencies

- **Meson** >= 0.55.0 - Build system
- **Ninja** - Build backend
- **pkg-config** - Dependency discovery
- **GCC** or **Clang** - C11 compiler

### Runtime Dependencies

- **D-Bus** >= 1.6 (`libdbus-1`)
- **GLib** >= 2.40 (`libglib-2.0`)
- **BlueZ** >= 5.x - Bluetooth stack (`bluetoothd`)
- **pthread** - POSIX threads

## Building

### Native Build

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt-get install meson ninja-build pkg-config \
  libdbus-1-dev libglib2.0-dev

# Configure
meson setup build

# Build
meson compile -C build

# Install (optional)
sudo meson install -C build
```

### Cross-Compilation

Meson makes cross-compilation straightforward. Create a cross-file or modify `cross/mips-linux.txt`:

```ini
[binaries]
c = 'mipsel-linux-gcc'
ar = 'mipsel-linux-ar'
strip = 'mipsel-linux-strip'
pkg-config = 'pkg-config'

[properties]
sys_root = '/path/to/sysroot'
pkg_config_libdir = '/path/to/sysroot/usr/lib/pkgconfig'

[host_machine]
system = 'linux'
cpu_family = 'mips'
cpu = 'mips32'
endian = 'little'
```

Then build:

```bash
meson setup build --cross-file cross/mips-linux.txt
meson compile -C build
```

### Alternative: Using CROSS_COMPILE

If you prefer traditional `CROSS_COMPILE` variable:

```bash
# Set compiler via environment
export CC=mipsel-linux-gcc
export AR=mipsel-linux-ar
export PKG_CONFIG_PATH=/path/to/sysroot/usr/lib/pkgconfig

meson setup build
meson compile -C build
```

## Running

### Prerequisites

1. **BlueZ daemon must be running:**
   ```bash
   sudo systemctl start bluetooth
   # or
   sudo bluetoothd
   ```

2. **D-Bus system bus must be accessible:**
   ```bash
   # Check D-Bus is running
   dbus-daemon --system
   ```

3. **Optional: mDNS for discovery:**
   ```bash
   # Avahi (recommended)
   avahi-daemon

   # Or add manual DNS-SD entry
   # Service type: _esphomelib._tcp
   # Port: 6053
   ```

### Start the Service

```bash
./build/esphome-ble-proxy
```

The service will:
- Listen on TCP port **6053**
- Connect to BlueZ via D-Bus
- Start BLE scanning
- Report devices every 10 seconds
- Remove devices not seen for 60 seconds

### Integration with Home Assistant

1. The proxy advertises itself via mDNS as `_esphomelib._tcp`
2. Home Assistant auto-discovers it as an ESPHome device
3. Add it through the ESPHome integration
4. It will appear as a Bluetooth Proxy
5. BLE devices are forwarded to Home Assistant

## Configuration

Currently configuration is compile-time via constants in the source:

- **Report interval**: 10 seconds (`REPORT_INTERVAL_MS` in `ble_scanner.c`)
- **Device timeout**: 60 seconds (`DEVICE_TIMEOUT_MS` in `ble_scanner.c`)
- **TCP port**: 6053 (standard ESPHome API port)
- **Device name**: Hostname (auto-detected)

## Architecture

```
┌─────────────────────┐
│  Home Assistant     │
│  (ESPHome Client)   │
└──────────┬──────────┘
           │ TCP 6053 (ESPHome Native API)
           │ Protobuf framed messages
           │
┌──────────▼──────────┐
│  esphome-ble-proxy  │
│                     │
│  ┌───────────────┐  │
│  │ ESPHome API   │  │  - Hello/Connect handshake
│  │ Server        │  │  - Device info response
│  └───────┬───────┘  │  - BLE advertisement batching
│          │          │
│  ┌───────▼───────┐  │
│  │ BLE Scanner   │  │  - D-Bus integration
│  │ (BlueZ)       │  │  - Device caching
│  └───────┬───────┘  │  - Periodic reporting
│          │          │
└──────────┼──────────┘
           │ D-Bus
┌──────────▼──────────┐
│     bluetoothd      │  - BLE scanning
│     (BlueZ)         │  - Advertisement parsing
└─────────────────────┘
```

## Project Structure

```
esphome-bluez-ble-proxy/
├── src/
│   ├── main.c              # Entry point
│   ├── esphome_api.c       # ESPHome protocol server
│   ├── esphome_proto.c     # Protobuf encoder/decoder
│   ├── ble_scanner.c       # BlueZ D-Bus BLE scanner
│   └── include/
│       ├── esphome_api.h
│       ├── esphome_proto.h
│       └── ble_scanner.h
├── cross/
│   └── mips-linux.txt      # Example cross-compilation config
├── meson.build             # Build configuration
├── README.md
├── LICENSE
└── .gitignore
```

## Troubleshooting

### No BLE devices appearing

1. Check BlueZ is scanning:
   ```bash
   bluetoothctl
   > scan on
   ```

2. Check D-Bus permissions:
   ```bash
   dbus-send --system --print-reply \
     --dest=org.bluez \
     /org/bluez/hci0 \
     org.freedesktop.DBus.Properties.Get \
     string:org.bluez.Adapter1 string:Discovering
   ```

3. Check service logs for errors

### Home Assistant not discovering proxy

1. Verify mDNS/Avahi is running
2. Check firewall allows TCP port 6053
3. Manually add via ESPHome integration using IP:6053

### Build errors

1. Ensure pkg-config can find dependencies:
   ```bash
   pkg-config --modversion dbus-1 glib-2.0
   ```

2. For cross-compilation, verify sysroot has required libraries

## Performance

- **Memory usage**: ~2-4 MB RSS
- **CPU usage**: <1% idle, ~2-5% during scanning
- **Network**: Minimal (batched reports every 10s)
- **BLE scan rate**: Depends on BlueZ configuration

## License

MIT License - see LICENSE file

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on target hardware
5. Submit a pull request

## Credits

Developed for the [Thingino Project](https://github.com/themactep/thingino-firmware) - open-source firmware for Ingenic SoC cameras.

## Related Projects

- [ESPHome](https://esphome.io/) - Home automation framework
- [Home Assistant](https://www.home-assistant.io/) - Open source home automation
- [BlueZ](http://www.bluez.org/) - Official Linux Bluetooth stack
- [Thingino](https://thingino.com/) - IP camera firmware
