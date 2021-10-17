#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARMV30MZ/ARMV30MZ.i"
#include "K2GE/K2GE.i"

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
	.global Z80_SetEnable
	.global Z80_nmi_do

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
	ldr r0,=EMUinput
	ldr r0,[r0]
	ldr r3,joyClick
	eor r3,r3,r0
	and r3,r3,r0
	str r0,joyClick

	ldr r2,=yStart
	ldrb r1,[r2]
	tst r0,#0x200				;@ L?
	subsne r1,#1
	movmi r1,#0
	tst r0,#0x100				;@ R?
	addne r1,#1
	cmp r1,#GAME_HEIGHT-SCREEN_HEIGHT
	movpl r1,#GAME_HEIGHT-SCREEN_HEIGHT
	strb r1,[r2]

	tst r3,#0x04				;@ NDS Select?
	tsteq r3,#0x800				;@ NDS Y?
	ldrne r2,=systemMemory+0xB3
	ldrbne r2,[r2]
	tstne r2,#4					;@ Power button NMI enabled?
	movne r0,#0x08				;@ 0x08 = Power button on NGP
	blne setInterruptExternal

	bl refreshEMUjoypads		;@ Z=1 if communication ok

;@----------------------------------------------------------------------------
ngpFrameLoop:
;@----------------------------------------------------------------------------
	ldrh r0,z80enabled
	ands r0,r0,r0,lsr#8
	beq NoZ80Now

	ldr z80optbl,=Z80OpTable
	ldr r0,z80CyclesPerScanline
	b Z80RestoreAndRunXCycles
ngpZ80End:
	add r0,z80optbl,#z80Regs
	stmia r0,{z80f-z80pc,z80sp}			;@ Save Z80 state
NoZ80Now:
;@--------------------------------------
	ldr t9optbl,=tlcs900HState
	ldr r0,tlcs900hCyclesPerScanline
	b tlcsRestoreAndRunXCycles
tlcs_return:
tlcs900hEnd:
;@--------------------------------------
	ldr geptr,=k2GE_0
	bl k2GEDoScanline
	cmp r0,#0
	bne ngpFrameLoop
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
tlcs900hCyclesPerScanline:	.long 0
z80CyclesPerScanline:	.long 0
joyClick:			.long 0
frameTotal:			.long 0		;@ Let ui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

z80enabled:			.byte 0
g_z80onoff:			.byte 1
					.byte 0,0

;@----------------------------------------------------------------------------
setCpuSpeed:				;@ in r0=0 normal / !=0 half speed.
	.type   tweakCpuSpeed STT_FUNC
;@----------------------------------------------------------------------------
;@---Speed - 6.144MHz / 60Hz / 198 lines	;NGP TLCS-900H.
	ldr r0,=T9_HINT_RATE				;@ 515
	str r0,tlcs900hCyclesPerScanline
;@---Speed - 3.072MHz / 60Hz / 198 lines	;NGP Z80.
	mov r0,r0,lsr#1
	str r0,z80CyclesPerScanline
	bx lr
;@----------------------------------------------------------------------------
cpuReset:					;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	bl setCpuSpeed
	ldr t9optbl,=tlcs900HState
	bl tlcs900HReset


;@--------------------------------------
	ldr z80optbl,=Z80OpTable

	adr r0,ngpZ80End
	str r0,[z80optbl,#z80NextTimeout]
	str r0,[z80optbl,#z80NextTimeout_]

	mov r0,#0
	bl Z80Reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
