#ifdef __arm__

#include "ARMV30MZ/ARMV30MZmac.h"
#include "Sphinx/Sphinx.i"

	.global empty_IO_R
	.global empty_IO_W
	.global rom_W

	.global cpuReadMem20
	.global cpuReadMem20W
	.global dmaReadMem20W
	.global v30ReadEA1
	.global v30ReadEA
	.global v30ReadStack
	.global v30ReadDsIx
	.global v30ReadSegOfs
	.global v30ReadEAW1
	.global v30ReadEAW
	.global v30ReadEAW_noAdd
	.global v30ReadSegOfsW

	.global cpuWriteMem20
	.global cpuWriteMem20W
	.global dmaWriteMem20W
	.global v30WriteEA
	.global v30WriteEsIy
	.global v30WriteSegOfs
	.global v30WriteEAW2
	.global v30WriteEAW
	.global v30PushW
	.global v30PushLastW
	.global v30WriteSegOfsW
	.global setBootRomOverlay


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
empty_IO_R:					;@ Read bad IO address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0x10
	bx lr
;@----------------------------------------------------------------------------
empty_IO_W:					;@ Write bad IO address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0x18
	bx lr
;@----------------------------------------------------------------------------
rom_W:						;@ Write ROM address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0xB0
	bx lr
;@----------------------------------------------------------------------------
setBootRomOverlay:			;@ r0=arg0, 0=remove overlay, 1=WS, 2=WSC/SC
;@----------------------------------------------------------------------------
	cmp r0,#3
	ldrmi r1,=bootRomSwitch
	ldrmi r2,=bootRomSwitch2
	adr r3,commandList
	ldrmi r0,[r3,r0,lsl#2]
	strmi r0,[r1]
	strmi r0,[r2]
commandList:
	bx lr
	subs r2,r2,#0xFF000
	subs r2,r2,#0xFE000

;@----------------------------------------------------------------------------

#ifdef NDS
	.section .itcm						;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
	.align 2

;@----------------------------------------------------------------------------
cpuReadWordUnaligned:	;@ Make sure cpuReadMem20 does not use r3 or r12!
;@----------------------------------------------------------------------------
	eatCycles 1
	stmfd sp!,{lr}
	mov r3,r0
	bl cpuReadMem20
	mov r12,r0
	add r0,r3,#0x1000
	bl cpuReadMem20
	orr r0,r12,r0,lsl#8
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
v30ReadEA1:			;@ In v30ofs=v30ptr+second byte of opcode.
;@----------------------------------------------------------------------------
	eatCycles 1
;@----------------------------------------------------------------------------
v30ReadEA:			;@ In v30ofs=v30ptr+second byte of opcode.
;@----------------------------------------------------------------------------
	adr r12,v30ReadSegOfs		;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
;@----------------------------------------------------------------------------
v30ReadDsIx:		;@
;@----------------------------------------------------------------------------
	ldrsb r4,[v30ptr,#v30DF]
	ldr v30ofs,[v30ptr,#v30RegIX]
	TestSegmentPrefix
	ldreq v30csr,[v30ptr,#v30SRegDS]
	add r0,v30ofs,r4,lsl#16
	str r0,[v30ptr,#v30RegIX]
;@----------------------------------------------------------------------------
v30ReadSegOfs:		;@ In r7=segment in top 16 bits, r6=offset in top 16 bits.
;@----------------------------------------------------------------------------
	add r0,v30csr,v30ofs,lsr#4
;@----------------------------------------------------------------------------
cpuReadMem20:		;@ In r0=address set in top 20 bits. Out r0=val, r1=phyAdr
;@ If this is updated, remember to also update V30EncodePC
;@----------------------------------------------------------------------------
	mvn r2,r0,lsr#28
	ldr r1,[v30ptr,r2,lsl#2]
	mov r2,r0,lsr#12
	ldrb r0,[r1,r0,lsr#12]!
bootRomSwitch:
	subs r2,r2,#0xFE000
	bxcc lr
	ldr r1,=biosBase
	ldr r1,[r1]
	ldrb r0,[r1,r2]!
	bx lr

;@----------------------------------------------------------------------------
v30ReadEAW1:		;@ In v30ofs=v30ptr+second byte of opcode.
;@----------------------------------------------------------------------------
	eatCycles 1
	adr r12,v30ReadSegOfsW		;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
;@----------------------------------------------------------------------------
v30ReadEAW:			;@ In r0=second byte of opcode.
;@----------------------------------------------------------------------------
	add v30ofs,v30ptr,r0,lsl#2
v30ReadEAW_noAdd:
	adr r12,v30ReadSegOfsW		;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
;@----------------------------------------------------------------------------
v30ReadStack:		;@ Read a word from the stack, r0=value on stack.
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr v30csr,[v30ptr,#v30SRegSS]
;@----------------------------------------------------------------------------
v30ReadSegOfsW:		;@ In r7=segment in top 16 bits, r6=offset in top 16 bits.
;@----------------------------------------------------------------------------
	add r0,v30csr,v30ofs,lsr#4
;@----------------------------------------------------------------------------
cpuReadMem20W:		;@ In r0=address set in top 20 bits. Out r0=val, r1=phyAdr
;@----------------------------------------------------------------------------
	tst r0,#0x1000
	bne cpuReadWordUnaligned
dmaReadMem20W:
	mvn r2,r0,lsr#28
	ldr r1,[v30ptr,r2,lsl#2]
	mov r2,r0,lsr#12
	ldrh r0,[r1,r2]!
bootRomSwitch2:
	subs r2,r2,#0xFE000
	bxcc lr
	ldr r1,=biosBase
	ldr r1,[r1]
	ldrh r0,[r1,r2]!
	bx lr

;@----------------------------------------------------------------------------
cpuWriteWordUnaligned:	;@ Make sure cpuWriteMem20 does not change r0 or r1!
;@----------------------------------------------------------------------------
	eatCycles 1
	stmfd sp!,{lr}
	bl cpuWriteMem20
	ldmfd sp!,{lr}
	add r0,r0,#0x1000
	mov r1,r1,lsr#8
	b cpuWriteMem20

;@----------------------------------------------------------------------------
v30WriteEA:				;@ In v30ofs=v30ptr+second byte of opcode.
;@----------------------------------------------------------------------------
	adr r12,v30WriteSegOfs		;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
;@----------------------------------------------------------------------------
v30WriteEsIy:		;@
;@----------------------------------------------------------------------------
	GetIyOfsESegment
	add r2,v30ofs,r4,lsl#16
	str r2,[v30ptr,#v30RegIY]
;@----------------------------------------------------------------------------
v30WriteSegOfs:		;@ In r7=segment in top 16 bits, r6=offset in top 16 bits.
;@----------------------------------------------------------------------------
	add r0,v30csr,v30ofs,lsr#4
;@----------------------------------------------------------------------------
cpuWriteMem20:		;@ r0=address set in top 20 bits, r1=value
;@----------------------------------------------------------------------------
	movs r2,r0,lsr#28
	bne tstSRAM_WB
;@----------------------------------------------------------------------------
ram_WB:				;@ Write ram ($00000-$0FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-1*4]
	strb r1,[r2,r0,lsr#12]
	add r2,r2,#0x10000			;@ Size of wsRAM, ptr to DIRTYTILES.
	strb r0,[r2,r0,lsr#17]
	bx lr
;@----------------------------------------------------------------------------
tstSRAM_WB:
;@----------------------------------------------------------------------------
	cmp r2,#1
;@----------------------------------------------------------------------------
sram_WB:			;@ Write sram ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	ldreq r2,[v30ptr,#v30MemTblInv-2*4]
	strbeq r1,[r2,r0,lsr#12]
	bxeq lr
	b rom_W

;@----------------------------------------------------------------------------
v30WriteEAW2:		;@ In v30ofs=v30ptr+second byte of opcode.
;@----------------------------------------------------------------------------
	eatCycles 2
;@----------------------------------------------------------------------------
v30WriteEAW:		;@ In v30ofs=v30ptr+second byte of opcode.
;@----------------------------------------------------------------------------
	adr r12,v30WriteSegOfsW		;@ Return reg for EA
	ldr pc,[v30ofs,#v30EATable]
;@----------------------------------------------------------------------------
v30PushW:		;@ In r1=value.
;@----------------------------------------------------------------------------
	ldr v30ofs,[v30ptr,#v30RegSP]
	ldr v30csr,[v30ptr,#v30SRegSS]
;@----------------------------------------------------------------------------
v30PushLastW:	;@ In r1=value.
;@----------------------------------------------------------------------------
	sub v30ofs,v30ofs,#0x20000
	str v30ofs,[v30ptr,#v30RegSP]
;@----------------------------------------------------------------------------
v30WriteSegOfsW:	;@ In r7=segment in top 16 bits, r6=offset in top 16 bits.
;@----------------------------------------------------------------------------
	add r0,v30csr,v30ofs,lsr#4
;@----------------------------------------------------------------------------
cpuWriteMem20W:		;@ r0=address set in top 20 bits, r1=value
;@----------------------------------------------------------------------------
	tst r0,#0x1000
	bne cpuWriteWordUnaligned
	movs r2,r0,lsr#28
	bne tstSRAM_WW
;@----------------------------------------------------------------------------
ram_WW:				;@ Write ram ($00000-$0FFFF)
dmaWriteMem20W:
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-1*4]
	add r3,r2,#0x10000			;@ Size of wsRAM, ptr to DIRTYTILES.
	add r2,r2,r0,lsr#12
	strh r1,[r2]
	strb r0,[r3,r0,lsr#17]
	bx lr
;@----------------------------------------------------------------------------
tstSRAM_WW:
;@----------------------------------------------------------------------------
	cmp r2,#1
;@----------------------------------------------------------------------------
sram_WW:			;@ Write sram ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	subeq v30cyc,v30cyc,#1*CYCLE
	ldreq r2,[v30ptr,#v30MemTblInv-2*4]
	moveq r0,r0,lsr#12
	strheq r1,[r2,r0]
	bxeq lr
	b rom_W
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
