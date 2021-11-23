#ifdef __arm__

#include "Equates.h"
#include "EEPROM.i"
#include "Sphinx/WSVideo.i"

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

	.global biosBase
	.global biosSpace
	.global biosSpaceColor
	.global g_BIOSBASE_BNW
	.global g_BIOSBASE_COLOR
	.global g_BIOSBASE_CRYSTAL
	.global wsRAM
	.global wsSRAM
	.global extEepromMem
	.global sramSize
	.global eepromSize
	.global g_romSize
	.global maxRomSize
	.global romMask
	.global g_config
	.global g_machine
	.global g_machineSet
	.global g_lang
	.global g_paletteBank

	.global extEepromDataLowR
	.global extEepromDataHighR
	.global extEepromAdrLowR
	.global extEepromAdrHighR
	.global extEepromStatusR
	.global extEepromDataLowW
	.global extEepromDataHighW
	.global extEepromAdrLowW
	.global extEepromAdrHighW
	.global extEepromCommandW


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
WS_BIOS_INTERNAL:
	.incbin "wsroms/ws_irom.bin"
//	.incbin "wsroms/boot.rom"
WSC_BIOS_INTERNAL:
	.incbin "wsroms/wc_irom.bin"
//	.incbin "wsroms/boot1.rom"
SC_BIOS_INTERNAL:
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
//	ldr r0,=romSpacePtr
//	ldr r7,=ROM_Space
//	str r7,[r0]

	bl gfxInit
//	bl ioInit
	bl soundInit
//	bl cpuInit

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
	ldr r6,[r4,#0xF*4]		;@ MemMap
	str r6,[r4,#0x2*4]		;@ 2 ROM
	str r6,[r4,#0x3*4]		;@ 3 ROM

	ldrb r5,g_machineSet
	cmp r5,#HW_AUTO
	bne dontCheckHW
	ldr r3,=0xFFF7			;@ Supported System
	ldrb r3,[r6,r3]
	cmp r3,#0
	moveq r5,#HW_ASWAN
	movne r5,#HW_SPHINX
dontCheckHW:
	strb r5,g_machine

	ldr r3,=0xFFFB			;@ NVRAM size
	ldrb r3,[r6,r3]
	mov r0,#0				;@ r0 = sram size
	mov r1,#0				;@ r1 = eeprom size
	cmp r3,#0x01			;@ 64kbit sram
	moveq r0,#0x2000
	cmp r3,#0x02			;@ 256kbit sram
	moveq r0,#0x8000
	cmp r3,#0x03			;@ 1Mbit sram
	moveq r0,#0x20000
	cmp r3,#0x04			;@ 2Mbit sram
	moveq r0,#0x40000
	cmp r3,#0x05			;@ 4Mbit sram
	moveq r0,#0x80000
	cmp r3,#0x10			;@ 1kbit eeprom
	moveq r1,#0x80
	cmp r3,#0x20			;@ 16kbit eeprom
	moveq r1,#0x800
	cmp r3,#0x50			;@ 8kbit eeprom
	moveq r1,#0x400
	str r0,sramSize
	str r1,eepromSize

	cmp r5,#HW_ASWAN
	moveq r0,#1				;@ For boot rom overlay
	movne r0,#2
	ldreq r1,g_BIOSBASE_BNW
	ldrne r1,g_BIOSBASE_COLOR
	ldreq r2,=WS_BIOS_INTERNAL
	ldrne r2,=WSC_BIOS_INTERNAL
	cmp r1,#0
	moveq r1,r2				;@ Use internal bios
	str r1,biosBase
	bl setBootRomOverlay

//	sub r0,r0,#0xE000
//	str r0,[r4,#0xF*4]


	ldr r0,=wsRAM			;@ clear RAM
	mov r1,#0x10000/4
	bl memclr_

	bl extEepromReset
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
	str r3,[r12]

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
	str r3,[r12]

	bx lr

;@----------------------------------------------------------------------------
extEepromDataLowR:
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromDataLowR
;@----------------------------------------------------------------------------
extEepromDataHighR:
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromDataHighR
;@----------------------------------------------------------------------------
extEepromAdrLowR:
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromAddressLowR
;@----------------------------------------------------------------------------
extEepromAdrHighR:
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromAddressHighR
;@----------------------------------------------------------------------------
extEepromStatusR:
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromStatusR
;@----------------------------------------------------------------------------
extEepromDataLowW:
;@----------------------------------------------------------------------------
	mov r0,r1
	adr eeptr,extEeprom
	b wsEepromDataLowW
;@----------------------------------------------------------------------------
extEepromDataHighW:
;@----------------------------------------------------------------------------
	mov r0,r1
	adr eeptr,extEeprom
	b wsEepromDataHighW
;@----------------------------------------------------------------------------
extEepromAdrLowW:
;@----------------------------------------------------------------------------
	mov r0,r1
	adr eeptr,extEeprom
	b wsEepromAddressLowW
;@----------------------------------------------------------------------------
extEepromAdrHighW:
;@----------------------------------------------------------------------------
	mov r0,r1
	adr eeptr,extEeprom
	b wsEepromAddressHighW
;@----------------------------------------------------------------------------
extEepromCommandW:
;@----------------------------------------------------------------------------
	mov r0,r1
	adr eeptr,extEeprom
	b wsEepromCommandW
;@----------------------------------------------------------------------------
extEepromReset:
;@----------------------------------------------------------------------------
	ldr r0,eepromSize
	cmp r0,#0
	bxeq lr
	ldr r1,=extEepromMem
	adr eeptr,extEeprom
	b wsEepromReset
;@----------------------------------------------------------------------------
extEeprom:
	.space wsEepromSize

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
	.byte 0
g_machineSet:
	.byte HW_AUTO
g_lang:
	.byte 1						;@ language
g_paletteBank:
	.byte 0						;@ palettebank
	.space 2					;@ alignment.

wsHeader:
romSpacePtr:
	.long 0
g_BIOSBASE_BNW:
	.long 0
g_BIOSBASE_COLOR:
g_BIOSBASE_CRYSTAL:
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
sramSize:
	.long 0
eepromSize:
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
extEepromMem:
	.space 0x800
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
