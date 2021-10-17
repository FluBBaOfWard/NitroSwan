#ifdef __arm__

#include "Shared/nds_asm.h"
#include "Equates.h"
#include "TLCS900H/TLCS900H.i"
#include "K2GE/K2GE.i"

	.global gfxInit
	.global gfxReset
	.global monoPalInit
	.global paletteInit
	.global paletteTxAll
	.global refreshGfx
	.global endFrameGfx
	.global gfxState
	.global g_gammaValue
	.global g_flicker
	.global g_twitch
	.global g_scaling
	.global g_gfxMask
	.global vblIrqHandler
	.global yStart
	.global GFX_BG0CNT
	.global GFX_BG1CNT
	.global EMUPALBUFF
	.global tmpOamBuffer


	.global k2GE_0
	.global k2GE_0R
	.global k2GE_0W
	.global k2geRAM
	.global DIRTYTILES
	.global DIRTYTILES2


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
gfxInit:					;@ Called from machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=OAM_BUFFER1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x100
	bl memset_
	adr r0,scaleParms
	bl setupSpriteScaling

	bl k2GEInit

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
scaleParms:					;@  NH     FH     NV     FV
	.long OAM_BUFFER1,0x0000,0x0100,0xff01,0x0120,0xfee1
;@----------------------------------------------------------------------------
gfxReset:					;@ Called with CPU reset
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=gfxState
	mov r1,#5					;@ 5*4
	bl memclr_					;@ Clear GFX regs

	ldr r0,=k2geRAM
	ldr r1,=0x6960/4			;@ VRAM and dirty tiles
	bl memclr_					;@ Clear GFX regs

	mov r1,#REG_BASE
	ldr r0,=0x30D0				;@ start-end
	strh r0,[r1,#REG_WIN0H]
	ldr r0,=0x1400+(SCREEN_HEIGHT+GAME_HEIGHT)/2	;@ start-end
	strh r0,[r1,#REG_WIN0V]

	mov r0,#0x003F				;@ WinIN0, Everything enabled inside Win0
	orr r0,r0,#0x2800			;@ WinIN1, Only BG3 & COL inside Win1
	strh r0,[r1,#REG_WININ]
	mov r0,#0x002C				;@ WinOUT, BG2, BG3 & COL enabled outside Windows.
	strh r0,[r1,#REG_WINOUT]
	ldr r0,=0x14AC30D0
	strh r0,[r1,#REG_WIN1H]
	mov r0,r0,lsr#16
	strh r0,[r1,#REG_WIN1V]


	mov r0,#0
	mov r1,#0
//	ldr r0,=m6809SetNMIPin
//	ldr r1,=m6809SetIRQPin
	ldr r2,=k2geRAM
	ldr r3,=g_machine
	ldrb r3,[r3]
	bl k2GEReset0
	bl monoPalInit

	ldr r0,=g_gammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping
	bl paletteTxAll				;@ Transfer it

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
monoPalInit:
	.type monoPalInit STT_FUNC
;@----------------------------------------------------------------------------
	ldr geptr,=k2GE_0
	stmfd sp!,{r4-r6,lr}
	ldr r0,=g_paletteBank
	ldrb r0,[r0]
	adr r1,monoPalette
	add r1,r1,r0,lsl#4
	ldr r0,[geptr,#paletteRAM]
	add r0,r0,#0x180

	mov r2,#8
	ldmia r1,{r3-r6}
monoPalLoop:
	stmia r0!,{r3-r6}
	subs r2,r2,#1
	bne monoPalLoop

	ldmfd sp!,{r4-r6,lr}
	bx lr
;@----------------------------------------------------------------------------
monoPalette:
;@	.short 0xFFF,0xDCD,0xBAB,0x979,0x767,0x535,0x313,0x000
;@	.short 0xFFF,0xDDC,0xBBA,0x997,0x775,0x553,0x331,0x000
;@	.short 0xFFF,0xCDD,0xABB,0x799,0x577,0x355,0x133,0x000
;@	.short 0xFFF,0xCCD,0xAAB,0x779,0x557,0x335,0x113,0x000
;@	.short 0xFFF,0xDCC,0xBAA,0x977,0x755,0x533,0x311,0x000
;@	.short 0xFFF,0xCDC,0xABA,0x797,0x575,0x353,0x131,0x000
;@	.short 0xFFF,0xDDD,0xBBB,0x999,0x777,0x555,0x333,0x000
;@	.short 0xFFF,0xDDD,0xBBB,0x999,0x777,0x555,0x333,0x000

;@ Black & White
	.short 0xFFF,0xDDD,0xBBB,0x999,0x777,0x444,0x333,0x000
;@ Red
	.short 0xFFF,0xCCF,0x99F,0x55F,0x11D,0x009,0x006,0x000
;@ Green
	.short 0xFFF,0xBFB,0x7F7,0x3D3,0x0B0,0x080,0x050,0x000
;@ Blue
	.short 0xFFF,0xFCC,0xFAA,0xF88,0xE55,0xB22,0x700,0x000
;@ Classic
	.short 0xFFF,0xADE,0x8BD,0x59B,0x379,0x157,0x034,0x000
;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type paletteInit STT_FUNC
;@ Called by ui.c:  void paletteInit(gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}
	mov r1,r0					;@ Gamma value = 0 -> 4
	mov r7,#0xF					;@ mask
	ldr r6,=MAPPED_RGB
	mov r4,#4096*2
	sub r4,r4,#2
noMap:							;@ Map 0000bbbbggggrrrr  ->  0bbbbbgggggrrrrr
	and r0,r7,r4,lsr#9			;@ Blue ready
	bl gPrefix
	mov r5,r0

	and r0,r7,r4,lsr#5			;@ Green ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	and r0,r7,r4,lsr#1			;@ Red ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	strh r5,[r6,r4]
	subs r4,r4,#2
	bpl noMap

	ldmfd sp!,{r4-r7,lr}
	bx lr

;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsl#4
;@----------------------------------------------------------------------------
gammaConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	adr geptr,k2GE_0
	ldr r2,=0x1FFE
	ldr r3,[geptr,#paletteRAM]	;@ Colour palette
	ldr r7,[geptr,#paletteMonoRAM]	;@ Mono palette
	ldr r4,=MAPPED_RGB
	ldr r5,=EMUPALBUFF
	add r6,r5,#0x200			;@ Sprite palette

	ldrb r8,[geptr,#kgeMode]	;@ Mono or color mode.
	eor r8,r8,#0x80
	ldrb r0,[geptr,#kgeBGCol]
	ands r9,r0,#0x80			;@ Invert colors?
	orrne r9,r2,r2,lsl#16
	mov r1,#0

txLoop0:						;@ Transfer starts with spr and continues with bgr0.
	tst r8,#0x80				;@ !!! inverted at start !!!
	tsteq r1,#0x70
	add r1,r1,#2
	ldrh r0,[r3,r1]				;@ NGP palette
	eor r0,r9,r0,lsl#1
	and r0,r2,r0
	ldrh r0,[r4,r0]				;@ Pal lut
	strhne r0,[r6,r1]			;@ GBA/NDS palette
	add r1,r1,#2

	ldr r0,[r3,r1]				;@ NGP palette
	eor r0,r9,r0,lsl#1
	and r11,r2,r0
	ldrh r11,[r4,r11]			;@ Pal lut
	and r0,r2,r0,lsr#16
	ldrh r0,[r4,r0]				;@ Pal lut
	orr r0,r11,r0,lsl#16
	strne r0,[r6,r1]			;@ GBA/NDS palette

	add r1,r1,#4
	add r6,r6,#0x18
	tst r1,#0x7E
	bne txLoop0

	sub r6,r6,#512-8
	cmp r1,#0x80
	subeq r6,r5,#0x80
	cmp r1,#0x180				;@ Also show mono replacement palette? 0x180/0x200.
	bne txLoop0

	tst r8,#0x80				;@ !!! inverted at start !!!
	beq TxMonoPalette
TxBackground:
	ldrb r0,[geptr,#kgeBGCol]	;@ Out of window color
	and r0,r0,#0x07
	mov r0,r0,lsl#1
	add r0,r0,#0x1F0
	ldrh r0,[r3,r0]
	eor r0,r9,r0,lsl#1
	and r0,r2,r0
	ldrh r0,[r4,r0]
	strh r0,[r5]
	mov r0,#0
	strh r0,[r5,#0x20]			;@ Border color (internal)

	ldrb r1,[r7,#0x18]			;@ Background color
	and r0,r1,#0x07
	mov r0,r0,lsl#1
	add r0,r0,#0x1E0
	ldrh r0,[r3,r0]
//	and r1,r1,#0xC0
//	cmp r1,#0x80
//	movne r0,#0					;@ Black background if not 0x80
	eor r0,r9,r0,lsl#1
	and r0,r2,r0
	ldrh r0,[r4,r0]
	strh r0,[r5,#0x40]

	ldmfd sp!,{r4-r11,lr}
	bx lr

TxMonoPalette:
	add r6,r5,#0x200			;@ Sprite palette
	mov r1,#0
	add r8,r3,#0x180			;@ Mono palette
txLoop1:
	tst r1,#0x06
	ldrbne r0,[r7,r1,lsr#1]		;@ NGP mono lut
	eorne r0,r9,r0,lsl#1
	andne r0,r0,#0x0E
	ldrhne r0,[r8,r0]			;@ NGP palette
	andne r0,r2,r0,lsl#1
	ldrhne r0,[r4,r0]			;@ Pal lut
	strhne r0,[r6,r1]			;@ GBA/NDS palette

	add r1,r1,#2
	tst r1,#0x6
	addeq r6,r6,#0x18
	addeq r8,r8,#0x10
	tst r1,#0x0E
	bne txLoop1

	sub r6,r6,#64-8
	cmp r1,#0x10
	subeq r6,r5,#0x10
	cmp r1,#0x30
	bne txLoop1

	b TxBackground

;@----------------------------------------------------------------------------
updateLED:
;@----------------------------------------------------------------------------
	ldrb r0,[geptr,#kgeLedOnOff]
	tst r0,#0x01
	ldr r0,=BG_GFX+0x1000
	ldr r1,[r0,#64*24]
	movne r1,r1,ror#16
	add r0,r0,#0x104
	strh r1,[r0]
	bx lr

;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	bl calculateFPS

	mov r6,#REG_BASE
	strh r6,[r6,#REG_DMA0CNT_H]	;@ DMA0 stop

	add r1,r6,#REG_DMA0SAD
	ldr r2,dmaScroll			;@ Setup DMA buffer for scrolling:
	ldmia r2!,{r4-r5}			;@ Read
	add r3,r6,#REG_BG0HOFS		;@ DMA0 always goes here
	stmia r3,{r4-r5}			;@ Set 1st value manually, HBL is AFTER 1st line
	ldr r4,=0x96600002			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 2 word
	stmia r1,{r2-r4}			;@ DMA0 go

	add r1,r6,#REG_DMA3SAD

	ldr r2,dmaOamBuffer			;@ DMA3 src, OAM transfer:
	mov r3,#OAM					;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#64*2				;@ 64 sprites * 2 longwords
	stmia r1,{r2-r4}			;@ DMA3 go

	ldr r2,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r3,#BG_PALETTE			;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#0x100			;@ 256 words (1024 bytes)
	stmia r1,{r2-r4}			;@ DMA3 go

	adr geptr,k2GE_0
	ldrb r0,[geptr,#kgeBGPrio]
	tst r0,#0x80
	ldr r0,GFX_BG0CNT
	orrne r0,r0,#0x00001
	orreq r0,r0,#0x10000
	str r0,[r6,#REG_BG0CNT]

	ldr r0,[geptr,#windowData]
	strh r0,[r6,#REG_WIN0H]
	mov r0,r0,lsr#16
	strh r0,[r6,#REG_WIN0V]

	ldr r0,frameDone
	cmp r0,#0
	beq nothingNew
	bl k2GEConvertTiles
	mov r0,#BG_GFX
	bl k2GEConvertTileMaps
	mov r0,#0
	str r0,frameDone
nothingNew:

	blx scanKeys
	ldmfd sp!,{r4-r8,pc}


;@----------------------------------------------------------------------------
g_flicker:		.byte 1
				.space 2
g_twitch:		.byte 0

g_scaling:		.byte 0
g_gfxMask:		.byte 0
yStart:			.byte 0
				.byte 0
;@----------------------------------------------------------------------------
refreshGfx:					;@ Called from C when changing scaling.
	.type refreshGfx STT_FUNC
;@----------------------------------------------------------------------------
	adr geptr,k2GE_0
;@----------------------------------------------------------------------------
endFrameGfx:				;@ Called just before screen end (~line 152)	(r0-r3 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	bl updateSlowIO				;@ RTC/Alarm and more
	bl updateLED
	ldr r0,tmpScroll
	bl copyScrollValues
	bl paletteTxAll
;@--------------------------

	ldr r0,dmaOamBuffer
	ldr r1,tmpOamBuffer
	str r0,tmpOamBuffer
	str r1,dmaOamBuffer

	ldr r0,dmaScroll
	ldr r1,tmpScroll
	str r0,tmpScroll
	str r1,dmaScroll

	ldr r0,=windowTop			;@ Load wTop, store in wTop+4.......load wTop+8, store in wTop+12
	ldmia r0,{r1-r3}			;@ Load with increment after
	stmib r0,{r1-r3}			;@ Store with increment before

	mov r0,#1
	str r0,frameDone

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
DMA0BUFPTR:		.long 0

tmpOamBuffer:	.long OAM_BUFFER1
dmaOamBuffer:	.long OAM_BUFFER2
tmpScroll:		.long SCROLLBUFF1
dmaScroll:		.long SCROLLBUFF2


frameDone:		.long 0
;@----------------------------------------------------------------------------
k2GEReset0:			;@ r0=periodicIrqFunc, r1=frameIrqFunc, r2=frame2IrqFunc, r3=model
;@----------------------------------------------------------------------------
	adr geptr,k2GE_0
	b k2GEReset
;@----------------------------------------------------------------------------
k2GE_0R:					;@ K2GE read, 0x8000-0x8FFF
;@----------------------------------------------------------------------------
	stmfd sp!,{geptr,lr}
	adr geptr,k2GE_0
	bl k2GE_R
	ldmfd sp!,{geptr,lr}
	bx lr

;@----------------------------------------------------------------------------
k2GE_0W:					;@ K2GE write, 0x8000-0x8FFF
;@----------------------------------------------------------------------------
	stmfd sp!,{geptr,lr}
	adr geptr,k2GE_0
	bl k2GE_W
	ldmfd sp!,{geptr,lr}
	bx lr

k2GE_0:
	.space k2GESize
;@----------------------------------------------------------------------------

gfxState:
adjustBlend:
	.long 0
windowTop:
	.long 0
wTop:
	.long 0,0,0		;@ windowTop  (this label too)   L/R scrolling in unscaled mode

GFX_BG0CNT:
	.short 0
GFX_BG1CNT:
	.short 0

	.section .bss
OAM_BUFFER1:
	.space 0x400
OAM_BUFFER2:
	.space 0x400
SCROLLBUFF1:
	.space 0x100*8				;@ Scrollbuffer.
SCROLLBUFF2:
	.space 0x100*8				;@ Scrollbuffer.
MAPPED_RGB:
	.space 0x2000				;@ 4096*2
EMUPALBUFF:
	.space 0x400
k2geRAM:
	.space 0x3360				;@ 0x3000+0x200+0x140+0x20
	.space 0x3000				;@ backbuffer
DIRTYTILES:
	.space 0x300
DIRTYTILES2:
	.space 0x300

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
