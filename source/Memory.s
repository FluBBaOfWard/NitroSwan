#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"
#include "Sphinx/Sphinx.i"

	.global empty_IO_R
	.global empty_IO_W
	.global rom_W
	.global cpuReadMem20
	.global cpuReadMem20W
	.global cpuWriteMem20
	.global cpuWriteMem20W
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
setBootRomOverlay:			;@ r0=arg0, 0=remove overlay, 1=WS, 2=WSC
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
	stmfd sp!,{lr}
	mov r3,r0
	bl cpuReadMem20
	mov r12,r0
	add r0,r3,#0x1000
	bl cpuReadMem20
	orr r0,r12,r0,lsl#8
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
cpuReadMem20:		;@ In r0=address set in top 20 bits. Out r0=val, r1=phyAdr
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
cpuReadMem20W:		;@ In r0=address set in top 20 bits. Out r0=val, r1=phyAdr
;@----------------------------------------------------------------------------
	tst r0,#0x1000
	bne cpuReadWordUnaligned
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
	stmfd sp!,{lr}
	bl cpuWriteMem20
	ldmfd sp!,{lr}
	add r0,r0,#0x1000
	mov r1,r1,lsr#8
;@----------------------------------------------------------------------------
cpuWriteMem20:		;@ r0=address set in top 20 bits
;@----------------------------------------------------------------------------
	movs r2,r0,lsr#28
	bne tstSRAM_WB
;@----------------------------------------------------------------------------
ram_WB:				;@ Write ram ($00000-$0FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-1*4]
	strb r1,[r2,r0,lsr#12]
	ldr r2,=DIRTYTILES
	strb r0,[r2,r0,lsr#17]
	bx lr
;@----------------------------------------------------------------------------
tstSRAM_WB:
;@----------------------------------------------------------------------------
	cmp r2,#1
	bne rom_W
;@----------------------------------------------------------------------------
sram_WB:			;@ Write sram ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-2*4]
	strb r1,[r2,r0,lsr#12]
	bx lr

;@----------------------------------------------------------------------------
cpuWriteMem20W:		;@ r0=address set in top 20 bits
;@----------------------------------------------------------------------------
	tst r0,#0x1000
	bne cpuWriteWordUnaligned
	movs r2,r0,lsr#28
	bne tstSRAM_WW
;@----------------------------------------------------------------------------
ram_WW:				;@ Write ram ($00000-$0FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-1*4]
	add r2,r2,r0,lsr#12
	strh r1,[r2]
	ldr r2,=DIRTYTILES
	strb r0,[r2,r0,lsr#17]
	bx lr
;@----------------------------------------------------------------------------
tstSRAM_WW:
;@----------------------------------------------------------------------------
	cmp r2,#1
	bne rom_W
;@----------------------------------------------------------------------------
sram_WW:			;@ Write sram ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-2*4]
	mov r0,r0,lsr#12
	strh r1,[r2,r0]
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
