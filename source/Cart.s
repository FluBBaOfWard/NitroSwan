#ifdef __arm__

#include "Equates.h"
#include "EEPROM.i"
#include "Sphinx/Sphinx.i"
#include "ARMV30MZ/ARMV30MZ.i"

	.global machineInit
	.global loadCart
	.global romNum
	.global cartFlags
	.global romStart
	.global reBankSwitch4_F_W
	.global BankSwitch4_F_W
	.global BankSwitch2_W
	.global BankSwitch3_W
	.global BankSwitch1_W

	.global wsHeader
	.global romSpacePtr
	.global MEMMAPTBL_

	.global biosBase
	.global biosSpace
	.global biosSpaceColor
	.global biosSpaceCrystal
	.global g_BIOSBASE_BNW
	.global g_BIOSBASE_COLOR
	.global g_BIOSBASE_CRYSTAL
	.global wsRAM
	.global wsSRAM
	.global extEepromMem
	.global sramSize
	.global eepromSize
	.global gRomSize
	.global maxRomSize
	.global romMask
	.global gConfig
	.global gMachine
	.global gMachineSet
	.global gSOC
	.global gLang
	.global gPaletteBank

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
WSC_BIOS_INTERNAL:
SC_BIOS_INTERNAL:
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
loadCart: 		;@ Called from C:
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr v30ptr,=V30OpTable

	ldr r0,romSize
	movs r2,r0,lsr#16		;@ 64kB blocks.
	subne r2,r2,#1
	str r2,romMask			;@ romMask=romBlocks-1

	ldr r7,romSpacePtr		;@ r7=rombase til end of loadcart

	add r4,v30ptr,#v30MemTbl
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

	ldrb r5,gMachine
	cmp r5,#HW_WONDERSWAN
	cmpne r5,#HW_POCKETCHALLENGEV2
	moveq r0,#1				;@ Set boot rom overlay (size small)
	ldreq r1,g_BIOSBASE_BNW
	ldreq r2,=WS_BIOS_INTERNAL
	moveq r4,#SOC_ASWAN
	movne r0,#2				;@ Set boot rom overlay (size big)
	ldrne r1,g_BIOSBASE_COLOR
	ldrne r2,=WSC_BIOS_INTERNAL
	movne r4,#SOC_SPHINX
	cmp r5,#HW_SWANCRYSTAL
	ldreq r1,g_BIOSBASE_CRYSTAL
	ldreq r2,=SC_BIOS_INTERNAL
	moveq r4,#SOC_SPHINX2
	strb r4,gSOC
	cmp r1,#0
	moveq r1,r2				;@ Use internal bios
	str r1,biosBase
	bl setBootRomOverlay

//	sub r0,r0,#0xE000
//	str r0,[r4,#0xF*4]


	ldr r0,=wsRAM			;@ Clear RAM
	mov r1,#0x10000/4
	bl memclr_
	cmp r4,#SOC_ASWAN
	ldreq r0,=wsRAM+0x4000	;@ Clear mem outside of RAM
	moveq r1,#0x90
	moveq r2,#0xC000
	bleq memset

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
	ldr spxptr,=sphinx0
	ldrb r1,[spxptr,#wsvBnk0Slct]
;@----------------------------------------------------------------------------
BankSwitch4_F_W:					;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	strb r1,[spxptr,#wsvBnk0Slct]
	mov r1,r1,lsl#4
	orr r1,r1,#4

	ldr r0,romMask
	ldr r2,romSpacePtr
	add r12,v30ptr,#v30MemTbl+4*4
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
	ldr spxptr,=sphinx0
	ldrb r1,[spxptr,#wsvBnk2Slct]
;@----------------------------------------------------------------------------
BankSwitch2_W:					;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	strb r1,[spxptr,#wsvBnk2Slct]

	ldr r0,romMask
	ldr r2,romSpacePtr
	and r3,r1,r0
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	str r3,[v30ptr,#v30MemTbl+2*4]

	bx lr

;@----------------------------------------------------------------------------
reBankSwitch3_W:				;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	ldrb r1,[spxptr,#wsvBnk3Slct]
;@----------------------------------------------------------------------------
BankSwitch3_W:					;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	strb r1,[spxptr,#wsvBnk3Slct]

	ldr r0,romMask
	ldr r2,romSpacePtr
	and r3,r1,r0
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	str r3,[v30ptr,#v30MemTbl+3*4]

	bx lr
;@----------------------------------------------------------------------------
reBankSwitch1_W:				;@ 0x10000-0x1FFFF
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	ldrb r1,[spxptr,#wsvBnk1Slct]
;@----------------------------------------------------------------------------
BankSwitch1_W:					;@ 0x10000-0x1FFFF
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	strb r1,[spxptr,#wsvBnk1Slct]

	ldr r0,sramSize
	sub r0,r0,#1
	mov r0,r0,lsr#16
	ldr r2,=wsSRAM
	and r3,r1,r0
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	str r3,[v30ptr,#v30MemTbl+1*4]

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
gConfig:
	.byte 0						;@ Config, bit 7=BIOS on/off
gMachineSet:
	.byte HW_AUTO
gMachine:
	.byte HW_WONDERSWANCOLOR
gSOC:
	.byte SOC_SPHINX
gLang:
	.byte 1						;@ language
gPaletteBank:
	.byte 0						;@ palettebank
	.space 1					;@ alignment.

wsHeader:
romSpacePtr:
	.long 0
g_BIOSBASE_BNW:
	.long 0
g_BIOSBASE_COLOR:
	.long 0
g_BIOSBASE_CRYSTAL:
	.long 0
gRomSize:
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
	.align 2
wsRAM:
	.space 0x10000
wsSRAM:
	.space 0x40000
biosSpace:
	.space 0x1000
biosSpaceColor:
	.space 0x2000
biosSpaceCrystal:
	.space 0x2000
extEepromMem:
	.space 0x800
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
