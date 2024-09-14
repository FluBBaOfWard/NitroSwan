//
//  FlashMemory.s
//  Bandai WonderSwan WonderWitch flash memory emulation for ARM32.
//
//  Created by Fredrik Ahlström on 2024-08-14.
//  Copyright © 2024 Fredrik Ahlström. All rights reserved.
//

#ifdef __arm__

#include "ARMV30MZ/ARMV30MZmac.h"
#include "Sphinx/Sphinx.i"


// Flash_commands
	.equ CMD_READ, 0xF0          // xxxx F0 or AAA AA, 555 55, AAA F0
	.equ CMD_ERASE, 0x80         // AAA AA, 555 55, AAA 80
	.equ CMD_CHIP_ERASE, 0x10    // AAA AA, 555 55, AAA 80, AAA AA, 555 55, AAA 10
	.equ CMD_SECTOR_ERASE, 0x30  // AAA AA, 555 55, AAA 80, AAA AA, 555 55, sector_address 30
	.equ CMD_FAST_MODE, 0x20     // AAA AA, 555 55, AAA 20
	.equ CMD_PROGRAM, 0xA0       // AAA AA, 555 55, AAA A0, adr data
	// In fast mode              // xxx A0, adr data
	.equ CMD_AUTOSELECT, 0x90    // AAA AA, 555 55, AAA 90, read from block_address?

/** Number of blocks on a chip */
#define BLOCK_COUNT (14)

	.global flashMemInit
	.global flashMemReset
	.global flashReadMem20
	.global flashReadMem20W

	.global flashWriteMem20
	.global flashWriteMem20W

	.global flashMemChanged

	.syntax unified
	.arm

#ifdef NDS
	.section .itcm						;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#endif
	.align 2

;@----------------------------------------------------------------------------
flashMemInit:			;@ r0=flashMemAdr
;@----------------------------------------------------------------------------
	str r0,flashMemory
;@----------------------------------------------------------------------------
flashMemReset:
;@----------------------------------------------------------------------------
	mov r0,#CMD_READ
	strb r0,currentCommand
	mov r0,#0
	b setFlashRead
;@----------------------------------------------------------------------------
flashReadMem20:			;@ In r0=address set in top 20 bits. Out r0=val, r1=phyAdr
;@----------------------------------------------------------------------------
	ldrb r1,currentCommand
	cmp r1,#CMD_READ
	bne doFlashRead
doMemRead:
	mvn r2,r0,lsr#28
	ldr r1,[v30ptr,r2,lsl#2]
	mov r2,r0,lsr#12
	ldrb r0,[r1,r0,lsr#12]!
	b bootRomSwitchB

doFlashRead:
	movs r2,r0,lsr#28
	beq doMemRead
	cmp r2,#1
	bne doMemRead

	cmp r1,#CMD_AUTOSELECT
	beq flashReadSignature
	cmp r1,#CMD_FAST_MODE
	beq flashReadStatus
	cmp r1,#CMD_SECTOR_ERASE
	cmpne r1,#CMD_PROGRAM
	beq flashReadStatusSetRead
	mov r0,#0
	bx lr

flashReadSignature:
	ands r2,r0,#0xE
	moveq r0,#0x04			;@ Manufacturer code: Fujitsu
	bxeq lr
	cmp r2,#0x4
	movmi r0,#0x0C			;@ Device code: MBM29DL400TC
	bxmi lr
	moveq r0,#0x00			;@ Protection: 0=unprotected, 1=protected.
	bxeq lr
	mov r0,#0x00
	bx lr
flashReadStatusSetRead:
	mov r1,#CMD_READ
	strb r1,currentCommand
	mov r0,#0
	strb r0,currentWriteCycle
	stmfd sp!,{lr}
	bl setFlashRead
	ldmfd sp!,{lr}
flashReadStatus:
	mov r0,#0x80
	bx lr
;@----------------------------------------------------------------------------
flashReadMem20W:		;@ In r0=address set in top 20 bits. Out r0=val, r1=phyAdr
;@----------------------------------------------------------------------------
	ldrb r1,currentCommand
	cmp r1,#CMD_READ
	bne doFlashReadW
doMemReadW:
	mvn r2,r0,lsr#28
	ldr r1,[v30ptr,r2,lsl#2]
	mov r2,r0,lsr#12
	ldrh r0,[r1,r2]!
	b bootRomSwitchW
doFlashReadW:
	movs r2,r0,lsr#28
	beq doMemReadW
	cmp r2,#1
	bne doMemReadW
	b doFlashReadW
;@----------------------------------------------------------------------------
flashWriteMem20:		;@ r0=address set in top 20 bits, r1=value
;@----------------------------------------------------------------------------
	mov r2,r0,lsr#28
	cmp r2,#1
	bxne lr
;@----------------------------------------------------------------------------
flashWriteByte:			;@ Write flash ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}
	and r1,r1,#0xFF
	bic r4,r0,#0xFF000000
	ldrb r2,currentWriteCycle
	cmp r2,#0x09
	ldrmi pc,[pc,r2,lsl#2]
	b flashCycRestart
	.long flashProg1
	.long flashProg2
	.long flashCommand
	.long flashProg1
	.long flashProg2
	.long flashCommand2
	.long flashFastWrite1
	.long flashFastWrite2
	.long flashSlowWrite
	.long flashErase

flashProg1:					;@ F_READ
	cmp r1,#CMD_READ
	beq flashSetRead
	ldr r3,=0xAAA000
	cmp r4,r3
	cmpeq r1,#0xAA
	addeq r2,r2,#1
	beq flashCycEnd

	mov r11,r11
	b flashCycRestart

flashProg2:					;@ F_PROG
	ldr r3,=0x555000
	cmp r4,r3
	cmpeq r1,#0x55
	addeq r2,r2,#1
	beq flashCycEnd

	mov r11,r11
	b flashCycRestart

flashCommand:				;@ F_COMMAND
	ldr r3,=0xAAA000
	cmp r4,r3
	bne flashSetReadUnknown	;@ Or just end?
	strb r1,currentCommand

	cmp r1,#CMD_READ
	beq flashSetRead

	stmfd sp!,{r0-r3,lr}
	mov r0,#1
	bl setFlashRead
	ldmfd sp!,{r0-r3,lr}

	cmp r1,#CMD_FAST_MODE	;@ Fast write mode
	moveq r2,#6
	beq flashCycEnd

	cmp r1,#CMD_AUTOSELECT
	beq flashCycRestart

	cmp r1,#CMD_ERASE
//	cmpne r1,#CMD_PROTECT
	addeq r2,r2,#1
	beq flashCycEnd

	cmp r1,#CMD_PROGRAM		;@ Slow write mode
	moveq r2,#8
	beq flashCycEnd

	mov r11,r11
	b flashCycRestart

flashCommand2:				;@ F_COMMAND2
	ldrb r2,currentCommand
	strb r1,currentCommand
	cmp r2,#CMD_ERASE
	beq flashErase
//	cmp r2,#CMD_PROTECT
//	beq flashProtect
	b flashSetReadUnknown

flashErase:
	cmp r1,#CMD_SECTOR_ERASE
	bne flashEraseChip
flashEraseSector:
//	mov r4,r0
//	mov r0,r4
//	bl checkProtectFromAdr
//	tst r0,#2
//	beq flashSetRead
//	mov r0,r4
//	bl markBlockModifiedFromAddress
//	bl getBlockInfoFromAddress
//	ldr r2,flashMemory
//	add r0,r0,r2
	ldr r0,[v30ptr,#v30MemTblInv-2*4]
	add r0,r0,#0x10000
	mov r2,#0x10000				;@ Length
	mov r1,#-1
	strb r1,flashMemChanged
	bl memset
	mov r2,#9					;@ You can chain several Sector Erase commands.
	b flashCycEnd

;@----------------------------------------------------------------------------
flashEraseChip:
	cmp r1,#CMD_CHIP_ERASE
	ldreq r3,=0xAAA000
	cmpeq r4,r3
	bne flashSetReadUnknown		;@ Or just end?
	strb r1,flashMemChanged
	mov r11,r11					;@ Erase chip here
	b flashCycEnd

;@----------------------------------------------------------------------------
flashFastWrite1:
;@----------------------------------------------------------------------------
	cmp r1,#CMD_PROGRAM
	addeq r2,r2,#1
	beq flashCycEnd
	cmp r1,#CMD_AUTOSELECT		;@ Leave fast mode?
	strbeq r1,currentCommand
	beq flashCycRestart
	b flashSetReadUnknown
;@----------------------------------------------------------------------------
flashFastWrite2:
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-2*4]
	ldrb r3,[r2,r0,lsr#12]
	and r3,r3,r1
	strb r3,[r2,r0,lsr#12]
	mov r2,#6
	strb r2,flashMemChanged
	b flashCycEnd
;@----------------------------------------------------------------------------
flashSlowWrite:
;@----------------------------------------------------------------------------
	ldr r2,[v30ptr,#v30MemTblInv-2*4]
	ldrb r3,[r2,r0,lsr#12]
	and r3,r3,r1
	strb r3,[r2,r0,lsr#12]
	mov r1,#1
	strb r1,flashMemChanged
	b flashSetRead

flashSetReadUnknown:
	mov r11,r11
flashSetRead:
	mov r0,#0
	bl setFlashRead
	mov r1,#CMD_READ
	strb r1,currentCommand
flashCycRestart:
	mov r2,#0
flashCycEnd:
	strb r2,currentWriteCycle
	ldmfd sp!,{r4-r5,lr}
	bx lr
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
flashWriteMem20W:		;@ r0=address set in top 20 bits, r1=value
;@----------------------------------------------------------------------------
	mov r11,r11
	mov r2,r0,lsr#28
	cmp r2,#1
	bxne lr
;@----------------------------------------------------------------------------
flashWriteWord:			;@ Write flash ($10000-$1FFFF)
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
flashMemory:
	.long 0
flashSize:
	.long 0
flashSizeMask:
	.byte 0
flashSizeId:
	.byte 0
lastBlock:
	.byte 0
currentWriteCycle:
	.byte 0
currentCommand:
	.byte CMD_READ
flashMemChanged:
	.byte 0
	.space 2

	.end
#endif // #ifdef __arm__
