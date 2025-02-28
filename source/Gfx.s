#ifdef __arm__

#include "Shared/nds_asm.h"
#include "Sphinx/Sphinx.i"

#define ALLOW_REFRESH_CHG	(1<<19)

	.global gFlicker
	.global gTwitch
	.global gGfxMask
	.global GFX_DISPCNT
	.global GFX_BG0CNT
	.global GFX_BG1CNT
	.global EMUPALBUFF
	.global MAPPED_BNW
	.global frameTotal
	.global sphinx0

	.global gfxInit
	.global gfxReset
	.global monoPalInit
	.global paletteInit
	.global paletteTxAll
	.global gfxRefresh
	.global gfxEndFrame
	.global vblIrqHandler
	.global v30ReadPort
	.global v30ReadPort16
	.global v30WritePort
	.global v30WritePort16
	.global updateLCDRefresh
	.global setScreenRefresh
	.global pushVolumeButton
	.global setHeadphones
	.global setLowBattery
	.global setSerialByteIn
	.global getInterruptVector
	.global setInterruptExternal
	.global setPowerOff


	.syntax unified
	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
gfxInit:					;@ Called from machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=OAM_BUFFER1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x100*3				;@ 3 buffers
	bl memset_

	bl wsVideoInit
	bl gfxWinInit

	ldr r0,=DISP_CTRL_LUT		;@ Destination
	mov r1,#0
dispLutLoop:
	and r2,r1,#0x03				;@ BG & FG
	tst r1,#0x04				;@ WS Sprites on?
	orrne r2,r2,#0x10			;@ Sprites
	orr r2,r2,r2,lsl#8			;@ Set both Win0 & Win1
	and r3,r1,#0x30				;@ FG Win Ctrl
	cmp r3,#0x20				;@ FG only inside Win0
	biceq r2,r2,#0x0200
	cmp r3,#0x30				;@ FG only outside Win0
	biceq r2,r2,#0x0002
	orr r2,r2,#0x002C0000		;@ WinOUT, Only BG2, BG3 & BLEND enabled outside Windows.
	str r2,[r0],#4
	add r1,r1,#1
	cmp r1,#64
	bne dispLutLoop

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
gfxReset:					;@ Called with CPU reset
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}

	ldr r0,=gfxState
	mov r1,#5					;@ 5*4
	bl memclr_					;@ Clear GFX regs

	bl gfxWinInit

	ldr r0,=wsRAM
	ldr r1,=gMachine
	ldrb r1,[r1]
	ldr r2,=V30SetIRQPin
	bl wsVideoReset0
	ldr r3,=handleSerialInEmpty
	str r3,[spxptr,#rxFunction]
	ldr r3,=handleSerialReceive
	str r3,[spxptr,#txFunction]

	ldr r4,=gGammaValue
	ldr r5,=gContrastValue
	ldrb r4,[r4]
	ldrb r5,[r5]
	mov r0,r4
	mov r1,r5
	bl paletteInit				;@ Do palette mapping
	mov r0,r4
	mov r1,r5
	bl monoPalInit				;@ Do mono palette mapping
	bl paletteTxAll				;@ Transfer it

	ldr r0,=cartOrientation
	ldr spxptr,=sphinx0
	ldrb r0,[r0]
	strb r0,[spxptr,#wsvOrientation]

	ldr r0,=emuSettings
	ldr r0,[r0]
	and r0,r0,#1<<18
	bl setHeadphones

	ldmfd sp!,{r4,r5,pc}

;@----------------------------------------------------------------------------
gfxWinInit:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#REG_BASE
	;@ Horizontal start-end
	ldr r1,=(((SCREEN_WIDTH-GAME_WIDTH)/2)<<8)+(SCREEN_WIDTH+GAME_WIDTH)/2
	orr r1,r1,r1,lsl#16			;@ Also WIN1H
	str r1,[r0,#REG_WIN0H]
	;@ Vertical start-end
	ldr r2,=(((SCREEN_HEIGHT-GAME_HEIGHT)/2)<<8)+(SCREEN_HEIGHT+GAME_HEIGHT)/2
	orr r2,r2,r2,lsl#16			;@ Also WIN1V
	str r2,[r0,#REG_WIN0V]

	ldr r3,=0x002C0000			;@ WinIN0/1, BG0, BG1, SPR & BLEND inside Win0
	str r3,[r0,#REG_WININ]		;@ WinOUT, Only BG2, BG3 & BLEND enabled outside Windows.

	ldr lr,=WININOUTBUFF1
	mov r0,#SCREEN_HEIGHT
gfxWinLoop:						;@ 3 buffers
	stmia lr!,{r1-r3}
	stmia lr!,{r1-r3}
	stmia lr!,{r1-r3}
	subs r0,r0,#1
	bne gfxWinLoop
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
monoPalInit:
	.type monoPalInit STT_FUNC
;@ Called by ui.c:  void monoPalInit(gammaVal, contrast);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	mov r8,#30
	rsb r1,r1,#4
	mul r8,r1,r8
	mov r1,r0					;@ Gamma value = 0 -> 4
	ldr spxptr,=sphinx0
	ldr r0,=gSOC
	ldrb r0,[r0]
	cmp r0,#SOC_ASWAN
	movne r0,#1
	ldreq r0,=gPaletteBank
	ldrbeq r0,[r0]
	adr r5,monoPalettes			;@ 3*16 for each palette
	add r5,r5,r0,lsl#4			;@ +16
	add r5,r5,r0,lsl#5			;@ +32
	ldr r6,=MAPPED_BNW

	mov r4,#16
monoPalLoop:
	ldrb r0,[r5],#1				;@ Red
	bl cPrefix
	mov r7,r0
	ldrb r0,[r5],#1				;@ Green
	bl cPrefix
	orr r7,r7,r0,lsl#5
	ldrb r0,[r5],#1				;@ Blue
	bl cPrefix
	orr r7,r7,r0,lsl#10
	strh r7,[r6],#2

	subs r4,r4,#1
	bne monoPalLoop

	ldmfd sp!,{r4-r8,lr}
	bx lr
;@----------------------------------------------------------------------------
monoPalettes:

;@ Classic
	.byte 0xF6,0xFE,0xAE, 0xE7,0xEE,0xA2, 0xD8,0xDE,0x96, 0xCA,0xCE,0x8B
	.byte 0xBB,0xBE,0x7F, 0xAC,0xAE,0x74, 0x9E,0x9E,0x68, 0x8F,0x8E,0x5C
	.byte 0x80,0x7F,0x51, 0x72,0x6F,0x45, 0x63,0x5F,0x3A, 0x54,0x4F,0x2E
	.byte 0x46,0x3F,0x22, 0x37,0x2F,0x17, 0x28,0x1F,0x0B, 0x19,0x0F,0x00
;@ Black & White
	.byte 0xFF,0xFF,0xFF, 0xEE,0xEE,0xEE, 0xDD,0xDD,0xDD, 0xCC,0xCC,0xCC
	.byte 0xBB,0xBB,0xBB, 0xAA,0xAA,0xAA, 0x99,0x99,0x99, 0x88,0x88,0x88
	.byte 0x77,0x77,0x77, 0x66,0x66,0x66, 0x55,0x55,0x55, 0x44,0x44,0x44
	.byte 0x33,0x33,0x33, 0x22,0x22,0x22, 0x11,0x11,0x11, 0x00,0x00,0x00
;@ Red
	.byte 0xFF,0xC0,0xC0, 0xEE,0xB3,0xB3, 0xDD,0xA6,0xA6, 0xCC,0x99,0x99
	.byte 0xBB,0x8C,0x8C, 0xAA,0x80,0x80, 0x99,0x73,0x73, 0x88,0x66,0x66
	.byte 0x77,0x59,0x59, 0x66,0x4C,0x4C, 0x55,0x40,0x40, 0x44,0x33,0x33
	.byte 0x33,0x26,0x26, 0x22,0x19,0x19, 0x11,0x0C,0x0C, 0x00,0x00,0x00
;@ Green
	.byte 0xC0,0xFF,0xC0, 0xB3,0xEE,0xB3, 0xA6,0xDD,0xA6, 0x99,0xCC,0x99
	.byte 0x8C,0xBB,0x8C, 0x80,0xAA,0x80, 0x73,0x99,0x73, 0x66,0x88,0x66
	.byte 0x59,0x77,0x59, 0x4C,0x66,0x4C, 0x40,0x55,0x40, 0x33,0x44,0x33
	.byte 0x26,0x33,0x26, 0x19,0x22,0x19, 0x0C,0x11,0x0C, 0x00,0x00,0x00
;@ Blue
	.byte 0xC0,0xC0,0xFF, 0xB3,0xB3,0xEE, 0xA6,0xA6,0xDD, 0x99,0x99,0xCC
	.byte 0x8C,0x8C,0xBB, 0x80,0x80,0xAA, 0x73,0x73,0x99, 0x66,0x66,0x88
	.byte 0x59,0x59,0x77, 0x4C,0x4C,0x66, 0x40,0x40,0x55, 0x33,0x33,0x44
	.byte 0x26,0x26,0x33, 0x19,0x19,0x22, 0x0C,0x0C,0x11, 0x00,0x00,0x00
;@ Green-Blue
    .byte 0xFF,0xFF,0xFF, 0xDD,0xFF,0xDD, 0xBB,0xFF,0xBB, 0xBB,0xBB,0xFF
    .byte 0x77,0xFF,0x77, 0x55,0xEE,0x55, 0x88,0x88,0xFF, 0x11,0xC6,0x11
    .byte 0x77,0x77,0xF8, 0x00,0xBB,0x00, 0x00,0xA1,0x00, 0x22,0x22,0xBB
    .byte 0x00,0x6E,0x00, 0x00,0x55,0x00, 0x00,0x00,0x3B, 0x00,0x00,0x00
;@ Blue-Green
    .byte 0xFF,0xFF,0xFF, 0xE5,0xE5,0xFF, 0xCC,0xCC,0xFF, 0x99,0xFF,0x99
    .byte 0xAA,0xAA,0xFF, 0x99,0x99,0xFF, 0x33,0xDD,0x33, 0x66,0x66,0xF3
    .byte 0x22,0xD1,0x22, 0x55,0x55,0xEE, 0x3B,0x3B,0xD4, 0x00,0x88,0x00
    .byte 0x11,0x11,0x99, 0x00,0x00,0x77, 0x00,0x2A,0x00, 0x00,0x00,0x00
;@ Puyo Puyo Tsu
    .byte 0xFF,0xFF,0xFF, 0xF6,0xEE,0xD4, 0xEE,0xDD,0xAA, 0xD8,0xCC,0xC0
    .byte 0xDD,0xBB,0x88, 0xFF,0x99,0x35, 0xFD,0xAF,0x07, 0xDA,0x6C,0x00
    .byte 0xAF,0x8D,0x49, 0x16,0xB8,0x1E, 0xAA,0x24,0x00, 0x3C,0x4E,0xAA
    .byte 0x5D,0x44,0x08, 0x44,0x33,0x00, 0x22,0x19,0x00, 0x00,0x00,0x00
;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type paletteInit STT_FUNC
;@ Called by ui.c:  void paletteInit(gammaVal, contrast);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	mov r8,#30
	rsb r1,r1,#4
	mul r8,r1,r8
	mov r1,r0					;@ Gamma value = 0 -> 4
	mov r7,#0xF					;@ mask
	ldr r6,=MAPPED_RGB
	mov r4,#4096*2
	sub r4,r4,#2
noMap:							;@ Map 0000rrrrggggbbbb  ->  0bbbbbgggggrrrrr
	and r0,r7,r4,lsr#1			;@ Blue ready
	bl gPrefix
	mov r5,r0,lsl#10

	and r0,r7,r4,lsr#5			;@ Green ready
	bl gPrefix
	orr r5,r5,r0,lsl#5

	and r0,r7,r4,lsr#9			;@ Red ready
	bl gPrefix
	orr r5,r5,r0

	strh r5,[r6,r4]
	subs r4,r4,#2
	bpl noMap

	ldmfd sp!,{r4-r8,lr}
	bx lr

;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsl#4
cPrefix:
	mov r2,r8
;@----------------------------------------------------------------------------
contrastConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4), contrast in r2(0-255) returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r3,r2,#256
	mul r0,r3,r0
	add r0,r0,r2,lsl#7
	mov r0,r0,lsr#8
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
	movs r0,r0,lsr#13

	bx lr
;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=EMUPALBUFF
	ldr spxptr,=sphinx0
;@----------------------------------------------------------------------------
paletteTx:					;@ r0=destination, spxptr=Sphinx
;@----------------------------------------------------------------------------
	ldr r1,=MAPPED_RGB
	ldr r2,=0x1FFE
	stmfd sp!,{r4-r8,lr}
	mov r5,#0
	ldrb r3,[spxptr,#wsvBgColor]	;@ Background palette
	ldrb r7,[spxptr,#wsvVideoMode]
	tst r7,#0x80				;@ Color mode?
	beq bnwTx

	ldr r4,[spxptr,#paletteRAM]
	mov r3,r3,lsl#1
	ldrh r3,[r4,r3]
	and r3,r2,r3,lsl#1
	ldrh r3,[r1,r3]
	strh r3,[r0]				;@ Background palette
	tst r7,#0x40				;@ 4bitplane mode?
	beq col4Tx
	add r6,r0,#0x100			;@ Sprite pal ofs - r5
txLoop:
	ldrh r3,[r4],#2
	and r3,r2,r3,lsl#1
	ldrh r3,[r1,r3]
	cmp r5,#0x00
	strhne r3,[r0,r5]			;@ Background palette
	cmp r5,#0x100
	strhpl r3,[r6,r5]			;@ Sprite palette

	add r5,r5,#2
	cmp r5,#0x200
	bmi txLoop

	ldmfd sp!,{r4-r8,lr}
	bx lr

col4Tx:
col4TxLoop:
	ldrh r3,[r4,r5]
	and r3,r2,r3,lsl#1
	ldrh r3,[r1,r3]
	cmp r5,#0x00
	strhne r3,[r0]				;@ Background palette
	strh r3,[r0,#0x8]			;@ Opaque tiles palette
	cmp r5,#0x100
	addpl r6,r0,#0x100
	strhpl r3,[r6]				;@ Sprite palette
	strhpl r3,[r6,#0x8]			;@ Sprite palette opaque

	add r0,r0,#2
	add r5,r5,#2
	tst r5,#6
	bne col4TxLoop
	add r0,r0,#0x18
	add r5,r5,#0x18
	cmp r5,#0x200
	bmi col4TxLoop

	ldmfd sp!,{r4-r8,lr}
	bx lr

bnwTx:
	add r1,r1,#MAPPED_BNW-MAPPED_RGB
	mov r2,#0x1E
	add r4,spxptr,#wsvPalette0
	and r3,r3,#0x7
	tst r3,#1
	add r7,spxptr,#wsvColor01
	ldrb r3,[r7,r3,lsr#1]
	andeq r3,r2,r3,lsl#1
	andne r3,r2,r3,lsr#3
	ldrh r3,[r1,r3]
	strh r3,[r0]				;@ Background palette
bnwTxLoop2:
	ldrh r6,[r4],#2
bnwTxLoop:
	and r3,r6,#0x7
	mov r6,r6,lsr#4
	tst r3,#1
	ldrb r3,[r7,r3,lsr#1]
	andeq r3,r2,r3,lsl#1
	andne r3,r2,r3,lsr#3
	ldrh r3,[r1,r3]

	cmp r5,#0x0
	strhne r3,[r0]				;@ Background palette
	strh r3,[r0,#0x8]			;@ Opaque tiles palette
	cmp r5,#0x100
	addpl r8,r0,#0x100
	strhpl r3,[r8]				;@ Sprite palette
	strhpl r3,[r8,#0x8]			;@ Sprite palette opaque

	add r0,r0,#2
	add r5,r5,#2
	tst r5,#6
	bne bnwTxLoop
	add r0,r0,#0x18
	add r5,r5,#0x18
	cmp r5,#0x200
	bmi bnwTxLoop2

	ldmfd sp!,{r4-r8,lr}
	bx lr
;@----------------------------------------------------------------------------
updateLCDRefresh:
	.type updateLCDRefresh STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	ldrb r0,[spxptr,#wsvTotalLines]
	b wsvRefW
;@----------------------------------------------------------------------------
setScreenRefresh:			;@ r0 in = WS scan line count.
	.type setScreenRefresh STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,spxptr,lr}
	mov r4,r0
	ldr r6,=12000				;@ WS scanline frequency = 12kHz
	mov r0,r6,lsl#1
	mov r1,r4
	swi 0x090000				;@ Division r0/r1, r0=result, r1=remainder.
	movs r0,r0,lsr#1
	adc r0,r0,#0
	mov r5,r0
	bl setLCDFPS
	ldr r0,=emuSettings
	ldr r0,[r0]
	tst r0,#ALLOW_REFRESH_CHG
	moveq r0,#59
	subne r0,r5,#1
	ldr r1,=fpsNominal
	strb r0,[r1]

	ldr r0,=15734				;@ DS scanline frequency = 15734.3Hz
	mul r0,r4,r0				;@ DS scanline freq * WS scanlines
	mov r1,r6					;@ / WS scanline freq = DS scanlines.
	swi 0x090000				;@ Division r0/r1, r0=result, r1=remainder.
	ldr r1,=263
	sub r0,r1,r0
	cmp r0,#3
	movmi r0,#0
	str r0,lcdSkip

	ldmfd sp!,{r4-r6,spxptr,lr}
	bx lr

;@----------------------------------------------------------------------------
#ifdef GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	bl calculateFPS

	mov r6,#REG_BASE
	strh r6,[r6,#REG_DMA0CNT_H]	;@ DMA0 stop
	strh r6,[r6,#REG_DMA3CNT_H]	;@ DMA3 stop

	add r0,r6,#REG_DMA0SAD
	ldr r1,dmaScroll			;@ Setup DMA buffer for scrolling:
	ldmia r1!,{r3-r4}			;@ Read
	add r2,r6,#REG_BG0HOFS		;@ DMA0 always goes here
	stmia r2,{r3-r4}			;@ Set 1st values manually, HBL is AFTER 1st line
	ldr r3,=0x96600002			;@ hblank 32bit repeat incsrc inc_reloaddst, 2 words
	stmia r0,{r1-r3}			;@ DMA0 go

	add r0,r6,#REG_DMA3SAD
	ldr r1,dmaOamBuffer			;@ DMA3 src, OAM transfer:
	mov r2,#OAM					;@ DMA3 dst
	mov r3,#0x84000000			;@ 32bit incsrc incdst
	orr r3,r3,#128*2			;@ 128 sprites * 2 longwords
	stmia r0,{r1-r3}			;@ DMA3 go

	ldr r1,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r2,#BG_PALETTE			;@ DMA3 dst
	mov r3,#0x84000000			;@ 32bit incsrc incdst
	orr r3,r3,#0x100			;@ 256 words (1024 bytes)
	stmia r0,{r1-r3}			;@ DMA3 go

	ldr r1,dmaWinInOut			;@ Setup DMA buffer for window stuff:
	ldmia r1!,{r3-r5}			;@ Read
	add r2,r6,#REG_WIN0H		;@ DMA3 dst
	stmia r2,{r3-r5}			;@ Set 1st values manually, HBL is AFTER 1st line
	ldr r3,=0x96600003			;@ hblank 32bit repeat incsrc inc_reloaddst, 3 words
	stmia r0,{r1-r3}			;@ DMA3 go

	adr spxptr,sphinx0
	ldr r0,GFX_DISPCNT
	ldrb r2,gGfxMask
	bic r0,r0,r2,lsl#8
	strh r0,[r6,#REG_DISPCNT]

	ldr r0,=emuSettings
	ldr r0,[r0]
	tst r0,#ALLOW_REFRESH_CHG
	beq exit75Hz
	ldr r0,=pauseEmulation
	ldrb r0,[r0]
	cmp r0,#0
	bne exit75Hz
	ldr r0,lcdSkip
	cmp r0,#0
	beq exit75Hz
hz75Start:
hz75Loop:
	ldrh r1,[r6,#REG_VCOUNT]
	cmp r1,#202
	bmi hz75Loop
	add r1,r1,r0			;@ Skip 55(?) scan lines for 75Hz.
	cmp r1,#260
	movpl r1,#260
	strh r1,[r6,#REG_VCOUNT]
exit75Hz:

	ldrb r0,frameDone
	cmp r0,#0
	beq nothingNew
//	bl wsvConvertTiles
	mov r0,#BG_GFX
	bl wsvConvertTileMaps
	mov r0,#0
	strb r0,frameDone
nothingNew:

	blx scanKeys
	ldmfd sp!,{r4-r8,pc}

;@----------------------------------------------------------------------------
copyWindowValues:		;@ r0 = destination
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	add r0,r0,#((SCREEN_HEIGHT-GAME_HEIGHT)/2)*12		;@ 12 bytes per row
	ldr r9,=(((SCREEN_WIDTH-GAME_WIDTH)/2)<<24)+(((SCREEN_WIDTH+GAME_WIDTH)/2)<<16)+(((SCREEN_WIDTH-GAME_WIDTH)/2)<<8)+((SCREEN_WIDTH-GAME_WIDTH)/2 + 1)
	ldr lr,=(((SCREEN_HEIGHT-GAME_HEIGHT)/2)<<24)+(((SCREEN_HEIGHT+GAME_HEIGHT)/2)<<16)+(((SCREEN_HEIGHT-GAME_HEIGHT)/2)<<8)+((SCREEN_HEIGHT-GAME_HEIGHT)/2 + 1)
	ldr r1,[spxptr,#dispBuff]
	ldr r4,[spxptr,#windowBuff]
	ldr r2,=DISP_CTRL_LUT

	mov r3,#GAME_HEIGHT<<24
setWindowLoop:
	ldr r8,[r4],#4				;@ FG Win pos/size
	and r6,r8,#0x000000FF		;@ H start
	and r7,r8,#0x00FF0000		;@ H end
	cmp r6,#GAME_WIDTH
	movcs r6,#GAME_WIDTH
	cmp r7,#(GAME_WIDTH-1)<<16
	movcs r7,#(GAME_WIDTH-1)<<16
	cmp r7,r6,lsl#16
	orr r6,r6,r7,lsl#8
	movcc r6,#-1
	add r6,r9,r6,ror#24

	rsb r5,r3,#GAME_HEIGHT<<24
	and r7,r8,#0x0000FF00		;@ V start, V end top byte
	cmp r7,r5,lsr#16
	movcc r7,r5,lsr#16
	cmp r7,#GAME_HEIGHT<<8
	movcs r7,#GAME_HEIGHT<<8
	cmp r8,#(GAME_HEIGHT-1)<<24
	movcs r8,#(GAME_HEIGHT-1)<<24
	cmp r8,r5
	subcc r8,r5,#1<<24
	orr r7,r7,r8,lsr#24
	add r7,r7,lr

	ldrb r8,[r1],#1
	ldr r8,[r2,r8,lsl#2]
	stmia r0!,{r6-r8}
	subs r3,r3,#1<<24
	bne setWindowLoop

	ldmfd sp!,{r4-r9,pc}

;@----------------------------------------------------------------------------
gfxRefresh:					;@ Called from C when changing scaling.
	.type gfxRefresh STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
;@----------------------------------------------------------------------------
gfxEndFrame:				;@ Called just after screen end (line 144)	(r0-r3 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}

	ldr r0,tmpScroll			;@ Destination
	bl copyScrollValues
	ldr r0,tmpWinInOut			;@ Destination
	bl copyWindowValues
	ldr r0,tmpOamBuffer			;@ Destination
	bl wsvConvertSprites
	bl paletteTxAll
;@--------------------------

	adr r0,tmpOamBuffer
	ldmia r0,{r1-r8,lr}
	stmia r0!,{r7,r8,lr}
	stmia r0,{r1-r6}

	mov r0,#1
	strb r0,frameDone
	bl updateSlowIO				;@ Battery level/RTC/Alarm

	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r8,lr}
	bx lr

;@----------------------------------------------------------------------------
frameTotal:		.long 0			;@ Let Gui.c see frame count for savestates

tmpOamBuffer:	.long OAM_BUFFER1
tmpScroll:		.long SCROLLBUFF1
tmpWinInOut:	.long WININOUTBUFF1
dmaOamBuffer:	.long OAM_BUFFER2
dmaScroll:		.long SCROLLBUFF2
dmaWinInOut:	.long WININOUTBUFF2
xtrOamBuffer:	.long OAM_BUFFER3
xtrScroll:		.long SCROLLBUFF3
xtrWinInOut:	.long WININOUTBUFF3


gFlicker:		.byte 1
				.space 2
gTwitch:		.byte 0

gGfxMask:		.byte 0
frameDone:		.byte 0
				.byte 0,0
;@----------------------------------------------------------------------------
wsVideoReset0:				;@ r0=ram+LUTs, r1=machine, r2=IrqFunc
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsVideoReset
;@----------------------------------------------------------------------------
v30ReadPort:
	.type v30ReadPort STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvRead
;@----------------------------------------------------------------------------
v30ReadPort16:
	.type v30ReadPort16 STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvRead16
;@----------------------------------------------------------------------------
v30WritePort:
	.type v30WritePort STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvWrite
;@----------------------------------------------------------------------------
v30WritePort16:
	.type v30WritePort16 STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvWrite16
;@----------------------------------------------------------------------------
pushVolumeButton:
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvPushVolumeButton
;@----------------------------------------------------------------------------
setHeadphones:				;@ r0 = on/off
	.type setHeadphones STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvSetHeadphones
;@----------------------------------------------------------------------------
setLowBattery:				;@ r0 = on/off
	.type setLowBattery STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvSetLowBattery
;@----------------------------------------------------------------------------
setSerialByteIn:
	.type setSerialByteIn STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvSetSerialByteIn
;@----------------------------------------------------------------------------
getInterruptVector:
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvGetInterruptVector
;@----------------------------------------------------------------------------
setInterruptExternal:		;@ r0=irq state
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvSetInterruptExternal
;@----------------------------------------------------------------------------
setPowerOff:
	.type setPowerOff STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvSetPowerOff
sphinx0:
	.space sphinxSize
;@----------------------------------------------------------------------------

gfxState:
	.long 0
	.long 0
	.long 0,0
lcdSkip:
	.long 0

GFX_DISPCNT:
	.long 0
GFX_BG0CNT:
	.short 0
GFX_BG1CNT:
	.short 0

#ifdef GBA
	.section .sbss				;@ For the GBA
#else
	.section .bss
#endif
	.align 2
OAM_BUFFER1:
	.space 0x400
OAM_BUFFER2:
	.space 0x400
OAM_BUFFER3:
	.space 0x400
SCROLLBUFF1:
	.space SCREEN_HEIGHT*8		;@ Scrollbuffer.
SCROLLBUFF2:
	.space SCREEN_HEIGHT*8		;@ Scrollbuffer.
SCROLLBUFF3:
	.space SCREEN_HEIGHT*8		;@ Scrollbuffer.
WININOUTBUFF1:
	.space SCREEN_HEIGHT*12		;@ Scrollbuffer.
WININOUTBUFF2:
	.space SCREEN_HEIGHT*12		;@ Scrollbuffer.
WININOUTBUFF3:
	.space SCREEN_HEIGHT*12		;@ Scrollbuffer.
DISP_CTRL_LUT:
	.space 64*4					;@ Convert from WS DispCtrl to NDS/GBA WinCtrl
MAPPED_RGB:
	.space 0x2000				;@ 4096*2
MAPPED_BNW:
	.space 0x20
EMUPALBUFF:
	.space 0x400

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
