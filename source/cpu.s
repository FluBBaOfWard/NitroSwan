#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARMV30MZ/ARMV30MZ.i"
#include "Sphinx/WSVideo.i"

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
	.global setInterruptExternal

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
//	movne r0,#0x08				;@ 0x08 = Power button on WS
//	blne setInterruptExternal

	bl refreshEMUjoypads		;@ Z=1 if communication ok

	ldr r4,=nec_execute
	ldr r5,=nec_int
	ldr geptr,=wsv_0
;@----------------------------------------------------------------------------
wsFrameLoop:
;@----------------------------------------------------------------------------
	bl checkInterrupt
	bl executeLine
	ldr geptr,=wsv_0
	bl wsvDoScanline
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
setInterruptExternal:			;@ r0=int number
;@----------------------------------------------------------------------------
	and r0,r0,#7
	ldr geptr,=wsv_0
	mov r2,#1
	ldrb r1,[geptr,#wsvInterruptStatus]
	orr r1,r1,r2,lsl r0
	strb r1,[geptr,#wsvInterruptStatus]
;@----------------------------------------------------------------------------
checkInterrupt:
;@----------------------------------------------------------------------------
	ldrb r1,[geptr,#wsvInterruptStatus]
	ldrb r0,[geptr,#wsvInterruptEnable]
	ands r1,r1,r0
	bxeq lr
	clz r0,r1
	rsb r0,r0,#31
	ldrb r1,[geptr,#wsvInterruptBase]
	bic r1,r1,#7
	orr r0,r0,r1
	mov r0,r0,lsl#2
	bx r5

;@----------------------------------------------------------------------------
cpuReset:					;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,#CYCLE_PSL
	str r0,v30MZCyclesPerScanline
	mov r0,#0
	blx nec_reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
