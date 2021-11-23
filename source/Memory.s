#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"
#include "Sphinx/WSVideo.i"

	.global empty_IO_R
	.global empty_IO_W
	.global rom_W
	.global cpuWriteByte
	.global cpuReadByte
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
	ldrmi r0,[pc,r0,lsl#2]
	strmi r0,[r1]
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
cpuWriteByte:		;@ r0=address, r1=value
	.type cpuWriteByte STT_FUNC
;@----------------------------------------------------------------------------
	ands r2,r0,#0xF0000
	bne tstSRAM_W
;@----------------------------------------------------------------------------
ram_W:				;@ Write ram ($00000-$0FFFF)
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#16
	ldr r2,=wsRAM
	strb r1,[r2,r0,lsr#16]
	mov r1,#0
	ldr r2,=DIRTYTILES
	strb r1,[r2,r0,lsr#21]
	bx lr

;@----------------------------------------------------------------------------
tstSRAM_W:
;@----------------------------------------------------------------------------
	cmp r2,#0x10000
	bne rom_W
;@----------------------------------------------------------------------------
sram_W:				;@ Write sram ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	movs r0,r0,lsl#16
	ldr r2,=wsSRAM
	strb r1,[r2,r0,lsr#16]
	bx lr
;@----------------------------------------------------------------------------
cpuReadByte:		;@ r0=address ($00000-$FFFFF)
	.type cpuReadByte STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=MEMMAPTBL_
	and r2,r0,#0xF0000
	ldr r1,[r1,r2,lsr#14]
	mov r3,r0,lsl#16
	ldrb r0,[r1,r3,lsr#16]
bootRomSwitch:
	subs r3,r3,#0xE0000000
	bxcc lr
	cmp r2,#0xF0000
	bxne lr
	ldr r1,=biosBase
	ldr r1,[r1]
	ldrb r0,[r1,r3,lsr#16]
	bx lr

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
