#ifndef GFX_HEADER
#define GFX_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "Sphinx/Sphinx.h"

extern u8 gFlicker;
extern u8 gTwitch;
extern u8 gGfxMask;

extern Sphinx sphinx0;
extern u16 EMUPALBUFF[0x200];
extern u16 MAPPED_BNW[0x10];
extern u32 GFX_DISPCNT;
extern u16 GFX_BG0CNT;
extern u16 GFX_BG1CNT;

void gfxInit(void);
void vblIrqHandler(void);

/**
 * Calculate new (color) palette look up table.
 * @param gammaVal: 0-4.
 * @param contrast: 0-4.
 * @param bright: -255 -> 255.
 */
void paletteInit(u8 gammaVal, u8 contrast, int bright);

/**
 * Calculate new (mono) palette look up table.
 * @param gammaVal: 0-4.
 * @param contrast: 0-4.
 * @param bright: -255 -> 255.
 */
void monoPalInit(u8 gammaVal, u8 contrast, int bright);

void paletteTxAll(void);
void shutDownLCD(void);
void updateLCDRefresh(void);
void gfxRefresh(void);
u8 v30ReadPort(u16 port);
u16 v30ReadPort16(u16 port);
void v30WritePort(u8 value, u16 port);
void v30WritePort16(u16 value, u16 port);

void pushVolumeButton(void);
void setHeadphones(bool enable);
void setSerialByteIn(u8 value);
void setPowerOff(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GFX_HEADER
