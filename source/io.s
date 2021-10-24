#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"
#include "WSVideo/WSVideo.i"

	.global ioReset
	.global transferTime
	.global refreshEMUjoypads
	.global ioSaveState
	.global ioLoadState
	.global ioGetStateSize
	.global ioReadByte
	.global ioWriteByte

	.global joyCfg
	.global EMUinput

	.global t9LoadB_Low
	.global t9StoreB_Low
	.global serialinterrupt
	.global resetSIO
	.global updateSlowIO
	.global g_subBatteryLevel
	.global batteryLevel
	.global systemMemory
	.global IO_regs

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
ioReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=SysMemDefault
	bl initSysMem
	bl transferTime

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
initSysMem:					;@ In r0=values ptr.
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}

	mov r4,r0
	mov r5,#0xFF
initMemLoop:
	ldrb r0,[r4,r5]
	mov r1,r5
	bl IO_reg_W
	subs r5,r5,#1
	bpl initMemLoop

	ldmfd sp!,{r4-r5,pc}
;@----------------------------------------------------------------------------
ioSaveState:			;@ In r0=destination. Out r0=size.
	.type   ioSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r1,=systemMemory
	mov r2,#0x100
	bl memcpy

	ldmfd sp!,{lr}
	mov r0,#0x100
	bx lr
;@----------------------------------------------------------------------------
ioLoadState:			;@ In r0=source. Out r0=size.
	.type   ioLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	bl initSysMem

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
	ldr r2,=systemMemory
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
	andne r1,r3,#3
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
	ldr r1,=IO_regs
	ldrb r1,[r1,#0xB5]
	and r1,r1,#0xF0
	ldrb r0,joy0State
	tst r1,#0x20
	andne r0,r0,#0x0F
	tst r1,#0x40
	movne r0,r0,lsr#4

	orr r0,r0,r1
	
	bx lr

;@----------------------------------------------------------------------------
IO_machine_R:
;@----------------------------------------------------------------------------
	ldr r1,=IO_regs
	ldrb r0,[r1,r0]
	orr r0,r0,#2
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

	ldr r1,=g_subBatteryLevel
	ldr r0,[r1]
	subs r0,r0,#0x00000100
	movmi r0,#0x00001000
	str r0,[r1]

	ldr r2,=systemMemory
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
	moveq r0,#0x0A
//	beq setInterrupt

	bx lr


;@----------------------------------------------------------------------------
ioReadByte:
	.type ioReadByte STT_FUNC
;@----------------------------------------------------------------------------
	ldr geptr,=k2GE_0
	and r0,r0,#0xFF
	ldr pc,[pc,r0,lsl#2]
	.long 0
IN_Table:
	.long IO_reg_R				;@ 0x00
	.long IO_reg_R
	.long wsvVCountR
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x08
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x10
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x18
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x20
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x28
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x30
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x38
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x40
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_important_R		;@ 0x48
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x50
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x58
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x60
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x68
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x70
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x78
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x80
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x88
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0x90
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0x98
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_machine_R			;@ 0xA0, color or mono
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0xA8
	.long IO_reg_R
	.long IO_important_R		;@ 0xAA vcounter?
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0xB0
	.long IO_reg_R
	.long IO_reg_R
	.long IO_important_R		;@ 0xB3 communication direction
	.long IO_reg_R
	.long IOPortA_R				;@ 0xB5 keypad
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0xB8
	.long IO_reg_R
	.long IO_important_R		;@ 0xBA int-eeprom even byte read
	.long IO_important_R		;@ 0xBB int-eeprom odd byte read
	.long IO_reg_R
	.long IO_reg_R
	.long IO_important_R		;@ 0xBE int-eeprom status
	.long IO_reg_R

	.long BankSwitch4_F_R		;@ 0xC0
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_important_R		;@ 0xC4 ext-eeprom even byte read
	.long IO_important_R		;@ 0xC5 ext-eeprom odd byte read
	.long IO_reg_R
	.long IO_reg_R
	.long IO_important_R		;@ 0xC8 ext-eeprom status
	.long IO_reg_R
	.long IO_important_R		;@ 0xCA rtc status
	.long IO_important_R		;@ 0xCB rtc read
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0xD0
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0xD8
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0xE0
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0xE8
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R

	.long IO_reg_R				;@ 0xF0
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R				;@ 0xF8
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R
	.long IO_reg_R


;@----------------------------------------------------------------------------
ioWriteByte:				;@ r0=adr, r1=val
	.type ioWriteByte STT_FUNC
;@----------------------------------------------------------------------------
	ldr geptr,=k2GE_0
	and r0,r0,#0xFF
	ldr r2,=IO_regs
	strb r1,[r2,r0]
	ldr pc,[pc,r0,lsl#2]
	.long 0
OUT_Table:
	.long wsvDisplayControlW	;@ 0x00
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long wsvSpriteTblAdrW
	.long wsvSpriteStartW
	.long wsvSpriteEndW			;@ last sprite, start sprite DMA?
	.long wsvTileMapBaseW
	.long IO_reg_W				;@ 0x08
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long wsvBgScrXW			;@ 0x10
	.long wsvBgScrYW
	.long wsvFgScrXW
	.long wsvFgScrYW
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x18
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x20
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x28
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x30
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x38
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x40	DMA, source
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ DMA destination
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ DMA length
	.long IO_reg_W
	.long DMA_Start_W			;@ 0x48
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x50
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x58
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x60
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x68
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x70
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x78
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x80
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x88
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0x90
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0x98
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0xA0
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0xA8
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0xB0
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0xB8
	.long IO_reg_W
	.long IO_important_W		;@ 0xBA int-eeprom even byte write
	.long IO_important_W		;@ 0xBB int-eeprom odd byte write
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long BankSwitch4_F_W		;@ 0xC0
	.long IO_reg_W
	.long BankSwitch2_W
	.long BankSwitch3_W
	.long IO_important_W		;@ 0xC4 ext-eeprom even byte write
	.long IO_important_W		;@ 0xC5 ext-eeprom odd byte write
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0xC8
	.long IO_reg_W
	.long IO_important_W		;@ 0xCA rtc reset
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0xD0
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0xD8
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0xE0
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0xE8
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

	.long IO_reg_W				;@ 0xF0
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W				;@ 0xF8
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W
	.long IO_reg_W

;@----------------------------------------------------------------------------
IO_important_W:
	mov r11,r11					;@ No$GBA breakpoint
;@----------------------------------------------------------------------------
IO_reg_W:
	adr r2,IO_regs
	strb r1,[r2,r0]
	bx lr
;@----------------------------------------------------------------------------
IO_important_R:
	mov r11,r11					;@ No$GBA breakpoint
;@----------------------------------------------------------------------------
IO_reg_R:
	ldrb r0,[pc,r0]
	bx lr
;@----------------------------------------------------------------------------
systemMemory:
IO_regs:
	.space 0x100

;@----------------------------------------------------------------------------
DMA_Start_W:
;@----------------------------------------------------------------------------
	tst r1,#0x80
	bxeq lr

	stmfd sp!,{r4-r7,lr}
	adr r7,IO_regs
	ldrb r4,[r7,#0x40]
	ldrb r0,[r7,#0x41]
	orr r4,r4,r0,lsl#8
	ldrb r0,[r7,#0x42]
	orr r4,r4,r0,lsl#16			;@ r4=source

	ldrb r5,[r7,#0x44]
	ldrb r0,[r7,#0x45]
	orr r5,r5,r0,lsl#8
	ldrb r0,[r7,#0x43]
	orr r5,r5,r0,lsl#16			;@ r5=destination

	ldrb r6,[r7,#0x46]
	ldrb r0,[r7,#0x47]
	orr r6,r6,r0,lsl#8			;@ r6=length

dma_loop:
	mov r0,r4
	bl cpuReadByte
	mov r1,r0
	mov r0,r5
	bl cpuWriteByte
	add r4,r4,#1
	add r5,r5,#1
	subs r6,r6,#1
	bne dma_loop

	strb r4,[r7,#0x40]
	mov r4,r4,lsr#8
	strb r4,[r7,#0x41]

	strb r5,[r7,#0x44]
	mov r5,r5,lsr#8
	strb r5,[r7,#0x45]

	mov r0,#0
	strb r0,[r7,#0x46]
	strb r0,[r7,#0x47]
	strb r0,[r7,#0x48]


	ldmfd sp!,{r4-r7,lr}
	bx lr
;@----------------------------------------------------------------------------

SysMemDefault:
IO_Default:
	.byte 0x00, 0x00, 0x9d, 0xbb, 0x00, 0x00, 0x00, 0x26, 0xfe, 0xde, 0xf9, 0xfb, 0xdb, 0xd7, 0x7f, 0xf5
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x9e, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x99, 0xfd, 0xb7, 0xdf
	.byte 0x30, 0x57, 0x75, 0x76, 0x15, 0x73, 0x77, 0x77, 0x20, 0x75, 0x50, 0x36, 0x70, 0x67, 0x50, 0x77
	.byte 0x57, 0x54, 0x75, 0x77, 0x75, 0x17, 0x37, 0x73, 0x50, 0x57, 0x60, 0x77, 0x70, 0x77, 0x10, 0x73
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x0a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00
	.byte 0x85, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4f, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0xdb, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x42, 0x00, 0x83, 0x00
	.byte 0x2f, 0x3f, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1
	.byte 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1
	.byte 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1
	.byte 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1, 0xd1


;@----------------------------------------------------------------------------
g_subBatteryLevel:
	.long 0x3000000				;@ subBatteryLevel
batteryLevel:
	.long 0xFFFF				;@ Max = 0xFFFF (0x3FF)
								;@ To start > 0x8400 (0x210)
								;@ Low < 0x8000 (0x200)
								;@ Bad < 0x7880 (0x1E2)
								;@ Shutdown <= 0x74C0 (0x1D3)
								;@ Alarm minimum = 0x5B80 (0x16E)
rtcTimer:
	.byte 0
	.byte 0
	.byte 0
	.byte 0

	.end
#endif // #ifdef __arm__
