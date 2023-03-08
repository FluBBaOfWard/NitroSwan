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
void paletteInit(u8 gammaVal, u8 contrast);
void monoPalInit(u8 gammaVal, u8 contrast);
void paletteTxAll(void);
void updateLCDRefresh(void);
void gfxRefresh(void);
u8 v30ReadPort(u16 port);
void v30WritePort(u16 port, u8 value);

void setHeadphones(bool enable);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GFX_HEADER
