#ifdef __arm__

#include "Equates.h"
#include "TLCS900H/TLCS900H.i"
#include "ARMZ80/ARMZ80.i"
#include "K2GE/K2GE.i"

	.extern reset				;@ from bios.c

	.global machineInit
	.global loadCart
	.global emuFlags
	.global romNum
	.global cartFlags
	.global romStart
	.global isBiosLoaded
	.global ngpHeader
	.global romSpacePtr

	.global biosSpace
	.global g_BIOSBASE_COLOR
	.global g_BIOSBASE_BW
	.global ngpRAM
	.global g_romSize
	.global maxRomSize
	.global g_config
	.global g_machine
	.global g_lang
	.global g_paletteBank


	.syntax unified
	.arm

	.section .rodata
	.align 2

ROM_Space:
//	.incbin "ngproms/Bust-A-Move Pocket (U).ngc"
//	.incbin "ngproms/Cool Boarders Pocket (JE) (M2).ngc"
//	.incbin "ngproms/Dark Arms - Beast Buster 1999 (JUE) (M2).ngc"
//	.incbin "ngproms/Evolution - Eternal Dungeons (E).ngc"
//	.incbin "ngproms/Fantastic Night Dreams Cotton (E).ngc"
//	.incbin "ngproms/Fatal Fury F-Contact (JUE) (M2).ngc"
//	.incbin "ngproms/Last Blade, The - Beyond the Destiny (E).ngc"
//	.incbin "ngproms/Metal Slug - 1st Mission (JUE) (M2).ngc"
//	.incbin "ngproms/SNK Gals' Fighters (UE).ngc"
//	.incbin "ngproms/Sonic the Hedgehog - Pocket Adventure (JUE).ngc"
//biosSpace:
//	.incbin "ngproms/[BIOS] SNK Neo Geo Pocket Color (JE).ngp"

	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr r0,=romSpacePtr
//	ldr r7,=ROM_Space
//	str r7,[r0]
	ldr r7,[r0]
							;@ r7=rombase til end of loadcart
	ldr t9optbl,=tlcs900HState
	str r7,[t9optbl,#romBaseLo]
	add r0,r7,#0x200000
	str r0,[t9optbl,#romBaseHi]

	ldr r0,=biosSpace
	str r0,[t9optbl,#biosBase]
	ldr r0,=tlcs_rom_R
	str r0,[t9optbl,#readRomPtrLo]
	ldr r0,=tlcs_romH_R
	str r0,[t9optbl,#readRomPtrHi]

	bl gfxInit
//	bl ioInit
	bl soundInit
	bl z80MemInit
//	bl cpuInit

	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldr r0,=g_BIOSBASE_COLOR
	ldr r0,[r0]
	cmp r0,#0
	beq skipBiosSettings

	bl run					;@ Settings are cleared when new batteries are inserted.
	bl transferTime			;@ So set up time
	ldr r1,=fixBiosSettings	;@ And Bios settings after the first run.
	blx r1
skipBiosSettings:
	ldmfd sp!,{r4-r11,lr}
	bx lr

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=emuflags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	str r0,emuFlags

	ldr r0,g_romSize
	ldr r1,romSpacePtr
	bl ngpFlashReset
	bl hacksInit

	ldr r0,g_BIOSBASE_COLOR
	cmp r0,#0
	bne skipHWSetup

	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset
	ldr r0,ngpHeader			;@ First argument
	ldr r1,=resetBios
	blx r1
skipHWSetup:
	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
z80MemInit:
;@----------------------------------------------------------------------------
	stmfd sp!,{z80optbl}
	ldr z80optbl,=Z80OpTable
	add r0,z80optbl,#z80ReadTbl
	ldr r1,=empty_R
	ldr r2,=empty_W
	mov r3,#8
z80MemLoop0:
	str r1,[r0],#4
	str r2,[r0,#28]
	subs r3,r3,#1
	bne z80MemLoop0

	add r0,z80optbl,#z80ReadTbl
	ldr r1,=z80RamR
	str r1,[r0]					;@ 0x0000-0x1FFF
	ldr r1,=z80LatchR
	str r1,[r0,#16]				;@ 0x8000-0x9FFF

	add r0,z80optbl,#z80WriteTbl
	ldr r1,=z80RamW
	str r1,[r0]					;@ 0x0000-0x1FFF
	ldr r1,=z80SoundW
	str r1,[r0,#8]				;@ 0x4000-0x5FFF
	ldr r1,=z80LatchW
	str r1,[r0,#16]				;@ 0x8000-0x9FFF
	ldr r1,=z80IrqW
	str r1,[r0,#24]				;@ 0xC000-0xDFFF

	ldr r0,=ngpRAM+0x3000		;@ Shared Z80/TLCS-900H RAM.
	add r1,z80optbl,#z80MemTbl
	mov r2,#8
z80MemLoop1:
	str r0,[r1],#4				;@ z80MemTbl
	subs r2,r2,#1
	bne z80MemLoop1

	ldmfd sp!,{z80optbl}
	bx lr


;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ romnumber
romInfo:						;@
emuFlags:
	.byte 0						;@ emuflags      (label this so UI.C can take a peek) see equates.h for bitfields
//scaling:
	.byte 0						;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ cartflags
g_config:
	.byte 0						;@ Config, bit 7=BIOS on/off
g_machine:
	.byte 0						;@ machine
g_lang:
	.byte 1						;@ language
g_paletteBank:
	.byte 0						;@ palettebank
isBiosLoaded:
	.byte 0
	.space 2					;@ alignment.

ngpHeader:
romSpacePtr:
	.long 0
g_BIOSBASE_COLOR:
	.long 0
g_BIOSBASE_BW:
	.long 0
g_romSize:
romSize:
	.long 0
maxRomSize:
	.long 0

	.section .bss
ngpRAM:
	.space 0x4000
biosSpace:
	.space 0x10000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
