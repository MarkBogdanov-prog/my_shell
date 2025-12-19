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

# Проверка зависимостей
DEPS := fuse3 libfuse3-dev g++ make
CHECK_DEPS := $(shell dpkg -s $(DEPS) >/dev/null 2>&1 || echo "deps_missing")

.PHONY: all clean deb run deps install-deps docker-build docker-test docker-clean

all: deps $(TARGET)

# Проверка и установка зависимостей
deps:
ifeq ($(CHECK_DEPS),deps_missing)
	@echo "Устанавливаю зависимости..."
	@sudo apt-get update
	@sudo apt-get install -y $(DEPS)
	@echo "Зависимости установлены!"
else
	@echo "Все зависимости установлены ✓"
endif

install-deps:
	@sudo apt-get update
	@sudo apt-get install -y $(DEPS)

# Основные цели
$(TARGET): $(SOURCES) deps
	$(CXX) $(CXXFLAGS) -o $@ $(SOURCES) $(LDFLAGS)

deb: deps $(TARGET) | $(BUILD_DIR) $(INSTALL_DIR)
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

# Docker цели (без изменений)
docker-build: deb
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE) -f Dockerfile.test .

docker-test: docker-build
	@echo "Running Docker tests..."
	docker run --rm --privileged \
		-v /dev:/dev:ro \
		--name $(TEST_CONTAINER) \
		$(DOCKER_IMAGE) \
		/bin/bash -c "/test/test_kubsh.sh"

docker-clean:
	-docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	-docker container prune -f
