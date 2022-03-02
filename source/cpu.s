#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARMV30MZ/ARMV30MZ.i"
#include "Sphinx/Sphinx.i"

#define CYCLE_PSL (256)

	.global run
	.global cpuInit
	.global cpuReset
	.global isConsoleRunning
	.global isConsoleSleeping
	.global tweakCpuSpeed
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global cpu1SetIRQ
	.global tlcs_return

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

//	tst r3,#0x04				;@ NDS Select?
//	tsteq r3,#0x800				;@ NDS Y?
//	ldrne r2,=systemMemory+0xB3
//	ldrbne r2,[r2]
//	tstne r2,#4					;@ Power button NMI enabled?
//	and r0,r3,#0x04				;@ NDS Select?
//	ldr v30ptr,=V30OpTable
//	bl V30SetNMIPin

	bl refreshEMUjoypads		;@ Z=1 if communication ok

	ldr v30ptr,=V30OpTable
	ldr v30cyc,[v30ptr,#v30ICount]
	ldr v30pc,[v30ptr,#v30IP]
	ldr v30f,[v30ptr,#v30Flags]
;@----------------------------------------------------------------------------
wsFrameLoop:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bl V30RunXCycles
	ldr spxptr,=sphinx0
	bl wsvDoScanline
	cmp r0,#0
	bne wsFrameLoop

;@----------------------------------------------------------------------------
	str v30cyc,[v30ptr,#v30ICount]
	str v30pc,[v30ptr,#v30IP]
	str v30f,[v30ptr,#v30Flags]
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
cpuInit:					;@ Called by machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{v30ptr,lr}
	ldr v30ptr,=V30OpTable

	mov r0,#CYCLE_PSL
	str r0,v30MZCyclesPerScanline
	mov r0,v30ptr
	bl V30Init

	ldmfd sp!,{v30ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
cpuReset:					;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{v30ptr,lr}
	ldr v30ptr,=V30OpTable

	mov r0,v30ptr
	bl V30Reset
	ldr r0,=getInterruptVector
	str r0,[v30ptr,#v30IrqVectorFunc]

	ldmfd sp!,{v30ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
