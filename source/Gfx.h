#ifndef GFX_HEADER
#define GFX_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "WSVideo/WSVideo.h"

extern u8 g_flicker;
extern u8 g_twitch;
extern u8 g_scaling;
extern u8 g_gfxMask;

extern WSVideo wsv_0;
extern u16 EMUPALBUFF[0x200];
extern u32 GFX_DISPCNT;
extern u16 GFX_BG0CNT;
extern u16 GFX_BG1CNT;

void gfxInit(void);
void vblIrqHandler(void);
void monoPalInit(void);
void paletteInit(u8 gammaVal);
void paletteTxAll(void);
void refreshGfx(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GFX_HEADER
