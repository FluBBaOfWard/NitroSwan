#ifdef __arm__

#include "Sphinx/Sphinx.i"

	.global soundInit
	.global soundReset
	.global VblSound2
	.global setMuteSoundGUI

	.extern pauseEmulation

;@----------------------------------------------------------------------------

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
soundInit:
	.type soundInit STT_FUNC
;@----------------------------------------------------------------------------
//	stmfd sp!,{lr}

//	ldmfd sp!,{lr}
//	bx lr

;@----------------------------------------------------------------------------
soundReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r0,#0
	ldr spxptr,=sphinx0
	bl wsAudioReset			;@ sound
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type   setMuteSoundGUI STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=pauseEmulation		;@ Output silence when emulation paused.
	ldrb r0,[r1]
	strb r0,muteSoundGUI
	bx lr
;@----------------------------------------------------------------------------
VblSound2:					;@ r0=length, r1=pointer
;@----------------------------------------------------------------------------
;@	mov r11,r11
	stmfd sp!,{r0,r1,lr}

	ldr r2,muteSound
	cmp r2,#0
	bne silenceMix
//	ldrb r2,muteSoundChip
//	cmp r2,#0
//	bne playSamples

	ldr spxptr,=sphinx0
//	mov r0,r0,lsl#2
	bl wsAudioMixer
	ldmfd sp!,{r0,r1,lr}
	bx lr

playSamples:
	stmfd sp!,{r4-r6}
	mov r12,r0
	ldr r6,pcmReadPtr
	ldr r4,pcmWritePtr
	mov r2,#27
//	subs r2,r4,r6
//	addmi r2,r2,#0x1000
	add r4,r6,r2
	str r4,pcmReadPtr
	ldr r3,=WAVBUFFER
	mov r6,r6,lsl#20
	mov r5,r0
wavLoop:
	ldrb r4,[r3,r6,lsr#20]
	subs r5,r5,r2
	addmi r6,r6,#0x00100000
	addmi r5,r0
	mov r4,r4,lsl#8
	orr r4,r4,r4,lsl#16
	str r4,[r1],#4
	subs r12,r12,#1
	bhi wavLoop

	ldmfd sp!,{r4-r6}
	ldmfd sp!,{r0,r1,lr}
	bx lr

silenceMix:
	ldmfd sp!,{r0,r1}
	mov r12,r0
	ldr r2,=0x80008000
silenceLoop:
	subs r12,r12,#1
	strpl r2,[r1],#4
	bhi silenceLoop

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
pcmWritePtr:	.long 0
pcmReadPtr:		.long 0

muteSound:
muteSoundGUI:
	.byte 0
muteSoundChip:
	.byte 0
	.space 2

soundLatch:
	.byte 0
	.space 3

	.section .bss
	.align 2
WAVBUFFER:
	.space 0x1000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
