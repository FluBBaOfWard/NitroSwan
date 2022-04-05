#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "WSEEPROM/WSEEPROM.h"

extern u32 gRomSize;
extern u32 maxRomSize;
extern u8 gConfig;
extern u8 gMachine;
extern u8 gMachineSet;
extern u8 gSOC;
extern u8 gLang;
extern u8 gPaletteBank;
extern u8 gGameID;
extern int sramSize;
extern int eepromSize;
extern WSEEPROM extEeprom;

extern u8 wsRAM[0x10000];
extern u8 wsSRAM[0x8000];
extern u8 extEepromMem[0x800];
extern u8 biosSpace[0x1000];
extern u8 biosSpaceColor[0x2000];
extern u8 biosSpaceCrystal[0x2000];
extern u8 *romSpacePtr;
extern void *g_BIOSBASE_BNW;
extern void *g_BIOSBASE_COLOR;
extern void *g_BIOSBASE_CRYSTAL;

void machineInit(void);
void loadCart(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
