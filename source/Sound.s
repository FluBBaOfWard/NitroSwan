#ifdef __arm__

#include "Sphinx/Sphinx.i"

	.extern pauseEmulation

	.global soundInit
	.global soundReset
	.global VblSound2
	.global setMuteSoundGUI
	.global setMuteSoundChip
	.global soundUpdate
	.global mix8Vol

#define WRITE_BUFFER_SIZE (0x800)
#define SHIFTVAL (21)

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
	mov r0,r0,lsl#SHIFTVAL		;@ Only keep 11 bits
	str r0,sndWritePtr
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
VblSound2:					;@ r0=length, r1=destination
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

	ldr r2,sndWritePtr
	ldr r0,pcmWritePtr
	sub r2,r2,r0,lsl#SHIFTVAL
	add r0,r0,r2,lsr#SHIFTVAL
	str r0,pcmWritePtr
	sub r0,r5,r0
	add r0,r0,#WRITE_BUFFER_SIZE/2
	ldr r2,neededExtra
	rsb r2,r2,r2,lsl#3			;@ mul 7
	add r0,r2,r0
	mov r0,r0,asr#3
	str r0,neededExtra
	bic r0,r0,#1		// 7
//	mov r0,r0,asr#1
//	bics r0,r0,#0xFF
	str r0,[spxptr,#missingSamplesCnt]
//	blne debugIOUnmappedR

	ldmfd sp!,{r0,r4,r5,lr}
	bx lr
;@----------------------------------------------------------------------------
soundCopyBuff:
;@----------------------------------------------------------------------------
	ldr r2,=WAVBUFFER			;@ Source
	mov r4,r4,lsl#SHIFTVAL
	ldrb r3,[spxptr,#wsvSoundOutput]
	tst r3,#0x80				;@ Headphones?
	beq soundCopyBuffInt
sndCopyLoop:
	subs r0,r0,#1
	ldrpl r3,[r2,r4,lsr#SHIFTVAL-2]
	add r4,r4,#1<<SHIFTVAL
	strpl r3,[r1],#4
	bhi sndCopyLoop
	bx lr
;@----------------------------------------------------------------------------
soundCopyBuffInt:			;@ Internal speaker, 8bit mono. r2=source
;@----------------------------------------------------------------------------
	stmfd sp!,{r5,lr}
	ldr lr,=0x80008000
	ldr r5,=0xFF00FF00
sndCpyIntLoop:
	subs r0,r0,#1
	ldrpl r3,[r2,r4,lsr#SHIFTVAL-2]
	add r4,r4,#1<<SHIFTVAL
	add r3,r3,r3,ror#16
	and r3,r3,r5
mix8Vol:
	eor r3,lr,r3,lsr#0			;@ Volume button shift, updated by wsaSetTotalVolume
	strpl r3,[r1],#4
	bhi sndCpyIntLoop
	ldmfd sp!,{r5,pc}
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
	ldr r1,=WAVBUFFER
	ldr r2,sndWritePtr
	mov r0,#2					;@ 24kHz / (75Hz * 160 scanlines) = 2 samples
	add r1,r1,r2,lsr#SHIFTVAL-2
	add r2,r2,r0,lsl#SHIFTVAL	;@ Only use top 11 bits
	str r2,sndWritePtr
	b wsAudioMixer

;@----------------------------------------------------------------------------
sndWritePtr:	.long 0
pcmWritePtr:	.long 0
pcmReadPtr:		.long 0
neededExtra:	.long 0

muteSound:
muteSoundGUI:
	.byte 0
muteSoundChip:
	.byte 1
	.space 2

#ifdef GBA
	.section .sbss				;@ This is EWRAM on GBA with devkitARM
#else
	.section .bss
#endif
	.align 2
WAVBUFFER:
	.space WRITE_BUFFER_SIZE*4
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
