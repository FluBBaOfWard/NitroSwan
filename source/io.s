#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"
#include "Sphinx/Sphinx.i"
#include "WSEEPROM/WSEEPROM.i"

	.global ioReset
	.global refreshEMUjoypads
	.global ioSaveState
	.global ioLoadState
	.global ioGetStateSize
	.global initIntEeprom

	.global updateSlowIO
	.global IOPortA_R

	.global intEepromSetSize
	.global intEepromDataLowR
	.global intEepromDataHighR
	.global intEepromAdrLowR
	.global intEepromAdrHighR
	.global intEepromStatusR
	.global intEepromDataLowW
	.global intEepromDataHighW
	.global intEepromAdrLowW
	.global intEepromAdrHighW
	.global intEepromCommandW

	.global joyCfg
	.global EMUinput
	.global batteryLevel
	.global wsEepromMem
	.global wscEepromMem
	.global scEepromMem

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
ioReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	bl intEepromReset

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
initIntEeprom:				;@ r0 = eepromAdr
	.type   initIntEeprom STT_FUNC
;@----------------------------------------------------------------------------
	add r0,r0,#0x60		;@ Name offset
	ldr r1,=eepromDefault
	mov r3,#16
eepromLoop:
	ldrb r2,[r1],#1
	strb r2,[r0],#1
	subs r3,r3,#1
	bne eepromLoop
	bx lr
;@----------------------------------------------------------------------------
eepromDefault: // From adr 0x60, "@ NITROSWAN @"
	.byte 0x25, 0x00, 0x18, 0x13, 0x1E, 0x1C, 0x19, 0x1D, 0x21, 0x0B, 0x18, 0x00, 0x25, 0x00, 0x00, 0x00

;@----------------------------------------------------------------------------
ioSaveState:			;@ In r0=destination. Out r0=size.
	.type   ioSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

//	ldr r1,=rtcRegs
//	mov r2,#0x100
//	bl memcpy

	ldmfd sp!,{lr}
	mov r0,#0x100
	bx lr
;@----------------------------------------------------------------------------
ioLoadState:			;@ In r0=source. Out r0=size.
	.type   ioLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

//	bl initSysMem

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
ioGetStateSize:		;@ Out r0=state size.
	.type   ioGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#0x100
	bx lr
;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------

		ldr r0,=frameTotal
		ldr r0,[r0]
		movs r0,r0,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	mov r3,r4
	and r0,r4,#0xf0
		ldr r2,joyCfg
		andcs r3,r3,r2
		tstcs r3,r3,lsr#10		;@ NDS L?
		andcs r3,r3,r2,lsr#16
	adr r1,dulr2dlur
	ldrb r0,[r1,r0,lsr#4]

	ldr spxptr,=sphinx0
	ldrb r1,[spxptr,#wsvOrientation]
	cmp r1,#0
	bne verticalJoypad

	tst r4,#0x200				;@ NDS L?
	moveq r0,r0,lsl#4			;@ Map dpad to X or Y keys.

	tst r4,#0x08				;@ NDS Start
	orrne r0,r0,#0x200			;@ WS Start

	ands r1,r3,#3				;@ A/B buttons
	cmpne r1,#3
	eorne r1,r1,#3
	tst r2,#0x400				;@ Swap A/B?
	andeq r1,r3,#3
	orr r0,r0,r1,lsl#10

	str r0,joy0State
	bx lr
;@----------------------------------------------------------------------------
verticalJoypad:
;@----------------------------------------------------------------------------
	tst r4,#0x08				;@ NDS Start
	orrne r0,r0,#0x200			;@ WS Start

	and r1,r4,#0x3				;@ A/B buttons
	and r2,r4,#0xC00			;@ X/Y buttons
	orr r1,r1,r2,lsr#8
	adr r2,abxy2ypad
	ldrb r1,[r2,r1]
	orr r0,r0,r1,lsl#4

	str r0,joy0State
	bx lr
;@----------------------------------------------------------------------------
joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
playerCount:.long 0			;@ Number of players in multilink.
joy0State:	.long 0
dulr2dlur:	.byte 0x00,0x02,0x08,0x0A, 0x01,0x03,0x09,0x0B, 0x04,0x06,0x0C,0x0E, 0x05,0x07,0x0D,0x0F
abxy2ypad:	.byte 0x00,0x02,0x04,0x06, 0x01,0x03,0x05,0x07, 0x08,0x0A,0x0C,0x0E, 0x09,0x0B,0x0D,0x0F

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
IOPortA_R:		;@ Player1...
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	ldrb r1,[spxptr,#wsvControls]
	and r1,r1,#0x70
	ldr r0,joy0State
	tst r1,#0x10		;@ Y keys enabled?
	biceq r0,r0,#0x00F
	tst r1,#0x20		;@ X keys enabled?
	biceq r0,r0,#0x0F0
	tst r1,#0x40		;@ Buttons enabled?
	biceq r0,r0,#0xF00
	orr r0,r0,r0,lsr#4
	orr r0,r0,r0,lsr#4
	and r0,r0,#0x0F
	orr r0,r0,r1

	bx lr

;@----------------------------------------------------------------------------
updateSlowIO:				;@ Call once every frame, updates rtc and battery levels.
;@----------------------------------------------------------------------------
	ldrb r0,slowTimer
	subs r0,r0,#1
	movmi r0,#74
	strb r0,slowTimer
	bxpl lr

	stmfd sp!,{r12,lr}
//	blx getBatteryLevel
	ldr r0,batteryLevel
	subs r0,r0,#1
	movmi r0,#1
	str r0,batteryLevel
	cmp r0,#10
	blmi setLowBattery
	ldmfd sp!,{r12,lr}

	b cartRtcUpdate

;@----------------------------------------------------------------------------
batteryLevel:
	.long 0x15000				;@ Around 24h (60*60*24)
slowTimer:
	.byte 0
	.byte 0
	.byte 0
	.byte 0
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
intEepromDataLowR:
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromDataLowR
;@----------------------------------------------------------------------------
intEepromDataHighR:
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromDataHighR
;@----------------------------------------------------------------------------
intEepromAdrLowR:
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromAddressLowR
;@----------------------------------------------------------------------------
intEepromAdrHighR:
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromAddressHighR
;@----------------------------------------------------------------------------
intEepromStatusR:
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromStatusR
;@----------------------------------------------------------------------------
intEepromDataLowW:		;@ r1 = value
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromDataLowW
;@----------------------------------------------------------------------------
intEepromDataHighW:		;@ r1 = value
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromDataHighW
;@----------------------------------------------------------------------------
intEepromAdrLowW:		;@ r1 = value
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromAddressLowW
;@----------------------------------------------------------------------------
intEepromAdrHighW:		;@ r1 = value
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromAddressHighW
;@----------------------------------------------------------------------------
intEepromCommandW:		;@ r1 = value
;@----------------------------------------------------------------------------
	adr eeptr,intEeprom
	b wsEepromCommandW
;@----------------------------------------------------------------------------
intEepromReset:
;@----------------------------------------------------------------------------
	ldr r0,=gSOC
	ldrb r0,[r0]
	cmp r0,#SOC_SPHINX
	ldrmi r2,=wsEepromMem
	ldreq r2,=wscEepromMem
	ldrhi r2,=scEepromMem
	mov r1,#0x080				;@  1kbit, 16kbit is switched to for Color _Games_.
	adr eeptr,intEeprom
	b wsEepromReset
;@----------------------------------------------------------------------------
intEepromSetSize:			;@ r0 = size, 0=1kbit, !0=16kbit
;@----------------------------------------------------------------------------
	cmp r0,#0
	moveq r1,#0x080				;@  1kbit
	movne r1,#0x800				;@ 16kbit
	adr eeptr,intEeprom
	b wsEepromSetSize
;@----------------------------------------------------------------------------
	.pool
intEeprom:
	.space wsEepromSize
wsEepromMem:
	.space 0x80
wscEepromMem:
	.space 0x800
scEepromMem:
	.space 0x800
;@----------------------------------------------------------------------------

	.end
#endif // #ifdef __arm__
