PORT ?= $(shell find /dev/ -name ttyUSB* -or -name ttyACM* | head -1)
BUILDDIR ?= launcher/build
IDF_PATH ?= $(shell pwd)/esp-idf
IDF_EXPORT_QUIET ?= 0
SHELL := /usr/bin/env bash

.PHONY: prepare clean build flash erase monitor menuconfig image qemu install size size-components size-files format

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

build:
	make -C bootloader build
	source "$(IDF_PATH)/export.sh" && cd launcher && idf.py build

flash: build
	source "$(IDF_PATH)/export.sh" && \
	esptool.py -b 921600 --port "$(PORT)" \
		write_flash --flash_mode dio --flash_freq 80m --flash_size 2MB \
		0x0 bootloader/build/kbbl.bin \
		0x8000 launcher/build/partition_table/partition-table.bin \
		0x10000 launcher/build/C6_AppFS.bin \
		0x50000 bootloader/port/esp32c6/bin/appfs.bin

erase:
	source "$(IDF_PATH)/export.sh" && idf.py erase-flash -p $(PORT)

monitor:
	source "$(IDF_PATH)/export.sh" && cd launcher && idf.py monitor -p $(PORT)

menuconfig:
	source "$(IDF_PATH)/export.sh" && cd launcher && idf.py menuconfig

image:
	cd "$(BUILDDIR)"; dd if=/dev/zero bs=1M count=16 of=flash.bin
	cd "$(BUILDDIR)"; dd if=bootloader/bootloader.bin bs=1 seek=4096 of=flash.bin conv=notrunc
	cd "$(BUILDDIR)"; dd if=partition_table/partition-table.bin bs=1 seek=36864 of=flash.bin conv=notrunc
	cd "$(BUILDDIR)"; dd if=main.bin bs=1 seek=65536 of=flash.bin conv=notrunc
