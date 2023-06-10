#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARMV30MZ/ARMV30MZ.i"
#include "ARMV30MZ/ARMV30MZmac.h"
#include "Sphinx/Sphinx.i"

#define CYCLE_PSL (256)

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut

	.syntax unified
	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
run:						;@ Return after X frame(s)
	.type run STT_FUNC
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
	ldr r0,=joy0State
	ldr r0,[r0]
	ldr r3,joyClick
	eor r3,r3,r0
	and r3,r3,r0
	str r0,joyClick

	tst r3,#0x10000				;@ WS Sound?
	blne pushVolumeButton

	bl refreshEMUjoypads

	ldr v30ptr,=V30OpTable
	add r1,v30ptr,#v30PrefixBase
	ldmia r1,{v30csr-v30cyc}	;@ Restore V30MZ state
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
	add r0,v30ptr,#v30PrefixBase
	stmia r0,{v30csr-v30cyc}	;@ Save V30MZ state
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
frameTotal:			.long 0		;@ Let Gui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr v30ptr,=V30OpTable
	add r1,v30ptr,#v30PrefixBase
	ldmia r1,{v30csr-v30cyc}		;@ Restore V30MZ state
;@----------------------------------------------------------------------------
wsStepLoop:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bl V30RunXCycles
	ldr spxptr,=sphinx0
	bl wsvDoScanline
	cmp r0,#0
	bne wsStepLoop

	mov r0,#CYCLE_PSL
	bl V30RunXCycles
	ldr spxptr,=sphinx0
	bl wsvDoScanline
;@----------------------------------------------------------------------------
	add r0,v30ptr,#v30PrefixBase
	stmia r0,{v30csr-v30cyc}		;@ Save V30MZ state

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
	bx lr
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
