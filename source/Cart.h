#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 g_romSize;
extern u32 maxRomSize;
extern u32 emuFlags;
extern u8 g_cartFlags;
extern u8 g_configSet;
extern u8 g_config;
extern u8 g_machine;
extern u8 g_machineSet;
extern u8 g_lang;
extern u8 g_paletteBank;
extern int sramSize;
extern int eepromSize;

extern u8 wsRAM[0x10000];
extern u8 wsSRAM[0x8000];
extern u8 extEepromMem[0x800];
extern u8 biosSpace[0x1000];
extern u8 biosSpaceColor[0x2000];
extern u8 *romSpacePtr;
extern void *g_BIOSBASE_BNW;
extern void *g_BIOSBASE_COLOR;

void machineInit(void);
void loadCart(int emuFlags);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
