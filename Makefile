# Компилятор и флаги
CXX := g++
CXXFLAGS := -O2 -std=c++17 -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=35
LDFLAGS := -lfuse3 -pthread

# Имя программы
TARGET := kubsh

# Исходные файлы
SOURCES := main.cpp vfs.cpp

# Настройки пакета
PACKAGE_NAME := $(TARGET)
VERSION := 1.0
ARCH := amd64
DEB_FILENAME := kubsh.deb

# Временные директории
BUILD_DIR := deb_build
INSTALL_DIR := $(BUILD_DIR)/usr/local/bin

# Docker
DOCKER_IMAGE := kubsh-local
TEST_CONTAINER := kubsh-test-$(shell date +%s)

.PHONY: all clean deb run

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CXX) $(CXXFLAGS) -o $@ $(SOURCES) $(LDFLAGS)

deb: $(TARGET) | $(BUILD_DIR) $(INSTALL_DIR)
	# Копируем бинарник
	cp $(TARGET) $(INSTALL_DIR)/
	
	# Создаем базовую структуру пакета
	mkdir -p $(BUILD_DIR)/DEBIAN
	
	# Генерируем контрольный файл
	@echo "Package: $(PACKAGE_NAME)" > $(BUILD_DIR)/DEBIAN/control
	@echo "Version: $(VERSION)" >> $(BUILD_DIR)/DEBIAN/control
	@echo "Architecture: $(ARCH)" >> $(BUILD_DIR)/DEBIAN/control
	@echo "Maintainer: $(USER)" >> $(BUILD_DIR)/DEBIAN/control
	@echo "Description: Simple shell with VFS using FUSE3" >> $(BUILD_DIR)/DEBIAN/control
	@echo "Depends: fuse3" >> $(BUILD_DIR)/DEBIAN/control
	
	# Собираем пакет с фиксированным именем
	dpkg-deb --build $(BUILD_DIR) $(DEB_FILENAME)

$(BUILD_DIR) $(INSTALL_DIR):
	mkdir -p $@

clean:
	rm -rf $(TARGET) $(BUILD_DIR) $(DEB_FILENAME)

run: $(TARGET)
	./$(TARGET)
