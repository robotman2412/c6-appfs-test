
// SPDX-License-Identifier: MIT

#include <stdio.h>

#include <appfs.h>
#include <esp_log.h>
#include <esp_system.h>

static char const TAG[] = "main";

// AppFS to bootloader magic.
#define APPFS_TOBOOTLOADER_MAGIC 0x89778e48441c5665

// To bootloader data.
typedef struct {
    uint64_t appfs_magic;
    uint8_t  app;
    uint8_t  padding[7];
    char     arg[64];
} tobootloader_t;

#define TOBOOTLOADER (*(tobootloader_t *)0x50000000)

void app_main() {
    appfsInit(APPFS_PART_TYPE, APPFS_PART_SUBTYPE);
    appfs_handle_t handle = appfsOpen("BadgerOS");
    if (handle == APPFS_INVALID_FD) {
        ESP_LOGE(TAG, "File not found");
        return;
    }

    TOBOOTLOADER.appfs_magic = APPFS_TOBOOTLOADER_MAGIC;
    TOBOOTLOADER.app         = handle;

    esp_restart();
}
