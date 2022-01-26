#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"
#include "Sphinx/Sphinx.i"

	.global empty_IO_R
	.global empty_IO_W
	.global rom_W
	.global cpuWriteByte
	.global cpuWriteWord
	.global cpuReadByte
	.global cpuReadWord
	.global cpu_writemem20
	.global cpu_writemem20w
	.global cpu_readmem20
	.global cpu_readmem20w
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
	subs r3,r3,#0xF0000000
	subs r3,r3,#0xE0000000

;@----------------------------------------------------------------------------

#ifdef NDS
	.section .itcm						;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
	.align 2

;@----------------------------------------------------------------------------
cpuReadWordUnaligned:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r4,lr}
	bl cpuReadByte
	mov r4,r0
	ldmfd sp!,{r0}
	add r0,r0,#1
	bl cpuReadByte
	orr r0,r4,r0,lsl#8
	ldmfd sp!,{r4,pc}
;@----------------------------------------------------------------------------
cpuReadByte:		;@ r0=address ($00000-$FFFFF)
	.type cpuReadByte STT_FUNC
cpu_readmem20:		;@ r0=address ($00000-$FFFFF)
	.type cpu_readmem20 STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#12
	add r1,v30ptr,#v30MemTbl
	and r2,r0,#0xF0000000
	ldr r1,[r1,r2,lsr#26]
	mov r3,r0,lsl#4
	ldrb r0,[r1,r3,lsr#16]
bootRomSwitch:
	subs r3,r3,#0xE0000000
	bxcc lr
	cmp r2,#0xF0000000
	bxne lr
	ldr r1,=biosBase
	ldr r1,[r1]
	ldrb r0,[r1,r3,lsr#16]
	bx lr
;@----------------------------------------------------------------------------
cpuReadWord:		;@ r0=address ($00000-$FFFFF)
	.type cpuReadWord STT_FUNC
cpu_readmem20w:		;@ r0=address ($00000-$FFFFF)
	.type cpu_readmem20w STT_FUNC
;@----------------------------------------------------------------------------
	tst r0,#0x1
	bne cpuReadWordUnaligned
	mov r0,r0,lsl#12
	add r1,v30ptr,#v30MemTbl
	and r2,r0,#0xF0000000
	ldr r1,[r1,r2,lsr#26]
	mov r3,r0,lsl#4
	add r1,r1,r3,lsr#16
	ldrh r0,[r1]
bootRomSwitch2:
	subs r3,r3,#0xE0000000
	bxcc lr
	cmp r2,#0xF0000000
	bxne lr
	ldr r1,=biosBase
	ldr r1,[r1]
	add r1,r1,r3,lsr#16
	ldrh r0,[r1]
	bx lr


;@----------------------------------------------------------------------------
cpuWriteWordUnaligned:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,lr}
	bl cpuWriteByte
	ldmfd sp!,{r0,r1,lr}
	add r0,r0,#1
	mov r1,r1,lsr#8
;@----------------------------------------------------------------------------
cpuWriteByte:		;@ r0=address, r1=value
	.type cpuWriteByte STT_FUNC
cpu_writemem20:		;@ r0=address, r1=value
	.type cpu_writemem20 STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#12
	ands r2,r0,#0xF0000000
	bne tstSRAM_WB
;@----------------------------------------------------------------------------
ram_WB:				;@ Write ram ($00000-$0FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTbl]
	strb r1,[r2,r0,lsr#12]
	ldr r2,=DIRTYTILES
	strb r0,[r2,r0,lsr#17]
	bx lr
;@----------------------------------------------------------------------------
tstSRAM_WB:
;@----------------------------------------------------------------------------
	cmp r2,#0x10000000
	bne rom_W
;@----------------------------------------------------------------------------
sram_WB:			;@ Write sram ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	movs r0,r0,lsl#4
	ldr r2,[v30ptr,#v30MemTbl+1*4]
	strb r1,[r2,r0,lsr#16]
	bx lr
;@----------------------------------------------------------------------------
cpuWriteWord:		;@ r0=address, r1=value
	.type cpuWriteWord STT_FUNC
cpu_writemem20w:	;@ r0=address, r1=value
	.type cpu_writemem20W STT_FUNC
;@----------------------------------------------------------------------------
	tst r0,#1
	bne cpuWriteWordUnaligned
	mov r0,r0,lsl#12
	ands r2,r0,#0xF0000000
	bne tstSRAM_WW
;@----------------------------------------------------------------------------
ram_WW:				;@ Write ram ($00000-$0FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTbl]
	add r2,r2,r0,lsr#12
	strh r1,[r2]
	ldr r2,=DIRTYTILES
	strb r0,[r2,r0,lsr#17]
	bx lr
;@----------------------------------------------------------------------------
tstSRAM_WW:
;@----------------------------------------------------------------------------
	cmp r2,#0x10000000
	bne rom_W
;@----------------------------------------------------------------------------
sram_WW:			;@ Write sram ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTbl+1*4]
	mov r0,r0,lsl#4
	add r2,r2,r0,lsr#16
	strh r1,[r2]
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
