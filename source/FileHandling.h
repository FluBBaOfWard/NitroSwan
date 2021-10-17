#ifndef FILEHANDLING_HEADER
#define FILEHANDLING_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "Emubase.h"

#define FILEEXTENSIONS ".ws.wsc"

extern ConfigData cfg;

int initSettings(void);
bool updateSettingsFromNGP(void);
int loadSettings(void);
void saveSettings(void);
bool loadGame(const char *gameName);
void loadNVRAM(void);
void saveNVRAM(void);
void loadState(void);
void saveState(void);
void ejectCart(void);
void selectGame(void);
void selectColorBios(void);
void selectBWBios(void);
int loadColorBIOS(void);
int loadBWBIOS(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // FILEHANDLING_HEADER
