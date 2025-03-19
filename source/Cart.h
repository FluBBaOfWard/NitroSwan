#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 maxRomSize;
extern u32 allocatedRomMemSize;
extern u8 gMachine;
extern u8 gMachineSet;
extern u8 gSOC;
extern u8 gLang;
extern u8 gPaletteBank;

extern u8 wsRAM[0x10000];
extern u8 biosSpace[0x1000];
extern u8 biosSpaceColor[0x2000];
extern u8 biosSpaceCrystal[0x2000];
extern u8 *allocatedRomMem;
extern const void *g_BIOSBASE_BNW;
extern const void *g_BIOSBASE_COLOR;
extern const void *g_BIOSBASE_CRYSTAL;

void machineInit(void);
void loadCart(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
