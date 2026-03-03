/*
 * KingsCourt KA Lite Launcher
 *
 * This .exe extracts setup-kalite.bat to a temp location and runs it.
 * The bat file handles all installation, start, stop logic.
 *
 * Compile with:
 *   x86_64-w64-mingw32-gcc -o setup-kalite.exe launcher.c -lshlwapi -mwindows -mconsole
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

/* The bat file content is embedded at compile time via xxd */
#include "setup-kalite-bat.h"

int main(int argc, char *argv[]) {
    char temp_path[MAX_PATH];
    char bat_path[MAX_PATH];
    char cmd[MAX_PATH * 2];
    FILE *f;

    /* Get temp directory */
    GetTempPathA(MAX_PATH, temp_path);
    snprintf(bat_path, MAX_PATH, "%ssetup-kalite.bat", temp_path);

    /* Write the embedded bat file to temp */
    f = fopen(bat_path, "wb");
    if (!f) {
        printf("ERROR: Could not create temp file: %s\n", bat_path);
        return 1;
    }
    fwrite(setup_kalite_bat, 1, setup_kalite_bat_len, f);
    fclose(f);

    /* Build command with any passed arguments (start/stop/status) */
    if (argc > 1) {
        snprintf(cmd, sizeof(cmd), "cmd.exe /c \"%s\" %s", bat_path, argv[1]);
    } else {
        snprintf(cmd, sizeof(cmd), "cmd.exe /c \"%s\"", bat_path);
    }

    /* Run it */
    int ret = system(cmd);

    /* Clean up temp bat file */
    DeleteFileA(bat_path);

    return ret;
}
