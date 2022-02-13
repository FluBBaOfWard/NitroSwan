#ifdef __arm__

#include "ARMV30MZ/ARMV30MZmac.h"

	.global hacksInit

;@----------------------------------------------------------------------------

	.syntax unified
	.arm

	.section .text						;@ For anything else
	.align 2
;@----------------------------------------------------------------------------
hacksInit:
	.type   hacksInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}

	mov r4,#0x70
	adr r5,OriginalOpcodes
origLoop:
	mov r0,r4
	ldr r1,[r5],#4
	bl V30RedirectOpcode
	add r4,r4,#1
	cmp r4,#0x80
	bne origLoop

	ldr r0,=emuSettings
	ldr r0,[r0]					;@ Speed hacks enabled?
	tst r0,#0x20000
	beq noHacks

	ldr r4,=gGameID
	ldrb r0,[r4]
	cmp r0,#0x1A
	bpl noHacks

	adr r4,SpeedHacks
	ldrb r0,[r4,r0,lsl#1]!
	cmp r0,#0
	beq noHacks
	ldr r1,=sngJR_hack0
	bl InstallHack
	ldrb r0,[r4,#1]
	cmp r0,#0
	ldr r1,=sngJR_hack1
	blne InstallHack
noHacks:
	ldmfd sp!,{r4-r6,lr}
	bx lr

InstallHack:
	and r2,r0,#0x0F
	orr r2,r2,#0xF0
	strb r2,[r1,#0x30]			;@ Change compare value for branch distance.

	mov r0,r0,lsr#4
	adr r3,HackOpcodes
	ldr r2,[r3,r0,lsl#2]
	ldr r3,[r2]
	str r3,[r1,#0x14]
	ldr r3,[r2,#0x04]
	str r3,[r1,#0x18]
	ldr r3,[r2,#8]
	str r3,[r1,#0x1C]
	ldrb r3,[r2,#15]
	strb r3,[r1,#0x23]
	add r0,r0,#0x70
	b V30RedirectOpcode			;@ Insert new pointer to hack opcode in optable

OriginalOpcodes:
	.long i_bv, i_bnv, i_bc,  i_bnc, i_be,  i_bne, i_bnh, i_bh
	.long i_bn, i_bp,  i_bpe, i_bpo, i_blt, i_bge, i_ble, i_bgt

HackOpcodes:
	.long i_bv, i_bnv, i_bc_hack,  i_bnc_hack, i_be_hack,  i_bne, i_bnh, i_bh
	.long i_bn, i_bp,  i_bpe, i_bpo, i_blt, i_bge, i_ble, i_bgt

SpeedHacks:
	.byte 0x00,0x00	;@ #0x00
	.byte 0x4A,0x00	;@ #0x01 Crazy Climber
	.byte 0x00,0x00	;@ #0x02 Chocobo no Fushigi na Dungeon
	.byte 0x00,0x00	;@ #0x03 Armored Unit
	.byte 0x00,0x00	;@ #0x04 Anchorz Field
	.byte 0x00,0x00	;@ #0x05
	.byte 0x00,0x00	;@ #0x06
	.byte 0x29,0x00	;@ #0x07 Guilty Gear Petit
	.byte 0x00,0x00	;@ #0x08
	.byte 0x00,0x00	;@ #0x09
	.byte 0x00,0x00	;@ #0x0A
	.byte 0x00,0x00	;@ #0x0B
	.byte 0x00,0x00	;@ #0x0C
	.byte 0x00,0x00	;@ #0x0D
	.byte 0x00,0x00	;@ #0x0E
	.byte 0x00,0x00	;@ #0x0F
	.byte 0x00,0x00	;@ #0x10
	.byte 0x00,0x00	;@ #0x11 Makaimura
	.byte 0x00,0x00	;@ #0x12
	.byte 0x00,0x00	;@ #0x13
	.byte 0x00,0x00	;@ #0x14
	.byte 0x00,0x00	;@ #0x15
	.byte 0x00,0x00	;@ #0x16
	.byte 0x00,0x00	;@ #0x17
	.byte 0x00,0x00	;@ #0x18
	.byte 0x00,0x00	;@ #0x19
	.byte 0x00,0x00	;@ #0x1A Cardcaptor Sakura
noHack:
	.byte 0x00,0x00
	.align 2

;@----------------------------------------------------------------------------
i_bc_hack:				;@ 0x72
;@----------------------------------------------------------------------------
	mov r0,r0
	mov r0,r0
	tst v30f,#PSR_C
	beq bc_end
bc_end:
;@----------------------------------------------------------------------------
i_bnc_hack:				;@ 0x73
;@----------------------------------------------------------------------------
	mov r0,r0
	mov r0,r0
	tst v30f,#PSR_C
	bne bnc_end
bnc_end:
;@----------------------------------------------------------------------------
i_be_hack:				;@ 0x74
;@----------------------------------------------------------------------------
	mov r0,r0
	mov r0,r0
	tst v30f,#PSR_Z
	beq be_end
be_end:

#if GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
	.align 2
#endif
;@----------------------------------------------------------------------------
sngJR_hack0:				;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	mov r0,r0
	mov r0,r0
	tst v30f,#PSR_Z
	beq hack1End
	mov r0,r0,lsl#24
	add v30pc,v30pc,r0,asr#8
	sub v30cyc,v30cyc,#3*CYCLE
	cmp r0,#0xFA000000				;@ Speedhack 0
	andeq v30cyc,v30cyc,#CYC_MASK
hack0End:
	sub v30cyc,v30cyc,#1*CYCLE
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
sngJR_hack1:				;@
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	getNextByte
	mov r0,r0
	mov r0,r0
	tst r1,#PSR_V
	beq hack1End
	mov r0,r0,lsl#24
	add v30pc,v30pc,r0,asr#8
	sub v30cyc,v30cyc,#3*CYCLE
	cmp r0,#0xF9000000				;@ Speedhack 1
	andeq v30cyc,v30cyc,#CYC_MASK
hack1End:
	sub v30cyc,v30cyc,#1*CYCLE
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
