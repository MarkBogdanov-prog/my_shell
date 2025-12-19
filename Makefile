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

# Проверка - находимся ли мы в Docker контейнере
IN_DOCKER := $(shell grep -c docker /proc/self/cgroup 2>/dev/null || echo "0")
IS_ROOT := $(shell id -u)

# Зависимости для разных сред
DEPS_UBUNTU := fuse3 libfuse3-dev g++ make
DEPS_ALPINE := fuse3 fuse3-dev g++ make
DEPS_FEDORA := fuse3 fuse3-devel gcc-c++ make

.PHONY: all clean deb run deps install-deps docker-build docker-test docker-clean

all: deps $(TARGET)

# Умная проверка зависимостей - разная для Docker и хоста
deps:
ifeq ($(IN_DOCKER),0)
	# Мы НЕ в Docker - проверяем как обычно
	@echo "Проверяю зависимости на хосте..."
	@if ! dpkg -s $(DEPS_UBUNTU) >/dev/null 2>&1; then \
		echo "Устанавливаю зависимости..."; \
		sudo apt-get update && sudo apt-get install -y $(DEPS_UBUNTU); \
	else \
		echo "Все зависимости установлены ✓"; \
	fi
else
	# Мы В Docker - устанавливаем без sudo
	@echo "Проверяю зависимости в Docker..."
	@if ! dpkg -s $(DEPS_UBUNTU) >/dev/null 2>&1; then \
		echo "Устанавливаю зависимости в Docker..."; \
		apt-get update && apt-get install -y $(DEPS_UBUNTU); \
	else \
		echo "Все зависимости установлены в Docker ✓"; \
	fi
endif

# Альтернативная установка зависимостей
install-deps:
ifeq ($(IN_DOCKER),0)
	@echo "Устанавливаю зависимости на хосте (с sudo)..."
	sudo apt-get update
	sudo apt-get install -y $(DEPS_UBUNTU)
else
	@echo "Устанавливаю зависимости в Docker (без sudo)..."
	apt-get update
	apt-get install -y $(DEPS_UBUNTU)
endif

# Проверка зависимостей без установки
check-deps:
	@echo "Проверка зависимостей..."
	@for dep in $(DEPS_UBUNTU); do \
		if dpkg -s $$dep >/dev/null 2>&1; then \
			echo "✅ $$dep"; \
		else \
			echo "❌ $$dep (отсутствует)"; \
		fi \
	done

# Основная цель сборки
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

# Docker цели - ОСОБЫЕ ПРАВИЛА ДЛЯ DOCKER
docker-build: deb
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE) -f Dockerfile.test .

docker-test: docker-build
	@echo "Running Docker tests..."
	docker run --rm --privileged \
		-v /dev:/dev:ro \
		--name $(TEST_CONTAINER) \
		$(DOCKER_IMAGE) \
		/bin/bash -c "cd /test && make -f /test/Makefile.docker test"

docker-clean:
	-docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	-docker container prune -f

# Цель для быстрой сборки в Docker
docker-quick:
	docker run --rm -v $(PWD):/build -w /build ubuntu:22.04 \
		bash -c "apt-get update && apt-get install -y g++ make && make"
