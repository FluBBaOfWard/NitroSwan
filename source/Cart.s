#ifdef __arm__

#include "Equates.h"
#include "WSVideo/WSVideo.i"

	.extern reset				;@ from bios.c

	.global machineInit
	.global loadCart
	.global emuFlags
	.global romNum
	.global cartFlags
	.global romStart
	.global isBiosLoaded
	.global BankSwitch4_F_W
	.global BankSwitch4_F_R
	.global BankSwitch2_W
	.global BankSwitch3_W

	.global ngpHeader
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
//biosSpace:
//	.incbin "wsroms/boot.rom"
//	.incbin "wsroms/boot1.rom"

	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr r0,=romSpacePtr
//	ldr r7,=ROM_Space
//	str r7,[r0]
	ldr r7,[r0]
							;@ r7=rombase til end of loadcart
	ldr r0,=biosSpace
//	str r0,[t9optbl,#biosBase]

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

	ldr r0,g_romSize
	ldr r1,romSpacePtr

	ldr r0,g_BIOSBASE_COLOR
	cmp r0,#0
	bne skipHWSetup

	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset
skipHWSetup:
	ldmfd sp!,{r4-r11,lr}
	bx lr


;@----------------------------------------------------------------------------
BankSwitch4_F_R:					;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	ldr r0,=IO_regs
	ldrb r0,[r1,#0xC0]
	and r0,r0,#0x0F
	orr r0,r0,#0x20
	bx lr
;@----------------------------------------------------------------------------
reBankSwitch4_F_W:					;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	ldr r0,=IO_regs
	ldrb r1,[r0,#0xC0]
;@----------------------------------------------------------------------------
BankSwitch4_F_W:					;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	ldr r0,=IO_regs
	strb r1,[r0,#0xC0]
	mov r1,r1,lsl#4
	orr r1,r1,#4

	ldr r0,romMask
	ldr r2,romSpacePtr
	ldr r12,=MEMMAPTBL_+4*4
tbloop1:
	and r3,r1,r0
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	str r3,[r12],#4
	add r1,r1,#1
	cmp r1,#0x100
	bne tbloop1

	bx lr
;@----------------------------------------------------------------------------
reBankSwitch2_W:				;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	ldr r0,=IO_regs
	ldrb r1,[r0,#0xC2]
;@----------------------------------------------------------------------------
BankSwitch2_W:					;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	ldr r0,=IO_regs
	strb r1,[r0,#0xC2]

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
	ldr r0,=IO_regs
	ldrb r1,[r0,#0xC3]
;@----------------------------------------------------------------------------
BankSwitch3_W:					;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	ldr r0,=IO_regs
	strb r1,[r0,#0xC3]

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
isBiosLoaded:
	.byte 0
	.space 2					;@ alignment.

ngpHeader:
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

	.section .bss
MEMMAPTBL_:
	.space 8*4
wsRAM:
	.space 0x10000
wsSRAM:
	.space 0x8000
biosSpace:
	.space 0x1000
biosSpaceColor:
	.space 0x1000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
