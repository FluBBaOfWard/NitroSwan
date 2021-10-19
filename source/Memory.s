#ifdef __arm__

#include "ARMV30MZ/ARMV30MZ.i"

	.global empty_IO_R
	.global empty_IO_W
	.global empty_R
	.global empty_W
	.global rom_W
	.global cpuWriteByte
	.global cpuReadByte


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
empty_R:					;@ Read bad address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
empty_W:					;@ Write bad address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0xBA
	bx lr
;@----------------------------------------------------------------------------
rom_W:						;@ Write ROM address (error)
;@----------------------------------------------------------------------------
	mov r11,r11					;@ No$GBA breakpoint
	mov r0,#0xB0
	bx lr
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
	movs r2,r0,lsr#16
	beq ram_W
	cmp r2,#1
	beq sram_W
	b rom_W
;@----------------------------------------------------------------------------
ram_W:				;@ Write ram ($000000-$00FFFF)
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#16
	ldr r2,=wsRAM
	strb r1,[r2,r0,lsr#16]
	mov r1,#0
	ldr r2,=DIRTYTILES
	strb r1,[r2,r0,lsr#21]
	bx lr
;@----------------------------------------------------------------------------
sram_W:				;@ Write sram ($010000-$017FFF)
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#17
	ldr r2,=wsSRAM
	strb r1,[r2,r0,lsr#17]
	bx lr
;@----------------------------------------------------------------------------
cpuReadByte:		;@ r0=address
	.type cpuReadByte STT_FUNC
;@----------------------------------------------------------------------------
	and r2,r0,#0x0F0000
	mov r0,r0,lsl#16
	ldr r1,=MEMMAPTBL_
	ldr r1,[r1,r2,lsr#14]
	ldrb r0,[r1,r0,lsr#16]
	bx lr

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
