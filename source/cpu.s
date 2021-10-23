#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARMV30MZ/ARMV30MZ.i"
#include "WSVideo/WSVideo.i"

#define CYCLE_PSL (256)

	.global run
	.global cpuReset
	.global isConsoleRunning
	.global isConsoleSleeping
	.global tweakCpuSpeed
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global cpu1SetIRQ
	.global tlcs_return
	.global setInterrupt

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
run:		;@ Return after 1 frame
	.type   run STT_FUNC
;@----------------------------------------------------------------------------
	ldrh r0,waitCountIn
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountIn
	bxne lr
	stmfd sp!,{r4-r11,lr}

;@----------------------------------------------------------------------------
runStart:
;@----------------------------------------------------------------------------
//	ldr r0,=EMUinput
//	ldr r0,[r0]
//	ldr r3,joyClick
//	eor r3,r3,r0
//	and r3,r3,r0
//	str r0,joyClick

//	ldr r2,=yStart
//	ldrb r1,[r2]
//	tst r0,#0x200				;@ L?
//	subsne r1,#1
//	movmi r1,#0
//	tst r0,#0x100				;@ R?
//	addne r1,#1
//	cmp r1,#GAME_HEIGHT-SCREEN_HEIGHT
//	movpl r1,#GAME_HEIGHT-SCREEN_HEIGHT
//	strb r1,[r2]

//	tst r3,#0x04				;@ NDS Select?
//	tsteq r3,#0x800				;@ NDS Y?
//	ldrne r2,=systemMemory+0xB3
//	ldrbne r2,[r2]
//	tstne r2,#4					;@ Power button NMI enabled?
//	movne r0,#0x08				;@ 0x08 = Power button on NGP
//	blne setInterruptExternal

	bl refreshEMUjoypads		;@ Z=1 if communication ok

	ldr r4,=nec_execute
	ldr r5,=nec_int
;@----------------------------------------------------------------------------
wsFrameLoop:
;@----------------------------------------------------------------------------

	bl scanlineHook
	bl executeLine
	ldr geptr,=k2GE_0
	bl k2GEDoScanline
	cmp r0,#0
	bne wsFrameLoop

;@----------------------------------------------------------------------------
	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------------------------
v30MZCyclesPerScanline:	.long 0
joyClick:			.long 0
frameTotal:			.long 0		;@ Let ui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
executeLine:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bx r4
;@----------------------------------------------------------------------------
scanlineHook:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r2,=IO_regs
	ldrb r0,[r2,#0xA4]
	cmp r0,#0
	beq noHBlIrq
	ldrb r1,[r2,#0xB2]
	tst r1,#0x80
	beq noHBlIrq
	ldrb r3,[r2,#0xA5]
	cmp r3,#0
	moveq r3,r0
	subs r3,r3,#1
	strb r3,[r2,#0xA5]
	bne noHBlIrq
	mov r0,#7
	bl setInterrupt
noHBlIrq:

	ldr geptr,=k2GE_0
	ldr r1,[geptr,#scanline]
	ldrb r0,[r2,#0x03]
	cmp r0,r1
	bne noLineIrq
	ldrb r1,[r2,#0xB2]
	tst r1,#0x10
	beq noLineIrq
	mov r0,#4
	bl setInterrupt
noLineIrq:

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
setInterrupt:			;@ r0=int number
;@----------------------------------------------------------------------------
	ldr r2,=IO_regs
	ldrb r1,[r2,#0xB6]
	mov r3,#1
	bic r1,r1,r3,lsl r0
	strb r1,[r2,#0xB6]
	ldrb r1,[r2,#0xB0]
	add r0,r0,r1
	mov r0,r0,lsl#2
	bx r5

;@----------------------------------------------------------------------------
cpuReset:					;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,#CYCLE_PSL
	str r0,v30MZCyclesPerScanline
	mov r0,#0
	ldr r1,=nec_reset
	blx r1

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
