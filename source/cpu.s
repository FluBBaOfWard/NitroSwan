#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"
#include "ARMV30MZ/ARMV30MZmac.h"
#include "Sphinx/Sphinx.i"

#define ALLOW_REFRESH_CHG	(1<<19)

#define CYCLE_PSL (256)

	.global waitMaskIn
	.global waitMaskOut

	.global run
	.global stepFrame
	.global stepScanLine
	.global cpuInit
	.global cpuReset

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
	ldr v30ptr,=V30OpTable

	bl refreshEMUjoypads

	add r1,v30ptr,#v30PrefixBase
	ldmia r1,{v30csr-v30cyc}	;@ Restore V30MZ state

	ldr r0,=emuSettings
	ldr r0,[r0]
	tst r0,#ALLOW_REFRESH_CHG
	beq wsFrameLoop3DS
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
wsFrameLoopEnd:
	add r0,v30ptr,#v30PrefixBase
	stmia r0,{v30csr-v30cyc}	;@ Save V30MZ state

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------------------------
wsFrameLoop3DS:
;@----------------------------------------------------------------------------
	mov r0,#CYCLE_PSL
	bl V30RunXCycles
	ldr spxptr,=sphinx0
	bl wsvDoScanline
	ldr r1,scanLineCount3DS
	cmp r0,#0
	cmpeq r1,#2
	subsne r1,r1,#1
	moveq r1,#200				;@ (159 * 75.47) / 60 = 199.9955
	str r1,scanLineCount3DS
	bne wsFrameLoop3DS
	b wsFrameLoopEnd
;@----------------------------------------------------------------------------
v30MZCyclesPerScanline:	.long 0
scanLineCount3DS:	.long 200
joyClick:			.long 0
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepScanLine:				;@ Return after 1 scanline
	.type stepScanLine STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr v30ptr,=V30OpTable
	bl wsScanLine
	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
wsScanLine:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#CYCLE_PSL
	bl V30RestoreAndRunXCycles
	add r0,v30ptr,#v30PrefixBase
	stmia r0,{v30csr-v30cyc}	;@ Save V30MZ state
	ldmfd sp!,{lr}
	ldr spxptr,=sphinx0
	b wsvDoScanline
;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr v30ptr,=V30OpTable
;@----------------------------------------------------------------------------
wsStepLoop:
;@----------------------------------------------------------------------------
	bl wsScanLine
	cmp r0,#0
	bne wsStepLoop
	bl wsScanLine
;@----------------------------------------------------------------------------

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
	ldr r0,=getInterruptVector
	str r0,[v30ptr,#v30IrqVectorFunc]
	ldr r0,=setBusStatus
	str r0,[v30ptr,#v30BusStatusFunc]

	ldmfd sp!,{v30ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
cpuReset:					;@ Called by loadCart/resetGame, r0 = type
;@----------------------------------------------------------------------------
	stmfd sp!,{v30ptr,lr}
	mov r1,r0
	ldr v30ptr,=V30OpTable

	mov r0,v30ptr
	bl V30Reset

	ldmfd sp!,{v30ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
