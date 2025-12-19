CXX := g++
CXXFLAGS := -O2 -std=c++17 -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=35
LDFLAGS := -static -lfuse3 -pthread -ldl

TARGET := kubsh
SOURCES := main.cpp vfs.cpp

PACKAGE_NAME := $(TARGET)
VERSION := 1.0
ARCH := amd64
DEB_FILENAME := kubsh.deb

BUILD_DIR := deb_build
INSTALL_DIR := $(BUILD_DIR)/usr/local/bin

.PHONY: all clean deb-static install-deps

all: $(TARGET)

install-deps:
  apt-get update
  apt-get install -y g++ make libfuse3-dev fuse3 pkg-config

$(TARGET): $(SOURCES)
  $(CXX) $(CXXFLAGS) -o $@ $(SOURCES) $(LDFLAGS)

deb: $(TARGET) | $(BUILD_DIR) $(INSTALL_DIR)
  cp $(TARGET) $(INSTALL_DIR)/
  
  # Проверяем, что бинарник действительно статический
  @echo "Checking if binary is static..."
  @if file $(TARGET) | grep -q "statically linked"; then \
    echo "✓ Binary is statically linked"; \
  else \
    echo "✗ Binary is NOT statically linked!"; \
    exit 1; \
  fi

  mkdir -p $(BUILD_DIR)/DEBIAN

  @echo "Package: $(PACKAGE_NAME)" > $(BUILD_DIR)/DEBIAN/control
  @echo "Version: $(VERSION)" >> $(BUILD_DIR)/DEBIAN/control
  @echo "Architecture: $(ARCH)" >> $(BUILD_DIR)/DEBIAN/control
  @echo "Maintainer: $(USER)" >> $(BUILD_DIR)/DEBIAN/control
  @echo "Description: Simple shell with VFS using FUSE3 (statically linked)" >> $(BUILD_DIR)/DEBIAN/control
  @echo "Depends:" >> $(BUILD_DIR)/DEBIAN/control  # Обратите внимание на двоеточие и пустую строку после
  @echo "" >> $(BUILD_DIR)/DEBIAN/control  # Добавляем пустую строку в конце

  dpkg-deb --build $(BUILD_DIR) $(DEB_FILENAME)

$(BUILD_DIR) $(INSTALL_DIR):
  mkdir -p $@

clean:
  rm -rf $(TARGET) $(BUILD_DIR) kubsh.deb kubsh.deb
