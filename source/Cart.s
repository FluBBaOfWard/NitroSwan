#ifdef __arm__

#include "WSEEPROM/WSEEPROM.i"
#include "WSRTC/WSRTC.i"
#include "Sphinx/Sphinx.i"
#include "ARMV30MZ/ARMV30MZ.i"

	.global machineInit
	.global loadCart
	.global romNum
	.global cartFlags
	.global romStart
	.global reBankSwitchAll
	.global reBankSwitch4_F
	.global reBankSwitch1
	.global reBankSwitch2
	.global reBankSwitch3
	.global clearDirtyTiles

	.global romSpacePtr
	.global allocatedRomMem

	.global biosBase
	.global biosSpace
	.global biosSpaceColor
	.global biosSpaceCrystal
	.global g_BIOSBASE_BNW
	.global g_BIOSBASE_COLOR
	.global g_BIOSBASE_CRYSTAL
	.global wsRAM
	.global DIRTYTILES
	.global wsSRAM
	.global extEeprom
	.global extEepromMem
	.global sramSize
	.global eepromSize
	.global gRomSize
	.global maxRomSize
	.global allocatedRomMemSize
	.global romMask
	.global gGameHeader
	.global gGameID
	.global cartOrientation
	.global gConfig
	.global gMachine
	.global gMachineSet
	.global gSOC
	.global gLang
	.global gPaletteBank

	.global cartRtcUpdate

	.syntax unified
	.arm

	.section .rodata
	.align 2

ROM_Space:
//	.incbin "wsroms/Anchorz Field (Japan).ws"
//	.incbin "wsroms/Crazy Climber (J) [M][!].ws"
//	.incbin "wsroms/Chaos Demo V2.1 by Charles Doty (PD).wsc"
//	.incbin "wsroms/Dicing Knight. (J).wsc"
//	.incbin "wsroms/Guilty Gear Petit (J).wsc"
//	.incbin "wsroms/Inuyasha - Kagome no Sengoku Nikki (Japan).wsc"
//	.incbin "wsroms/Kaze no Klonoa - Moonlight Museum (Japan).ws"
//	.incbin "wsroms/Magical Drop for WonderSwan (Japan).ws"
//	.incbin "wsroms/Makaimura for WonderSwan (Japan).ws"
//	.incbin "wsroms/Mr. Driller (J) [!].wsc"
//	.incbin "wsroms/SD Gundam - Operation U.C. (Japan).wsc"
//	.incbin "wsroms/Tetris (Japan).wsc"
//	.incbin "wsroms/Tonpuusou (Japan).wsc"
//	.incbin "wsroms/WONDERPR.WSC"
//	.incbin "wsroms/WSCpuTest.wsc"
//	.incbin "wsroms/XI Little (Japan).wsc"
ROM_SpaceEnd:
WS_BIOS_INTERNAL:
//	.incbin "wsroms/boot.rom"
	.incbin "wsroms/ws_irom.bin"
WSC_BIOS_INTERNAL:
SC_BIOS_INTERNAL:
//	.incbin "wsroms/boot1.rom"
	.incbin "wsroms/wc_irom.bin"
//	.incbin "wsroms/wsc_irom.bin"

	.align 2
;@----------------------------------------------------------------------------
machineInit: 				;@ Called from C
	.type machineInit STT_FUNC
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
	bl cpuInit

	ldmfd sp!,{r4-r11,lr}
	bx lr

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
loadCart: 					;@ Called from C:
	.type loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr v30ptr,=V30OpTable

	bl fixRomSizeAndPtr

	bl resetCartridgeBanks

	ldr r1,=wsRAM
	str r1,[v30ptr,#v30MemTblInv-0x1*4]		;@ 0 RAM
	ldr r6,[v30ptr,#v30MemTblInv-0x10*4]	;@ MemMap

	ldr r4,=0xFFFF0				;@ Header offset
	add r4,r6,r4
	str r4,gGameHeader
	ldrb r0,[r4,#0x8]			;@ Game ID
	strb r0,gGameID
	ldrb r3,[r4,#0xB]			;@ NVRAM size
	mov r0,#0					;@ r0 = sram size
	mov r1,#0					;@ r1 = eeprom size
	cmp r3,#0x01				;@ 64kbit sram
	moveq r0,#0x2000
	cmp r3,#0x02				;@ 256kbit sram
	moveq r0,#0x8000
	cmp r3,#0x03				;@ 1Mbit sram
	moveq r0,#0x20000
	cmp r3,#0x04				;@ 2Mbit sram
	moveq r0,#0x40000
	cmp r3,#0x05				;@ 4Mbit sram
	moveq r0,#0x80000
	cmp r3,#0x10				;@ 1kbit eeprom
	moveq r1,#0x80
	cmp r3,#0x20				;@ 16kbit eeprom
	moveq r1,#0x800
	cmp r3,#0x50				;@ 8kbit eeprom
	moveq r1,#0x400
	str r0,sramSize
	str r1,eepromSize

	ldrb r0,[r4,#0xC]			;@ Flags
	and r0,r0,#1				;@ Orientation
	strb r0,cartOrientation

	ldrb r0,[r4,#0xD]			;@ Mapper? (RTC present)
	strb r0,rtcPresent

	ldrb r5,gMachine
	cmp r5,#HW_WONDERSWAN
	cmpne r5,#HW_POCKETCHALLENGEV2
	moveq r0,#1					;@ Set boot rom overlay (size small)
	ldreq r1,g_BIOSBASE_BNW
	ldreq r2,=WS_BIOS_INTERNAL
	moveq r4,#SOC_ASWAN
	movne r0,#2					;@ Set boot rom overlay (size big)
	ldrne r1,g_BIOSBASE_COLOR
	ldrne r2,=WSC_BIOS_INTERNAL
	movne r4,#SOC_SPHINX
	cmp r5,#HW_SWANCRYSTAL
	ldreq r1,g_BIOSBASE_CRYSTAL
	ldreq r2,=SC_BIOS_INTERNAL
	moveq r4,#SOC_SPHINX2
	strb r4,gSOC
	cmp r1,#0
	moveq r1,r2					;@ Use internal bios
	str r1,biosBase
	bl setBootRomOverlay


	ldr r0,=wsRAM				;@ Clear RAM
	mov r1,#0x10000/4
	bl memclr_
	bl clearDirtyTiles
	cmp r4,#SOC_ASWAN
	ldreq r0,=wsRAM+0x4000		;@ Clear mem outside of RAM
	moveq r1,#0x90
	moveq r2,#0xC000
	bleq memset

	ldr r0,eepromSize
	cmp r0,#0					;@ Does the cart use EEPROM?
	ldreq r0,=Luxsor2003R		;@ Nope, use new Mapper Chip.
	ldreq r1,=Luxsor2003W
	ldrne r0,=Luxsor2001R		;@ Yes, use old Mapper Chip.
	ldrne r1,=Luxsor2001W
	cmp r5,#HW_POCKETCHALLENGEV2
	ldreq r0,=KarnakR			;@ All PCV2 games uses Karnak mapper.
	ldreq r1,=KarnakW
	bl wsvSetCartMap

//	bl hacksInit
	bl extEepromReset
	bl cartRtcReset
	bl gfxReset
	bl resetCartridgeBanks
	bl ioReset
	bl soundReset
	bl cpuReset
	ldmfd sp!,{r4-r11,lr}
	bx lr


;@----------------------------------------------------------------------------
clearDirtyTiles:
;@----------------------------------------------------------------------------
	ldr r0,=DIRTYTILES			;@ Clear RAM
	mov r1,#0x800/4
	b memclr_

;@----------------------------------------------------------------------------
fixRomSizeAndPtr:
;@----------------------------------------------------------------------------
	ldr r0,romSize
	sub r1,r0,#1
	orr r1,r1,r1,lsr#1
	orr r1,r1,r1,lsr#2
	orr r1,r1,r1,lsr#4
	orr r1,r1,r1,lsr#8
	orr r1,r1,r1,lsr#16
	add r1,r1,#1				;@ RomSize Power of 2

	movs r2,r1,lsr#16			;@ 64kB blocks.
	subne r2,r2,#1
	str r2,romMask				;@ romMask=romBlocks-1

	ldr r2,romSpacePtr
	add r2,r2,r0
	sub r2,r2,r1
	str r2,romPtr
	sub r2,r2,#0x20000
	str r2,romPtr2
	sub r2,r2,#0x10000
	str r2,romPtr3
	sub r2,r2,#0x10000
	str r2,romPtr4

	bx lr
;@----------------------------------------------------------------------------
resetCartridgeBanks:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr spxptr,=sphinx0
	mov r0,#0xFF
	bl BankSwitch4_F_W
	mov r0,#0xFF
	bl BankSwitch1_W
	mov r0,#0xFF
	bl BankSwitch2_W
	mov r0,#0xFF
	bl BankSwitch3_W
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
reBankSwitchAll:
;@----------------------------------------------------------------------------
	stmfd sp!,{v30ptr,lr}
	ldr v30ptr,=V30OpTable
	bl reBankSwitch4_F
	bl reBankSwitch1
	bl reBankSwitch2
	bl reBankSwitch3
	ldmfd sp!,{v30ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
reBankSwitch4_F:			;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,#wsvBnk0SlctX]
;@----------------------------------------------------------------------------
BankSwitch4_F_W:			;@ 0x40000-0xFFFFF
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	and r0,r0,#0x3F
	strb r0,[spxptr,#wsvBnk0SlctX]
	orr r0,r0,#0x40000000

	ldr r1,romMask
	ldr r2,romPtr4
	add lr,v30ptr,#v30MemTblInv-5*4
tbLoop2:
	and r3,r1,r0,ror#28
	add r3,r2,r3,lsl#16		;@ 64kB blocks.
	sub r2,r2,#0x10000
	str r3,[lr],#-4
	adds r0,r0,#0x10000000
	bcc tbLoop2

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
BankSwitch1_H_W:			;@ 0x10000-0x1FFFF
;@----------------------------------------------------------------------------
	and r0,r0,#0x3
	strb r0,[spxptr,#wsvBnk1SlctX+1]
;@----------------------------------------------------------------------------
reBankSwitch1:				;@ 0x10000-0x1FFFF
;@----------------------------------------------------------------------------
	ldrh r0,[spxptr,#wsvBnk1SlctX]
;@----------------------------------------------------------------------------
BankSwitch1_W:				;@ 0x10000-0x1FFFF
BankSwitch1_L_W:			;@ 0x10000-0x1FFFF
;@----------------------------------------------------------------------------
	strb r0,[spxptr,#wsvBnk1SlctX]

	ldr r1,sramSize
	movs r1,r1,lsr#16			;@ 64kB blocks.
	subne r1,r1,#1
	and r1,r1,#3				;@ Mask for actual SRAM banks we emulate
	ldr r2,=wsSRAM-0x10000
	and r3,r1,r0
	add r3,r2,r3,lsl#16			;@ 64kB blocks.
	str r3,[v30ptr,#v30MemTblInv-2*4]

	bx lr
;@----------------------------------------------------------------------------
BankSwitch2_H_W:			;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	and r0,r0,#0x3
	strb r0,[spxptr,#wsvBnk2SlctX+1]
;@----------------------------------------------------------------------------
reBankSwitch2:				;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	ldrh r0,[spxptr,#wsvBnk2SlctX]
;@----------------------------------------------------------------------------
BankSwitch2_W:				;@ 0x20000-0x2FFFF
BankSwitch2_L_W:			;@ 0x20000-0x2FFFF
;@----------------------------------------------------------------------------
	strb r0,[spxptr,#wsvBnk2SlctX]

	ldr r1,romMask
	ldr r2,romPtr2
	and r3,r1,r0
	add r3,r2,r3,lsl#16			;@ 64kB blocks.
	str r3,[v30ptr,#v30MemTblInv-3*4]

	bx lr
;@----------------------------------------------------------------------------
BankSwitch3_H_W:			;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	and r0,r0,#0x3
	strb r0,[spxptr,#wsvBnk3SlctX+1]
;@----------------------------------------------------------------------------
reBankSwitch3:				;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	ldrh r0,[spxptr,#wsvBnk3SlctX]
;@----------------------------------------------------------------------------
BankSwitch3_W:				;@ 0x30000-0x3FFFF
BankSwitch3_L_W:			;@ 0x30000-0x3FFFF
;@----------------------------------------------------------------------------
	strb r0,[spxptr,#wsvBnk3SlctX]

	ldr r1,romMask
	ldr r2,romPtr3
	and r3,r1,r0
	add r3,r2,r3,lsl#16			;@ 64kB blocks.
	str r3,[v30ptr,#v30MemTblInv-4*4]

	bx lr

;@----------------------------------------------------------------------------
BankSwitch4_F_R:			;@ 0xC0/0xCF
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk0SlctX]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch1_R:				;@ 0xC1/0xD0
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk1SlctX]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch1_H_R:			;@ 0xD1
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk1SlctX+1]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch2_R:				;@ 0xC2/0xD2
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk2SlctX]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch2_H_R:			;@ 0xD3
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk2SlctX+1]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch3_R:				;@ 0xC3/0xD4
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk3SlctX]
	bx lr
;@----------------------------------------------------------------------------
BankSwitch3_H_R:			;@ 0xD5
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvBnk3SlctX+1]
	bx lr

;@----------------------------------------------------------------------------
cartGPIODirR:				;@ 0xCC General Purpose I/O enable/dir?, bit 3-0.
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvGPIOEnable]
	bx lr
;@----------------------------------------------------------------------------
cartGPIODataR:				;@ 0xCD General Purpose I/O data, bit 3-0.
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvGPIOData]
	bx lr
;@----------------------------------------------------------------------------
cartWWFlashR:				;@ 0xCE WonderWitch Flash/SRAM select
;@----------------------------------------------------------------------------
	ldrb r0,[spxptr,wsvWWitch]
	bx lr
;@----------------------------------------------------------------------------
cartUnmR:
;@----------------------------------------------------------------------------
	mov r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
cartGPIODirW:				;@ 0xCC General Purpose I/O enable, bit 3-0.
;@----------------------------------------------------------------------------
	strb r0,[spxptr,wsvGPIOEnable]
	bx lr
;@----------------------------------------------------------------------------
cartGPIODataW:				;@ 0xCD General Purpose I/O data, bit 3-0.
;@----------------------------------------------------------------------------
	strb r0,[spxptr,wsvGPIOData]
	bx lr
;@----------------------------------------------------------------------------
cartWWFlashW:				;@ 0xCE WonderWitch flash
;@----------------------------------------------------------------------------
	and r0,r0,#1
	strb r0,[spxptr,wsvWWitch]
	bx lr
;@----------------------------------------------------------------------------
cartUnmW:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
extEepromDataLowR:			;@ 0xC4
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromDataLowR
;@----------------------------------------------------------------------------
extEepromDataHighR:			;@ 0xC5
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromDataHighR
;@----------------------------------------------------------------------------
extEepromAdrLowR:			;@ 0xC6
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromAddressLowR
;@----------------------------------------------------------------------------
extEepromAdrHighR:			;@ 0xC7
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromAddressHighR
;@----------------------------------------------------------------------------
extEepromStatusR:			;@ 0xC8
;@----------------------------------------------------------------------------
	adr eeptr,extEeprom
	b wsEepromStatusR
;@----------------------------------------------------------------------------
extEepromDataLowW:			;@ 0xC4
;@----------------------------------------------------------------------------
	mov r1,r0
	adr eeptr,extEeprom
	b wsEepromDataLowW
;@----------------------------------------------------------------------------
extEepromDataHighW:			;@ 0xC5
;@----------------------------------------------------------------------------
	mov r1,r0
	adr eeptr,extEeprom
	b wsEepromDataHighW
;@----------------------------------------------------------------------------
extEepromAdrLowW:			;@ 0xC6
;@----------------------------------------------------------------------------
	mov r1,r0
	adr eeptr,extEeprom
	b wsEepromAddressLowW
;@----------------------------------------------------------------------------
extEepromAdrHighW:			;@ 0xC7
;@----------------------------------------------------------------------------
	mov r1,r0
	adr eeptr,extEeprom
	b wsEepromAddressHighW
;@----------------------------------------------------------------------------
extEepromCommandW:			;@ 0xC8
;@----------------------------------------------------------------------------
	mov r1,r0
	adr eeptr,extEeprom
	b wsEepromCommandW
;@----------------------------------------------------------------------------
extEepromReset:
;@----------------------------------------------------------------------------
	ldr r1,eepromSize
	cmp r1,#0
	bxeq lr
	ldr r2,=extEepromMem
	mov r3,#0					;@ Disallow protect
	adr eeptr,extEeprom
	b wsEepromReset
;@----------------------------------------------------------------------------
extEeprom:
	.space wsEepromSize

;@----------------------------------------------------------------------------
cartRtcStatusR:				;@ 0xCA
;@----------------------------------------------------------------------------
	adr rtcptr,cartRtc
	b wsRtcStatusR
;@----------------------------------------------------------------------------
cartRtcDataR:				;@ 0xCB
;@----------------------------------------------------------------------------
	adr rtcptr,cartRtc
	b wsRtcDataR
;@----------------------------------------------------------------------------
cartRtcCommandW:			;@ 0xCA
;@----------------------------------------------------------------------------
	mov r1,r0
	adr rtcptr,cartRtc
	b wsRtcCommandW
;@----------------------------------------------------------------------------
cartRtcDataW:				;@ 0xCB
;@----------------------------------------------------------------------------
	mov r1,r0
	adr rtcptr,cartRtc
	b wsRtcDataW
;@----------------------------------------------------------------------------
cartRtcReset:
;@----------------------------------------------------------------------------
	ldrb r0,rtcPresent
	cmp r0,#0
	bxeq lr
	stmfd sp!,{lr}
	adr rtcptr,cartRtc
	ldr r1,=setInterruptExternal
	bl wsRtcReset
	bl getTime					;@ r0 = ??ssMMHH, r1 = ??DDMMYY
	ldmfd sp!,{lr}
	mov r2,r1
	mov r1,r0
	adr rtcptr,cartRtc
	b wsRtcSetDateTime
;@----------------------------------------------------------------------------
cartRtcUpdate:				;@ r0=rtcptr. Call every second.
;@----------------------------------------------------------------------------
	ldrb r0,rtcPresent
	cmp r0,#0
	bxeq lr
	adr rtcptr,cartRtc
	b wsRtcUpdate
;@----------------------------------------------------------------------------
cartRtc:
	.space wsRtcSize

romNum:
	.long 0						;@ romnumber
romInfo:						;@
emuFlags:
	.byte 0						;@ emuflags      (label this so GUI.c can take a peek) see EmuSettings.h for bitfields
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
gGameID:
	.byte 0						;@ Game ID
rtcPresent:
	.byte 0						;@ RTC present in cartridge
cartOrientation:
	.byte 0						;@ 1=Vertical, 0=Horizontal
	.space 2					;@ alignment.

gGameHeader:
	.long 0
allocatedRomMem:
	.long 0
allocatedRomMemSize:
	.long 0
romSpacePtr:
	.long 0
romPtr:
	.long 0
romPtr2:
	.long 0
romPtr3:
	.long 0
romPtr4:
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
;@----------------------------------------------------------------------------
	.section .rodata
	.align 2

Luxsor2001R:
	.long BankSwitch4_F_R		;@ 0xC0 Bank ROM 0x40000-0xF0000
	.long BankSwitch1_R			;@ 0xC1 Bank SRAM 0x10000
	.long BankSwitch2_R			;@ 0xC2 Bank ROM 0x20000
	.long BankSwitch3_R			;@ 0xC3 Bank ROM 0x30000
	.long extEepromDataLowR		;@ 0xC4 ext-eeprom data low
	.long extEepromDataHighR	;@ 0xC5 ext-eeprom data high
	.long extEepromAdrLowR		;@ 0xC6 ext-eeprom address low
	.long extEepromAdrHighR		;@ 0xC7 ext-eeprom address high
	.long extEepromStatusR		;@ 0xC8 ext-eeprom status

	;@ 0xC9-0xCF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	;@ 0xD0-0xDF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	;@ 0xE0-0xEF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	;@ 0xF0-0xFF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR

Luxsor2001W:
	.long BankSwitch4_F_W		;@ 0xC0 Bank switch 0x40000-0xF0000
	.long BankSwitch1_W			;@ 0xC1 Bank switch 0x10000 (SRAM)
	.long BankSwitch2_W			;@ 0xC2 Bank switch 0x20000
	.long BankSwitch3_W			;@ 0xC3 Bank switch 0x30000
	.long extEepromDataLowW		;@ 0xC4 ext-eeprom data low
	.long extEepromDataHighW	;@ 0xC5 ext-eeprom data high
	.long extEepromAdrLowW		;@ 0xC6 ext-eeprom address low
	.long extEepromAdrHighW		;@ 0xC7 ext-eeprom address high
	.long extEepromCommandW		;@ 0xC8 ext-eeprom command
	;@ 0xC9-0xCF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	;@ 0xD6-0xDF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	;@ 0xE0-0xEF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	;@ 0xF0-0xFF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW

;@----------------------------------------------------------------------------
Luxsor2003R:
	.long BankSwitch4_F_R		;@ 0xC0 Bank ROM 0x40000-0xF0000
	.long BankSwitch1_R			;@ 0xC1 Bank SRAM 0x10000
	.long BankSwitch2_R			;@ 0xC2 Bank ROM 0x20000
	.long BankSwitch3_R			;@ 0xC3 Bank ROM 0x30000
	.long cartUnmR				;@ 0xC4
	.long cartUnmR				;@ 0xC5
	.long cartUnmR				;@ 0xC6
	.long cartUnmR				;@ 0xC7
	.long cartUnmR				;@ 0xC8
	.long cartUnmR				;@ 0xC9
	.long cartRtcStatusR		;@ 0xCA RTC status
	.long cartRtcDataR			;@ 0xCB RTC data read
	.long cartGPIODirR			;@ 0xCC General purpose input/output enable, bit 3-0.
	.long cartGPIODataR			;@ 0xCD General purpose input/output data, bit 3-0.
	.long cartWWFlashR			;@ 0xCE WonderWitch flash
	.long BankSwitch4_F_R		;@ 0xCF Alias to 0xC0

	.long BankSwitch1_R			;@ 0xD0 Alias to 0xC1
	.long BankSwitch1_H_R		;@ 0xD1 2 more bits for 0xC1
	.long BankSwitch2_R			;@ 0xD2 Alias to 0xC2
	.long BankSwitch2_H_R		;@ 0xD3 2 more bits for 0xC2
	.long BankSwitch3_R			;@ 0xD4 Alias to 0xC3
	.long BankSwitch3_H_R		;@ 0xD5 2 more bits for 0xC3
	;@ 0xD6-0xDF
	.long cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	;@ 0xE0-0xEF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	;@ 0xF0-0xFF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR

Luxsor2003W:
	.long BankSwitch4_F_W		;@ 0xC0 Bank switch 0x40000-0xF0000
	.long BankSwitch1_W			;@ 0xC1 Bank switch 0x10000 (SRAM)
	.long BankSwitch2_W			;@ 0xC2 Bank switch 0x20000
	.long BankSwitch3_W			;@ 0xC3 Bank switch 0x30000
	.long cartUnmW				;@ 0xC4
	.long cartUnmW				;@ 0xC5
	.long cartUnmW				;@ 0xC6
	.long cartUnmW				;@ 0xC7
	.long cartUnmW				;@ 0xC8
	.long cartUnmW				;@ 0xC9
	.long cartRtcCommandW		;@ 0xCA RTC command
	.long cartRtcDataW			;@ 0xCB RTC data write
	.long cartGPIODirW			;@ 0xCC General purpose input/output enable, bit 3-0.
	.long cartGPIODataW			;@ 0xCD General purpose input/output data, bit 3-0.
	.long cartWWFlashW			;@ 0xCE WonderWitch flash
	.long BankSwitch4_F_W		;@ 0xCF Alias to 0xC0

	.long BankSwitch1_L_W		;@ 0xD0 Alias to 0xC1
	.long BankSwitch1_H_W		;@ 0xD1 2 more bits for 0xC1
	.long BankSwitch2_L_W		;@ 0xD2 Alias to 0xC2
	.long BankSwitch2_H_W		;@ 0xD3 2 more bits for 0xC2
	.long BankSwitch3_L_W		;@ 0xD4 Alias to 0xC3
	.long BankSwitch3_H_W		;@ 0xD5 2 more bits for 0xC3
	;@ 0xD6-0xDF
	.long cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	;@ 0xE0-0xEF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	;@ 0xF0-0xFF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW

;@----------------------------------------------------------------------------
KarnakR:
	.long BankSwitch4_F_R		;@ 0xC0 Bank ROM 0x40000-0xF0000
	.long BankSwitch1_R			;@ 0xC1 Bank SRAM 0x10000
	.long BankSwitch2_R			;@ 0xC2 Bank ROM 0x20000
	.long BankSwitch3_R			;@ 0xC3 Bank ROM 0x30000
	.long cartUnmR				;@ 0xC4
	.long cartUnmR				;@ 0xC5
	.long cartUnmR				;@ 0xC6
	.long cartUnmR				;@ 0xC7
	.long cartUnmR				;@ 0xC8
	.long cartUnmR				;@ 0xC9
	.long cartUnmR				;@ 0xCA
	.long cartUnmR				;@ 0xCB
	.long cartGPIODirR			;@ 0xCC General purpose input/output enable, bit 3-0.
	.long cartGPIODataR			;@ 0xCD General purpose input/output data, bit 3-0.
	.long cartWWFlashR			;@ 0xCE WonderWitch flash
	.long BankSwitch4_F_R		;@ 0xCF Alias to 0xC0

	.long BankSwitch1_R			;@ 0xD0 Alias to 0xC1
	.long BankSwitch1_H_R		;@ 0xD1 2 more bits for 0xC1
	.long BankSwitch2_R			;@ 0xD2 Alias to 0xC2
	.long BankSwitch2_H_R		;@ 0xD3 2 more bits for 0xC2
	.long BankSwitch3_R			;@ 0xD4 Alias to 0xC3
	.long BankSwitch3_H_R		;@ 0xD5 2 more bits for 0xC3
	.long cartUnmR				;@ 0xD6 Programmable Interval Timer
	.long cartUnmR				;@ 0xD7
	.long cartUnmR				;@ 0xD8 ADPCM input
	.long cartUnmR				;@ 0xD9 ADPCM output
	;@ 0xDA-0xDF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	;@ 0xE0-0xEF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	;@ 0xF0-0xFF
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR
	.long cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR,cartUnmR

KarnakW:
	.long BankSwitch4_F_W		;@ 0xC0 Bank switch 0x40000-0xF0000
	.long BankSwitch1_W			;@ 0xC1 Bank switch 0x10000 (SRAM)
	.long BankSwitch2_W			;@ 0xC2 Bank switch 0x20000
	.long BankSwitch3_W			;@ 0xC3 Bank switch 0x30000
	.long cartUnmW				;@ 0xC4
	.long cartUnmW				;@ 0xC5
	.long cartUnmW				;@ 0xC6
	.long cartUnmW				;@ 0xC7
	.long cartUnmW				;@ 0xC8
	.long cartUnmW				;@ 0xC9
	.long cartUnmW				;@ 0xCA
	.long cartUnmW				;@ 0xCB
	.long cartGPIODirW			;@ 0xCC General purpose input/output enable, bit 3-0.
	.long cartGPIODataW			;@ 0xCD General purpose input/output data, bit 3-0.
	.long cartWWFlashW			;@ 0xCE WonderWitch flash
	.long BankSwitch4_F_W		;@ 0xCF Alias to 0xC0

	.long BankSwitch1_L_W		;@ 0xD0 Alias to 0xC1
	.long BankSwitch1_H_W		;@ 0xD1 2 more bits for 0xC1
	.long BankSwitch2_L_W		;@ 0xD2 Alias to 0xC2
	.long BankSwitch2_H_W		;@ 0xD3 2 more bits for 0xC2
	.long BankSwitch3_L_W		;@ 0xD4 Alias to 0xC3
	.long BankSwitch3_H_W		;@ 0xD5 2 more bits for 0xC3
	.long cartUnmW				;@ 0xD6 Programmable Interval Timer
	.long cartUnmW				;@ 0xD7
	.long cartUnmW				;@ 0xD8 ADPCM input
	.long cartUnmW				;@ 0xD9 ADPCM output
	;@ 0xDA-0xDF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	;@ 0xE0-0xEF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	;@ 0xF0-0xFF
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW
	.long cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW,cartUnmW

;@----------------------------------------------------------------------------
#ifdef GBA
	.section .sbss				;@ For the GBA
#else
	.section .bss
#endif
	.align 2
wsRAM:
	.space 0x10000
DIRTYTILES:
	.space 0x800
wsSRAM:
#ifdef GBA
	.space 0x10000				;@ For the GBA
#else
	.space 0x40000
#endif
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
