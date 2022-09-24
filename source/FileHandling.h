#ifndef FILEHANDLING_HEADER
#define FILEHANDLING_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "Emubase.h"
#include "WonderSwan.h"

#define FILEEXTENSIONS ".ws.wsc.pc2"

extern ConfigData cfg;

int initSettings(void);
bool updateSettingsFromWS(void);
int loadSettings(void);
void saveSettings(void);
bool loadGame(const char *gameName);
void checkMachine(void);
void loadNVRAM(void);
void saveNVRAM(void);
void loadState(void);
void saveState(void);
void ejectCart(void);
void selectGame(void);
void selectBnWBios(void);
void selectColorBios(void);
void selectCrystalBios(void);
int loadBnWBIOS(void);
int loadColorBIOS(void);
int loadCrystalBIOS(void);
int loadIntEeproms(void);
int saveIntEeproms(void);
void selectEEPROM(void);
void clearIntEeproms(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // FILEHANDLING_HEADER
