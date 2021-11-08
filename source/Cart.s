#ifdef __arm__

#include "Equates.h"
#include "WSVideo/WSVideo.i"

	.global machineInit
	.global loadCart
	.global emuFlags
	.global romNum
	.global cartFlags
	.global romStart
	.global reBankSwitch4_F_W
	.global BankSwitch4_F_W
	.global BankSwitch2_W
	.global BankSwitch3_W

	.global wsHeader
	.global romSpacePtr
	.global MEMMAPTBL_

	.global biosSpace
	.global g_BIOSBASE_COLOR
	.global g_BIOSBASE_BW
	.global wsRAM
	.global wsSRAM
	.global g_romSize
	.global maxRomSize
	.global romMask
	.global g_config
	.global g_machine
	.global g_lang
	.global g_paletteBank


	.syntax unified
	.arm

	.section .rodata
	.align 2

ROM_Space:
//	.incbin "wsroms/Crazy Climber (J) [M][!].ws"
//	.incbin "wsroms/Guilty Gear Petit (J).wsc"
//	.incbin "wsroms/Mr. Driller (J) [!].wsc"
//	.incbin "wsroms/Tetris (Japan).wsc"
//	.incbin "wsroms/WONDERPR.WSC"
//	.incbin "wsroms/XI Little (Japan).wsc"
ROM_SpaceEnd:
BIOS_Space:
//	.incbin "wsroms/boot.rom"
//	.incbin "wsroms/boot1.rom"
//	.incbin "wsroms/ws_irom.bin"
	.incbin "wsroms/wc_irom.bin"
//	.incbin "wsroms/wsc_irom.bin"

	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

//	ldr r0,=romSize
//	mov r1,#ROM_SpaceEnd-ROM_Space
//	str r1,[r0]
	ldr r0,=romSpacePtr
//	ldr r7,=ROM_Space
//	str r7,[r0]
	ldr r7,[r0]
							;@ r7=rombase til end of loadcart
	ldr r0,=BIOS_Space
	ldr r1,=biosBase
	str r0,[r1]

	bl gfxInit
//	bl ioInit
	bl soundInit
//	bl cpuInit

	ldr r0,=g_BIOSBASE_COLOR
	ldr r0,[r0]
	cmp r0,#0
	beq skipBiosSettings

	bl run					;@ Settings are cleared when new batteries are inserted.
	bl transferTime			;@ So set up time
skipBiosSettings:
	ldmfd sp!,{r4-r11,lr}
	bx lr

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=emuflags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	str r0,emuFlags

	ldr r0,romSize
	movs r2,r0,lsr#16		;@ 64kB blocks.
	subne r2,r2,#1
	str r2,romMask			;@ romMask=romBlocks-1

	ldr r7,romSpacePtr		;@ r7=rombase til end of loadcart

	ldr r4,=MEMMAPTBL_
	mov r0,#4
	mov r5,#0xF4
tbLoop1:
	and r1,r5,r2
	add r1,r7,r1,lsl#16		;@ 64kB blocks.
	str r1,[r4,r0,lsl#2]
	add r5,r5,#1
	add r0,r0,#1
	cmp r0,#0x10
	bne tbLoop1

	ldr r1,=wsRAM
	str r1,[r4,#0x0*4]		;@ 0 RAM
	ldr r1,=wsSRAM
	str r1,[r4,#0x1*4]		;@ 1 SRAM
	ldr r1,[r4,#0xF*4]		;@ MemMap
	str r1,[r4,#0x2*4]		;@ 2 ROM
	str r1,[r4,#0x3*4]		;@ 3 ROM

	ldr r1,biosBase
	sub r1,r1,#0xE000
//	str r1,[r4,#0xF*4]		;@ Map in Bios, not liked by GunPey


	ldr r0,=wsRAM			;@ clear RAM
	mov r1,#0x10000/4
	bl memclr_

//	ldr r0,g_BIOSBASE_COLOR
//	cmp r0,#0
//	bne skipHWSetup

	ldr r0,=wsRAM+0x75AC	;@ simulate BIOS leftovers?
	mov r1,#0x41
//	strb r1,[r0],#1
	mov r1,#0x5F
//	strb r1,[r0],#1
	mov r1,#0x43
//	strb r1,[r0],#1
	mov r1,#0x31
//	strb r1,[r0],#1
	mov r1,#0x6E
//	strb r1,[r0],#1
	mov r1,#0x5F
//	strb r1,[r0],#1
	mov r1,#0x63
//	strb r1,[r0],#1
	mov r1,#0x31
//	strb r1,[r0],#1

	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset
skipHWSetup:
	ldmfd sp!,{r4-r11,lr}
	bx lr


;@----------------------------------------------------------------------------
reBankSwitch4_F_W:					;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	ldr geptr,=wsv_0
	ldrb r1,[geptr,#wsvBnk0Slct]
;@----------------------------------------------------------------------------
BankSwitch4_F_W:					;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	ldr geptr,=wsv_0
	strb r1,[geptr,#wsvBnk0Slct]
	mov r1,r1,lsl#4
	orr r1,r1,#4

	ldr r0,romMask
	ldr r2,romSpacePtr
	ldr r12,=MEMMAPTBL_+4*4
tbLoop2:
	and r3,r0,r1
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	str r3,[r12],#4
	add r1,r1,#1
	ands r3,r1,#0xF
	bne tbLoop2

	bx lr
;@----------------------------------------------------------------------------
reBankSwitch2_W:				;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	ldr geptr,=wsv_0
	ldrb r1,[geptr,#wsvBnk2Slct]
;@----------------------------------------------------------------------------
BankSwitch2_W:					;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	ldr geptr,=wsv_0
	strb r1,[geptr,#wsvBnk2Slct]

	ldr r0,romMask
	ldr r2,romSpacePtr
	ldr r12,=MEMMAPTBL_+2*4
	and r3,r1,r0
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	str r3,[r12],#4

	bx lr

;@----------------------------------------------------------------------------
reBankSwitch3_W:				;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	ldr geptr,=wsv_0
	ldrb r1,[geptr,#wsvBnk3Slct]
;@----------------------------------------------------------------------------
BankSwitch3_W:					;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	ldr geptr,=wsv_0
	strb r1,[geptr,#wsvBnk3Slct]

	ldr r0,romMask
	ldr r2,romSpacePtr
	ldr r12,=MEMMAPTBL_+3*4
	and r3,r1,r0
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	str r3,[r12],#4

	bx lr

;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ romnumber
romInfo:						;@
emuFlags:
	.byte 0						;@ emuflags      (label this so UI.C can take a peek) see equates.h for bitfields
//scaling:
	.byte 0						;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ cartflags
g_config:
	.byte 0						;@ Config, bit 7=BIOS on/off
g_machine:
	.byte 0						;@ machine
g_lang:
	.byte 1						;@ language
g_paletteBank:
	.byte 0						;@ palettebank
	.space 3					;@ alignment.

wsHeader:
romSpacePtr:
	.long 0
g_BIOSBASE_BW:
	.long 0
g_BIOSBASE_COLOR:
	.long 0
g_romSize:
romSize:
	.long 0
maxRomSize:
	.long 0
romMask:
	.long 0
biosBase:
	.long 0

	.section .bss
MEMMAPTBL_:
	.space 16*4
wsRAM:
	.space 0x10000
wsSRAM:
	.space 0x8000
biosSpace:
	.space 0x1000
biosSpaceColor:
	.space 0x2000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
