# SPDX-License-Identifier: GPL-2.0
# Simplified Makefile for building libbluetooth shared library

# Compiler and flags
CC ?= gcc

CFLAGS = -Wall -Wextra -O2 -fPIC
LDFLAGS ?= -shared
INCLUDES = -I.

# Library name and version
LIBNAME = libbluetooth.so.3
LIBNAME_SHORT = libbluetooth.so

# Install directories
PREFIX ?= ../out
LIBDIR = $(PREFIX)/lib
INCLUDEDIR = $(PREFIX)/include/bluetooth

# Source files from lib/
LIB_DIR = lib
SOURCES = $(LIB_DIR)/bluetooth.c \
          $(LIB_DIR)/hci.c \
          $(LIB_DIR)/uuid.c

# Object files
OBJECTS = $(SOURCES:.c=.o)

# Default target
all: $(LIBNAME)

# Build the shared library
$(LIBNAME): $(OBJECTS)
	@echo "Creating shared library: $@"
	$(CC) $(LDFLAGS) -Wl,-soname,$(LIBNAME) -o $@ $^

# Compile source files to object files
%.o: %.c
	@echo "Compiling: $<"
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Install target
install: $(LIBNAME)
	@echo "Installing library to $(LIBDIR)..."
	@mkdir -p $(LIBDIR)
	@cp $(LIBNAME) $(LIBDIR)/
	@ln -sf $(LIBNAME) $(LIBDIR)/$(LIBNAME_SHORT)
	@echo "Installing headers to $(INCLUDEDIR)..."
	@mkdir -p $(INCLUDEDIR)
	@cp $(LIB_DIR)/*.h $(INCLUDEDIR)/
	@echo "Installation complete"

# Clean target
clean:
	rm -f $(OBJECTS) $(LIBNAME)
	rm -rf $(PREFIX)

.PHONY: all clean install