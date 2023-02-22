#ifdef __arm__

#include "Sphinx/Sphinx.i"

	.global soundInit
	.global soundReset
	.global VblSound2
	.global setMuteSoundGUI
	.global soundUpdate

	.extern pauseEmulation

#define buffer_size (640)

#define WRITE_BUFFER_SIZE (0x800)

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
	str r0,pcmWritePtr
	str r0,pcmReadPtr
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
	stmfd sp!,{r0,r4,r5,lr}

	ldr r2,muteSound
	cmp r2,#0
	bne silenceMix

	ldr spxptr,=sphinx0
	ldrb r2,[spxptr,#wsvHWVolume]
	cmp r2,#0
	beq silenceMix
	ldr r4,pcmReadPtr
	add r5,r4,r0
	str r5,pcmReadPtr

	bl soundCopyBuff
	ldr r2,pcmWritePtr
	sub r2,r5,r2
	adds r2,r2,#buffer_size/2
	strpl r2,[spxptr,#missingSamplesCnt]

	ldmfd sp!,{r0,r4,r5,lr}
	bx lr
;@----------------------------------------------------------------------------
soundCopyBuff:
;@----------------------------------------------------------------------------
	ldr r3,=WAVBUFFER
	mov r4,r4,lsl#21
sndCopyLoop:
	subs r0,r0,#1
	ldrpl r2,[r3,r4,lsr#19]
	strpl r2,[r1],#4
	add r4,r4,#0x00200000
	bhi sndCopyLoop
	bx lr
;@----------------------------------------------------------------------------
silenceMix:
;@----------------------------------------------------------------------------
	ldr r2,=0x80008000
silenceLoop:
	subs r0,r0,#1
	strpl r2,[r1],#4
	bhi silenceLoop

	ldmfd sp!,{r0,r4,r5,lr}
	bx lr

soundUpdateMore:
	stmfd sp!,{r4,lr}
	mov r4,r0
updLoop:
	bl soundUpdate
	subs r4,r4,#2
	bhi updLoop
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
soundUpdate:			;@ Should be called at every scanline
;@----------------------------------------------------------------------------
	mov r0,#2			;@ 24kHz / (75Hz * 160 scanlines) = 2
	ldr r1,pcmWritePtr
	mov r2,r1,lsl#21	;@ Only keep 11 bits
	add r1,r1,r0
	str r1,pcmWritePtr
	ldr r1,=WAVBUFFER
	add r1,r1,r2,lsr#19
	b wsAudioMixer

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
	.space 0x2000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
