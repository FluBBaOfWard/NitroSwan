#ifndef FILEHANDLING_HEADER
#define FILEHANDLING_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "Emubase.h"
#include "WonderSwan.h"

#define FILEEXTENSIONS ".ws.wsc.pc2.pcv2"

extern ConfigData cfg;

int initSettings(void);
bool updateSettingsFromWS(void);
/// Load user settings and internal eeprom.
int loadSettings(void);
/// Save user settings and internal eeprom.
void saveSettings(void);
bool loadGame(const char *gameName);
void checkMachine(void);
/// Load SRAM, EEPROM and/or Flash if they exist.
void loadNVRAM(void);
/// Save SRAM, EEPROM and/or Flash if they exist.
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
void selectIPS(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // FILEHANDLING_HEADER
