PORT ?= $(shell find /dev/ -name ttyUSB* -or -name ttyACM* | head -1)
BUILDDIR ?= launcher/build
IDF_PATH ?= $(shell pwd)/esp-idf
IDF_EXPORT_QUIET ?= 0
SHELL := /usr/bin/env bash

.PHONY: all prepare clean fullclean bl-build build flash bl-flash erase monitor menuconfig

all: build flash

prepare:
	git submodule update --init --recursive
	rm -rf "$(IDF_PATH)"
	git clone --recursive --branch v5.1.2 https://github.com/espressif/esp-idf.git
	cd "$(IDF_PATH)"; bash install.sh

clean:
	rm -rf "$(BUILDDIR)"

fullclean:
	source "$(IDF_PATH)/export.sh" && cd launcher && idf.py fullclean

bl-build:
	$(MAKE) -C bootloader build

build:
	source "$(IDF_PATH)/export.sh" && cd launcher && idf.py build

flash: bl-build build
	source "$(IDF_PATH)/export.sh" && \
	esptool.py -b 921600 --port "$(PORT)" \
		write_flash --flash_mode dio --flash_freq 80m --flash_size 2MB \
		0x0 bootloader/build/kbbl.bin \
		0x8000 launcher/build/partition_table/partition-table.bin \
		0x10000 launcher/build/C6_AppFS.bin \
		0x110000 bootloader/port/esp32c6/bin/appfs.bin

bl-flash: bl-build
	source "$(IDF_PATH)/export.sh" && \
	esptool.py -b 921600 --port "$(PORT)" \
		write_flash --flash_mode dio --flash_freq 80m --flash_size 2MB \
		0x0 bootloader/build/kbbl.bin

erase:
	source "$(IDF_PATH)/export.sh" && esptool.py erase_flash -p $(PORT)

monitor:
	source "$(IDF_PATH)/export.sh" && cd launcher && idf.py monitor -p $(PORT)

menuconfig:
	source "$(IDF_PATH)/export.sh" && cd launcher && idf.py menuconfig
