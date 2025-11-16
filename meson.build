project('esphome-bluez-ble-proxy', 'c',
  version: '1.0.0',
  license: 'MIT',
  default_options: [
    'warning_level=2',
    'c_std=c11',
    'buildtype=release',
  ],
)

# Dependencies - automatically uses pkg-config
dbus_dep = dependency('dbus-1', version: '>=1.6')
glib_dep = dependency('glib-2.0', version: '>=2.40')
thread_dep = dependency('threads')

# Source files
sources = files(
  'src/main.c',
  'src/ble_scanner.c',
  'src/esphome_api.c',
  'src/esphome_proto.c',
)

# Include directories
inc = include_directories('src/include')

# Compiler flags
add_project_arguments(
  '-D_GNU_SOURCE',
  language: 'c'
)

# Executable
executable('esphome-ble-proxy',
  sources,
  include_directories: inc,
  dependencies: [dbus_dep, glib_dep, thread_dep],
  install: true,
)

# Summary
summary({
  'prefix': get_option('prefix'),
  'bindir': get_option('bindir'),
  'D-Bus': dbus_dep.version(),
  'GLib': glib_dep.version(),
}, section: 'Configuration')
