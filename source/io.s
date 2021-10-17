#ifdef __arm__

#include "TLCS900H/TLCS900H.i"
#include "K2GE/K2GE.i"

	.global ioReset
	.global transferTime
	.global Z80In
	.global Z80Out
	.global refreshEMUjoypads
	.global ioSaveState
	.global ioLoadState
	.global ioGetStateSize

	.global joyCfg
	.global EMUinput

	.global t9LoadB_Low
	.global t9StoreB_Low
	.global serialinterrupt
	.global resetSIO
	.global updateSlowIO
	.global z80ReadLatch
	.global g_subBatteryLevel
	.global batteryLevel
	.global commByte
	.global system_comms_read
	.global system_comms_poll
	.global system_comms_write
	.global systemMemory

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
	bl t9StoreB_Low
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
	adr r1,rlud2lrud
	ldrb r0,[r1,r0,lsr#4]


	ands r1,r3,#3				;@ A/B buttons
	cmpne r1,#3
	eorne r1,r1,#3
	tst r2,#0x400				;@ Swap A/B?
	andne r1,r3,#3
	orr r0,r0,r1,lsl#4

	tst r4,#0x08				;@ NDS Start
	tsteq r4,#0x400				;@ NDS X
	orrne r0,r0,#0x40			;@ NGP Option
	tst r4,#0x200				;@ NDS L
	orrne r0,r0,#0x80			;@ NGP D

	ldr r2,=systemMemory+0xB0	;@ HW joypad
	strb r0,[r2]

	mov r0,#0xFF
	tst r4,#0x04				;@ NDS Select
	tsteq r4,#0x800				;@ NDS Y
	bicne r0,r0,#0x01			;@ NGP Power
	ldr r1,=g_subBatteryLevel
	ldr r1,[r1]
	tst r1,#0x2000000			;@ highest bit of subbattery level
	biceq r0,r0,#0x02
	strb r0,[r2,#1]				;@ HW powerbutton + subbattery

	bx lr

joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
playerCount:.long 0			;@ Number of players in multilink.
			.byte 0
			.byte 0
			.byte 0
			.byte 0
rlud2lrud:		.byte 0x00,0x08,0x04,0x0C, 0x01,0x09,0x05,0x0D, 0x02,0x0A,0x06,0x0E, 0x03,0x0B,0x07,0x0F

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
z80ReadLatch:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#0
	bl Z80SetNMIPin
	ldmfd sp!,{lr}
	ldrb r0,commByte				;@ 0xBC
	bx lr

;@----------------------------------------------------------------------------
system_comms_read:			;@ r0 = (uint8 *buffer)
	.type system_comms_read STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
system_comms_poll:			;@ r0 = (uint8 *buffer)
	.type system_comms_poll STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
system_comms_write:			;@ r0 = (uint8 data)
	.type system_comms_write STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#0
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
	beq setInterrupt

	bx lr

;@----------------------------------------------------------------------------
t9StoreB_Low:
;@----------------------------------------------------------------------------
	ldr t9optbl,=tlcs900HState	;@ !!!This should not be needed when called from asm.
	ldr r2,=systemMemory
	strb r0,[r2,r1]

	cmp r1,#0x50				;@ Serial channel 0 buffer.
	strbeq r0,sc0Buf
	bxeq lr

	cmp r1,#0xB2				;@ COMMStatus
	andeq r0,r0,#1
	strbeq r0,commStatus
	bxeq lr

	cmp r1,#0xB8				;@ Soundchip enable/disable, 0x55 On 0xAA Off.
	beq setMuteT6W28

	cmp r1,#0xB9				;@ Z80 enable/disable, 0x55 On 0xAA Off.
	beq Z80_SetEnable

	cmp r1,#0xBA				;@ Z80 NMI
	beq Z80_nmi_do

	cmp r1,#0xBC				;@ Z80_COM
	strbeq r0,commByte
	bxeq lr

	cmp r1,#0xA0				;@ T6W28, Right
	beq T6W28_R_W
	cmp r1,#0xA1				;@ T6W28, Left
	beq T6W28_L_W
	cmp r1,#0xA2				;@ T6W28 DAC, Left
	beq T6W28_DAC_L_W
;@	cmp r1,#0xA3				;@ T6W28 DAC, Right
;@	beq T6W28_DAC_R_W

	cmp r1,#0x6F				;@ Watchdog
	beq watchDogW

	cmp r1,#0x6D				;@ Battery A/D start
	beq ADStart

	cmp r1,#0x80				;@ CpuSpeed
	beq cpuSpeedW

	and r2,r1,#0xF0
	cmp r2,#0x20
	beq timer_write8

	and r0,r0,#0xFF
	cmp r2,#0x70
	beq int_write8

//	cmp r1,#0xB3				;@ Power button NMI on/off.
	bx lr

;@----------------------------------------------------------------------------
ADStart:
;@----------------------------------------------------------------------------
	tst r0,#0x04
	bxeq lr
	ldr r0,batteryLevel
	ldr r1,=systemMemory
	orr r0,r0,#0x3F				;@ bit 0=ready, bit 1-5=1.
	strh r0,[r1,#0x60]
	mov r0,#0x1C
	b setInterrupt

;@----------------------------------------------------------------------------
cpuSpeedW:
;@----------------------------------------------------------------------------
	adr r1,systemMemory
	and r0,r0,#0x07
	cmp r0,#4
	movpl r0,#4
	ldrb r2,[r1,#0x80]
	subs r2,r0,r2
	bxeq lr
	strb r0,[r1,#0x80]
	rsb r0,r0,#T9CYC_SHIFT
	strb r0,[t9optbl,#tlcs_cycShift]
	mov t9cycles,t9cycles,ror r2
	bx lr

;@----------------------------------------------------------------------------
t9LoadB_Low:
;@----------------------------------------------------------------------------
	and r1,r0,#0xF0

	cmp r1,#0x70
	beq int_read8

	cmp r1,#0x20
	beq timer_read8

	cmp r0,#0x50				;@ Serial channel 0 buffer.
	ldrbeq r0,sc0Buf
	bxeq lr

	cmp r0,#0xBC				;@ Z80_COM
	ldrbeq r0,commByte
	bxeq lr

	ldr r2,=systemMemory
	ldrb r0,[r2,r0]
	bx lr

;@----------------------------------------------------------------------------
systemMemory:
	.space 0x100


SysMemDefault:
	;@ 0x00													;@ 0x08
	.byte 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x08, 0xFF, 0xFF
	;@ 0x10													;@ 0x18
	.byte 0x34, 0x3C, 0xFF, 0xFF, 0xFF, 0x3F, 0x00, 0x00,	0x3F, 0xFF, 0x2D, 0x01, 0xFF, 0xFF, 0x03, 0xB2
	;@ 0x20													;@ 0x28
	.byte 0x80, 0x00, 0x01, 0x90, 0x03, 0xB0, 0x90, 0x62,	0x05, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x4C, 0x4C
	;@ 0x30													;@ 0x38
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x30, 0x00, 0x00, 0x00, 0x20, 0xFF, 0x80, 0x7F
	;@ 0x40													;@ 0x48
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0x50													;@ 0x58
	.byte 0x00, 0x20, 0x69, 0x15, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF
	;@ 0x60													;@ 0x68
	.byte 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x17, 0x17, 0x03, 0x03, 0x02, 0x00, 0x10, 0x4E
	;@ 0x70													;@ 0x78
	.byte 0x02, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0x80													;@ 0x88
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0x90													;@ 0x98
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0xA0													;@ 0xA8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0xB0													;@ 0xB8
	.byte 0x00, 0x00, 0x00, 0x04, 0x0A, 0x00, 0x00, 0x00,	0xAA, 0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0xC0													;@ 0xC8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0xD0													;@ 0xD8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0xE0													;@ 0xE8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	;@ 0xF0													;@ 0xF8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00


;@----------------------------------------------------------------------------
watchDogW:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
Z80In:
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
Z80Out:
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0
	b Z80SetIRQPin
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
sc0Buf:
	.byte 0
commStatus:
	.byte 0
commByte:
	.byte 0
//	.space 2

	.end
#endif // #ifdef __arm__
