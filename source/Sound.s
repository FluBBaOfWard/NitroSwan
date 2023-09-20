#ifdef __arm__

#include "Sphinx/Sphinx.i"

	.global soundInit
	.global soundReset
	.global VblSound2
	.global setMuteSoundGUI
	.global setMuteSoundChip
	.global soundUpdate

	.extern pauseEmulation

#define WRITE_BUFFER_SIZE (0x800)
#define SHIFTVAL (21)

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
	mov r0,#WRITE_BUFFER_SIZE/2
	str r0,pcmWritePtr
	mov r0,#0
	str r0,pcmReadPtr
	strb r0,muteSoundChip
	ldr spxptr,=sphinx0
	bl wsAudioReset				;@ sound
	mov r0,#WRITE_BUFFER_SIZE
	ldr r1,=WAVBUFFER
	bl silenceMix
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type setMuteSoundGUI STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=pauseEmulation		;@ Output silence when emulation paused.
	ldrb r0,[r1]
	strb r0,muteSoundGUI
	bx lr
;@----------------------------------------------------------------------------
setMuteSoundChip:
	.type setMuteSoundChip STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#1
	strb r0,muteSoundChip
	bx lr
;@----------------------------------------------------------------------------
VblSound2:					;@ r0=length, r1=pointer
;@----------------------------------------------------------------------------
	ldr r2,muteSound
	cmp r2,#0
	bne silenceMix

	stmfd sp!,{r0,r4,r5,lr}
	ldr spxptr,=sphinx0
	ldr r4,pcmReadPtr
	add r5,r4,r0
	str r5,pcmReadPtr

	bl soundCopyBuff

	ldr r0,pcmWritePtr
	sub r0,r5,r0
	add r0,r0,#WRITE_BUFFER_SIZE/2
	ldr r2,neededExtra
	rsb r2,r2,r2,lsl#3			;@ mul 7
	add r0,r2,r0
	mov r0,r0,asr#3
	str r0,neededExtra
	bic r0,r0,#1
	str r0,[spxptr,#missingSamplesCnt]

	ldmfd sp!,{r0,r4,r5,lr}
	bx lr
;@----------------------------------------------------------------------------
soundCopyBuff:
;@----------------------------------------------------------------------------
	ldr r3,=WAVBUFFER
	mov r4,r4,lsl#21
sndCopyLoop:
	subs r0,r0,#1
	ldrpl r2,[r3,r4,lsr#SHIFTVAL-2]
	strpl r2,[r1],#4
	add r4,r4,#0x00200000
	bhi sndCopyLoop
	bx lr
;@----------------------------------------------------------------------------
silenceMix:
;@----------------------------------------------------------------------------
	mov r3,r0
	ldr r2,=0x80008000
silenceLoop:
	subs r3,r3,#1
	strpl r2,[r1],#4
	bhi silenceLoop

	bx lr

;@----------------------------------------------------------------------------
soundUpdate:				;@ r0 = samples to render
;@----------------------------------------------------------------------------
	mov r0,#2					;@ 24kHz / (75Hz * 160 scanlines) = 2 samples
	ldr r2,pcmWritePtr
	add r1,r2,r0
	str r1,pcmWritePtr
	ldr r1,=WAVBUFFER
	mov r2,r2,lsl#SHIFTVAL		;@ Only keep 11 bits
	add r1,r1,r2,lsr#SHIFTVAL-2
	b wsAudioMixer

;@----------------------------------------------------------------------------
pcmWritePtr:	.long 0
pcmReadPtr:		.long 0
neededExtra:	.long 0

muteSound:
muteSoundGUI:
	.byte 0
muteSoundChip:
	.byte 0
	.space 2

	.section .bss
	.align 2
WAVBUFFER:
	.space WRITE_BUFFER_SIZE*4
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
