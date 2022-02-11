#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"
#include "Sphinx/Sphinx.i"
#include "WSEEPROM/WSEEPROM.i"

	.global ioReset
	.global transferTime
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
//	bl transferTime

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
transferTime:
	.type transferTime STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	bl getTime					;@ r0 = ??ssMMHH, r1 = ??DDMMYY
	ldr r2,=rtcRegs
	strb r1,[r2,#0x91]			;@ Year
	mov r1,r1,lsr#8
	strb r1,[r2,#0x92]			;@ Month
	mov r1,r1,lsr#8
	strb r1,[r2,#0x93]			;@ Day
	and r1,r0,#0x3F
	strb r1,[r2,#0x94]			;@ Hours
	mov r0,r0,lsr#8
	strb r0,[r2,#0x95]			;@ Minutes
	mov r0,r0,lsr#8
	strb r0,[r2,#0x96]			;@ Seconds

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------

		ldr r4,=frameTotal
		ldr r4,[r4]
		movs r0,r4,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	mov r3,r4
	and r0,r4,#0xf0
		ldr r2,joyCfg
		andcs r3,r3,r2
		tstcs r3,r3,lsr#10		;@ NDS L?
		andcs r3,r3,r2,lsr#16
	adr r1,dulr2dlur
	ldrb r0,[r1,r0,lsr#4]


	ands r1,r3,#3				;@ A/B buttons
	cmpne r1,#3
	eorne r1,r1,#3
	tst r2,#0x400				;@ Swap A/B?
	andeq r1,r3,#3
	orr r0,r0,r1,lsl#6

	tst r4,#0x08				;@ NDS Start
	orrne r0,r0,#0x20			;@ WS Start

	strb r0,joy0State

	bx lr

joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
playerCount:.long 0			;@ Number of players in multilink.
joy0State:	.byte 0
			.byte 0
			.byte 0
			.byte 0
dulr2dlur:	.byte 0x00,0x02,0x08,0x0A, 0x01,0x03,0x09,0x0B, 0x04,0x06,0x0C,0x0E, 0x05,0x07,0x0D,0x0F

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
IOPortA_R:		;@ Player1...
;@----------------------------------------------------------------------------
	ldr spxptr,=sphinx0
	ldrb r1,[spxptr,#wsvControls]
	and r1,r1,#0xF0
	ldrb r0,joy0State
	tst r1,#0x20
	biceq r0,r0,#0x0F
	tst r1,#0x40
	movne r0,r0,lsr#4
	and r0,r0,#0x0F

	orr r0,r0,r1

	bx lr

;@----------------------------------------------------------------------------
updateSlowIO:				;@ Call once every frame, updates rtc and battery levels.
;@----------------------------------------------------------------------------
	ldrb r0,rtcTimer
	subs r0,r0,#1
	movmi r0,#59
	strb r0,rtcTimer
	bxpl lr

	ldr r0,batteryLevel
	subs r0,r0,#1
	movmi r0,#1
	str r0,batteryLevel

	ldr r2,=rtcRegs
	ldrb r0,[r2,#0x90]			;@ RTC control
	tst r0,#1					;@ Enabled?
	bxeq lr

	ldrb r0,[r2,#0x96]			;@ Seconds
	add r0,r0,#0x01
	and r1,r0,#0x0F
	cmp r1,#0x0A
	addpl r0,r0,#0x06
	cmp r0,#0x60
	movpl r0,#0
	strb r0,[r2,#0x96]			;@ Seconds
	bmi checkForAlarm

	ldrb r0,[r2,#0x95]			;@ Minutes
	add r0,r0,#0x01
	and r1,r0,#0x0F
	cmp r1,#0x0A
	addpl r0,r0,#0x06
	cmp r0,#0x60
	movpl r0,#0
	strb r0,[r2,#0x95]			;@ Minutes
	bmi checkForAlarm

	ldrb r0,[r2,#0x94]			;@ Hours
	add r0,r0,#0x01
	and r1,r0,#0x0F
	cmp r1,#0x0A
	addpl r0,r0,#0x06
	cmp r0,#0x24
	movpl r0,#0
	strb r0,[r2,#0x94]			;@ Hours
	bmi checkForAlarm

	ldrb r0,[r2,#0x93]			;@ Days
	add r0,r0,#0x01
	and r1,r0,#0x0F
	cmp r1,#0x0A
	addpl r0,r0,#0x06
	cmp r0,#0x32
	movpl r0,#0
	strb r0,[r2,#0x93]			;@ Days
	bmi checkForAlarm

	ldrb r0,[r2,#0x92]			;@ Months
	add r0,r0,#0x01
	and r1,r0,#0x0F
	cmp r1,#0x0A
	addpl r0,r0,#0x06
	cmp r0,#0x13
	movpl r0,#1
	strb r0,[r2,#0x92]			;@ Months

checkForAlarm:
	ldrb r0,[r2,#0x96]			;@ Seconds
	cmp r0,#0x00
	ldrbeq r0,[r2,#0x95]		;@ RTC Minutes
	ldrbeq r1,[r2,#0x9A]		;@ ALARM Minutes
	cmpeq r0,r1
	ldrbeq r0,[r2,#0x94]		;@ RTC Hours
	ldrbeq r1,[r2,#0x99]		;@ ALARM Hours
	cmpeq r0,r1
	ldrbeq r0,[r2,#0x93]		;@ RTC Days
	ldrbeq r1,[r2,#0x98]		;@ ALARM Days
	moveq r0,#0x02				;@ Cartridge interrupt
//	beq setInterruptExternal

	bx lr


;@----------------------------------------------------------------------------
rtcRegs:
	.space 0x100
batteryLevel:
	.long 0xFFFF				;@ Max = 0xFFFF (0x3FF)
rtcTimer:
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
	movmi r1,#0x080				;@  1kbit
	movpl r1,#0x800				;@ 16kbit
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
