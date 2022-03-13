#ifdef __arm__

#include "Shared/nds_asm.h"
#include "Equates.h"
#include "Sphinx/Sphinx.i"

	.global gfxInit
	.global gfxReset
	.global monoPalInit
	.global paletteInit
	.global paletteTxAll
	.global refreshGfx
	.global endFrameGfx
	.global ioReadByte
	.global ioWriteByte
	.global cpu_readport
	.global cpu_writeport
	.global getInterruptVector
	.global setInterruptExternal

	.global gfxState
	.global gGammaValue
	.global gFlicker
	.global gTwitch
	.global gScaling
	.global gGfxMask
	.global vblIrqHandler
	.global yStart
	.global GFX_DISPCNT
	.global GFX_BG0CNT
	.global GFX_BG1CNT
	.global EMUPALBUFF
	.global tmpOamBuffer


	.global sphinx0
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

	bl wsVideoInit
	bl gfxWinInit

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

	bl gfxWinInit

	ldr r0,=V30SetIRQPin
	mov r1,#0
	ldr r2,=wsRAM
	ldr r3,=gSOC
	ldrb r3,[r3]
	bl wsVideoReset0
	bl monoPalInit

	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping
	bl paletteTxAll				;@ Transfer it

	ldr r0,=cartOrientation
	ldr spxptr,=sphinx0
	ldrb r0,[r0]
	strb r0,[spxptr,#wsvOrientation]

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
gfxWinInit:
;@----------------------------------------------------------------------------
	mov r1,#REG_BASE
	;@ Horizontal start-end
	ldr r0,=(((SCREEN_WIDTH-GAME_WIDTH)/2)<<8)+(SCREEN_WIDTH+GAME_WIDTH)/2
	strh r0,[r1,#REG_WIN0H]
	strh r0,[r1,#REG_WIN1H]
	;@ Vertical start-end
	ldr r0,=(((SCREEN_HEIGHT-GAME_HEIGHT)/2)<<8)+(SCREEN_HEIGHT+GAME_HEIGHT)/2
	strh r0,[r1,#REG_WIN0V]
	strh r0,[r1,#REG_WIN1V]

	ldr r0,=0x3333				;@ WinIN0/1, BG0, BG1, SPR & COL inside Win0
	strh r0,[r1,#REG_WININ]
	mov r0,#0x002C				;@ WinOUT, Only BG2, BG3 & COL enabled outside Windows.
	strh r0,[r1,#REG_WINOUT]
	bx lr
;@----------------------------------------------------------------------------
monoPalInit:
	.type monoPalInit STT_FUNC
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	stmfd sp!,{r4-r6,lr}
	ldr r0,=gPaletteBank
	ldrb r0,[r0]
	adr r1,monoPalette
	add r1,r1,r0,lsl#4
	ldr r0,[spxptr,#paletteRAM]
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
noMap:							;@ Map 0000rrrrggggbbbb  ->  0bbbbbgggggrrrrr
	and r0,r7,r4,lsr#1			;@ Blue ready
	bl gPrefix
	mov r5,r0,lsl#10

	and r0,r7,r4,lsr#5			;@ Green ready
	bl gPrefix
	orr r5,r5,r0,lsl#5
	orrcs r5,r5,#0x8000

	and r0,r7,r4,lsr#9			;@ Red ready
	bl gPrefix
	orr r5,r5,r0

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
	ldrb r3,[spxptr,#wsvBGColor]	;@ Background palette
	ldrb r7,[spxptr,#wsvVideoMode]
	tst r7,#0x80				;@ Color mode?
	beq bnwTx

	ldr r4,=wsRAM+0xFE00
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
	add r4,spxptr,#wsvPalette00
	and r3,r3,#0x7
	tst r3,#1
	add r7,spxptr,#wsvColor01
	ldrb r3,[r7,r3,lsr#1]
	movne r3,r3,lsr#4
	and r3,r3,#0xF
	eor r3,r3,#0xF
	orr r3,r3,r3,lsl#4
	orr r3,r3,r3,lsl#4
	and r3,r2,r3,lsl#1
	ldrh r3,[r1,r3]
	strh r3,[r0]				;@ Background palette
bnwTxLoop2:
	ldrh r6,[r4],#2
bnwTxLoop:
	and r3,r6,#0x7
	mov r6,r6,lsr#4
	tst r3,#1
	ldrb r3,[r7,r3,lsr#1]
	movne r3,r3,lsr#4
	and r3,r3,#0xF
	eor r3,r3,#0xF
	orr r3,r3,r3,lsl#4
	orr r3,r3,r3,lsl#4
	and r3,r2,r3,lsl#1
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
	orr r4,r4,#128*2			;@ 128 sprites * 2 longwords
	stmia r1,{r2-r4}			;@ DMA3 go

	ldr r2,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r3,#BG_PALETTE			;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#0x100			;@ 256 words (1024 bytes)
	stmia r1,{r2-r4}			;@ DMA3 go

	adr spxptr,sphinx0
	ldr r0,GFX_BG0CNT
	str r0,[r6,#REG_BG0CNT]
	ldr r0,GFX_DISPCNT
	ldrb r1,[spxptr,#wsvDispCtrl]
	tst r1,#1
	biceq r0,r0,#0x0100			;@ Turn off bg
	tst r1,#0x02
	biceq r0,r0,#0x0200			;@ Turn off fg
	tst r1,#0x04
	biceq r0,r0,#0x1000			;@ Turn off sprites
	tst r1,#0x20				;@ Win for FG on?
	biceq r0,r0,#0x2000			;@ Turn off fg-window
	ldrb r2,gGfxMask
//	bic r0,r0,r2,lsl#8
	strh r0,[r6,#REG_DISPCNT]

	ldr r0,[spxptr,#windowData]
	strh r0,[r6,#REG_WIN0H]
	mov r0,r0,lsr#16
	strh r0,[r6,#REG_WIN0V]
	ldr r0,=0x3333				;@ WinIN0/1, BG0, BG1, SPR & COL inside Win0
	and r2,r1,#0x30
	cmp r2,#0x20
	biceq r0,r0,#0x0200
	cmp r2,#0x30
	biceq r0,r0,#0x0002
	strh r0,[r6,#REG_WININ]


	ldr r0,frameDone
	cmp r0,#0
	beq nothingNew
//	bl wsvConvertTiles
	mov r0,#BG_GFX
	bl wsvConvertTileMaps
	mov r0,#0
	str r0,frameDone
nothingNew:

	blx scanKeys
	ldmfd sp!,{r4-r8,pc}


;@----------------------------------------------------------------------------
gFlicker:		.byte 1
				.space 2
gTwitch:		.byte 0

gScaling:		.byte 0
gGfxMask:		.byte 0
yStart:			.byte 0
				.byte 0
;@----------------------------------------------------------------------------
refreshGfx:					;@ Called from C when changing scaling.
	.type refreshGfx STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
;@----------------------------------------------------------------------------
endFrameGfx:				;@ Called just before screen end (~line 143)	(r0-r3 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,tmpScroll			;@ Destination
	bl copyScrollValues
	ldr r0,tmpOamBuffer			;@ Destination
	bl wsvConvertSprites
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

//	ldr r0,=windowTop			;@ Load wTop, store in wTop+4.......load wTop+8, store in wTop+12
//	ldmia r0,{r1-r3}			;@ Load with increment after
//	stmib r0,{r1-r3}			;@ Store with increment before

	mov r0,#1
	str r0,frameDone
	bl updateSlowIO				;@ RTC/Alarm and more

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
wsVideoReset0:		;@ r0=periodicIrqFunc, r1=, r2=frame2IrqFunc, r3=model
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsVideoReset
;@----------------------------------------------------------------------------
ioReadByte:
	.type ioReadByte STT_FUNC
cpu_readport:
	.type cpu_readport STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvRead
;@----------------------------------------------------------------------------
ioWriteByte:				;@ r0=port, r1=value
	.type ioWriteByte STT_FUNC
cpu_writeport:
	.type cpu_writeport STT_FUNC
;@----------------------------------------------------------------------------
	adr spxptr,sphinx0
	b wsvWrite
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
sphinx0:
	.space sphinxSize
;@----------------------------------------------------------------------------

gfxState:
adjustBlend:
	.long 0
windowTop:
	.long 0
wTop:
	.long 0,0,0		;@ windowTop  (this label too)   L/R scrolling in unscaled mode

GFX_DISPCNT:
	.long 0
GFX_BG0CNT:
	.short 0
GFX_BG1CNT:
	.short 0

	.section .bss
	.align 2
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
DIRTYTILES:
	.space 0x400
DIRTYTILES2:
	.space 0x400

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
