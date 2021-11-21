// Bandai WonderSwan EEPROM emulation

#ifdef __arm__

#include "EEPROM.i"

	.global wsEepromReset
	.global wsEepromSetSize
	.global wsEepromWriteByte
	.global wsEepromSaveState
	.global wsEepromLoadState
	.global wsEepromGetStateSize

	.global wsEepromDataLowR
	.global wsEepromDataHighR
	.global wsEepromAddressLowR
	.global wsEepromAddressHighR
	.global wsEepromStatusR
	.global wsEepromDataLowW
	.global wsEepromDataHighW
	.global wsEepromAddressLowW
	.global wsEepromAddressHighW
	.global wsEepromCommandW


	.syntax unified
	.arm

#if GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
wsEepromReset:			;@ r0 = size(in bytes), r1 = *memory, r12 = eeptr
;@----------------------------------------------------------------------------
	stmfd sp!,{r0-r1,eeptr,lr}

	mov r0,eeptr
	ldr r1,=wsEepromSize/4
	bl memclr_					;@ Clear WSEeprom state

	ldmfd sp!,{r0-r1,eeptr,lr}
	str r1,[eeptr,#eepMemory]
;@----------------------------------------------------------------------------
wsEepromSetSize:		;@ r0 = size(in bytes), r12 = eeptr
;@----------------------------------------------------------------------------
	mov r1,#0x80				;@ 1kbit
	mov r2,#6
	cmp r0,#0x100				;@ 2kbit
	movpl r1,#0x100
	movpl r2,#7
	cmp r0,#0x200				;@ 4kbit
	movpl r1,#0x200
	movpl r2,#8
	cmp r0,#0x400				;@ 8kbit
	movpl r1,#0x400
	movpl r2,#9
	cmp r0,#0x800				;@ 16kbit
	movpl r1,#0x800
	movpl r2,#10
	str r1,[eeptr,#eepSize]
	sub r1,r1,#1
	str r1,[eeptr,#eepMask]
	strb r2,[eeptr,#eepAdrBits]

	bx lr
;@----------------------------------------------------------------------------
wsEepromWriteByte:		;@ r0 = adr, r1 = value, r12 = eeptr
;@----------------------------------------------------------------------------
	ldr r2,[eeptr,#eepMask]
	and r0,r2,r0
	ldr r2,[eeptr,#eepMemory]
	strb r1,[r2,r0]
	bx lr
;@----------------------------------------------------------------------------
wsEepromSaveState:		;@ In r0=destination, r1=eeptr. Out r0=state size.
	.type   wsEepromSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r4,r0					;@ Store destination
	mov r5,r1					;@ Store eeptr (r1)

	ldr r1,[r5,#eepMemory]
	ldr r2,[r5,#eepSize]
	bl memcpy

	ldr r2,[r5,#eepSize]
	add r0,r4,r2
	add r1,r5,#wsEepromState
	mov r2,#(wsEepromStateEnd-wsEepromState)
	bl memcpy

	ldmfd sp!,{r4,r5,lr}
	ldr r0,=0x800+(wsEepromStateEnd-wsEepromState)
	bx lr
;@----------------------------------------------------------------------------
wsEepromLoadState:		;@ In r0=eeptr, r1=source. Out r0=state size.
	.type   wsEepromLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,r5,lr}
	mov r5,r0					;@ Store eeptr (r0)
	mov r4,r1					;@ Store source

	ldr r0,[r5,#eepMemory]
	ldr r2,[r5,#eepSize]
	bl memcpy

	ldr r2,[r5,#eepSize]
	add r0,r5,#wsEepromState
	add r1,r4,r2
	mov r2,#(wsEepromStateEnd-wsEepromState)
	bl memcpy

	ldmfd sp!,{r4,r5,lr}
;@----------------------------------------------------------------------------
wsEepromGetStateSize:	;@ Out r0=state size.
	.type   wsEepromGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=0x800+(wsEepromStateEnd-wsEepromState)
	bx lr

	.pool
;@----------------------------------------------------------------------------
wsEepromDataLowR:		;@ r12=eeptr
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepData]
	bx lr
;@----------------------------------------------------------------------------
wsEepromDataHighR:		;@ r12=eeptr
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepData+1]
	bx lr
;@----------------------------------------------------------------------------
wsEepromAddressLowR:	;@ r12=eeptr
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepAddress]
	bx lr
;@----------------------------------------------------------------------------
wsEepromAddressHighR:	;@ r12=eeptr
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepAddress+1]
	bx lr
;@----------------------------------------------------------------------------
wsEepromStatusR:	;@ r12=eeptr
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepStatus]
	bx lr
// bit(0) = readReady;
// bit(1) = writeReady;
// bit(2) = eraseReady;
// bit(3) = resetReady;
// bit(4) = readPending;
// bit(5) = writePending;
// bit(6) = erasePending;
// bit(7) = resetPending;
;@----------------------------------------------------------------------------
wsEepromDataLowW:		;@ r0 = value, r12=eeptr
;@----------------------------------------------------------------------------
	strb r0,[eeptr,#eepData]
	bx lr
;@----------------------------------------------------------------------------
wsEepromDataHighW:		;@ r0 = value, r12=eeptr
;@----------------------------------------------------------------------------
	strb r0,[eeptr,#eepData+1]
	bx lr
;@----------------------------------------------------------------------------
wsEepromAddressLowW:	;@ r0 = value, r12=eeptr
;@----------------------------------------------------------------------------
	strb r0,[eeptr,#eepAddress]
	bx lr
;@----------------------------------------------------------------------------
wsEepromAddressHighW:	;@ r0 = value, r12=eeptr
;@----------------------------------------------------------------------------
	strb r0,[eeptr,#eepAddress+1]
	bx lr
;@----------------------------------------------------------------------------
wsEepromCommandW:		;@ r0 = value, r12=eeptr
;@----------------------------------------------------------------------------
	and r0,r0,#0xF0
	strb r0,[eeptr,#eepCommand]

	cmp r0,#0x10	;@ Read
	beq wsEepromDoRead
	cmp r0,#0x20	;@ Write
	beq wsEepromDoWrite
	cmp r0,#0x40	;@ Erase
	beq wsEepromDoErase
	cmp r0,#0x80	;@ Reset
	beq wsEepromDoReset
	bx lr			;@ Only 1 bit can be set
;@----------------------------------------------------------------------------
wsEepromDoRead:
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepAdrBits]
	ldr r1,[eeptr,#eepAddress]
	mov r2,r1,lsr r0
	and r2,r2,#0x7
	cmp r2,#0x6
	bxne lr
	ldr r2,[eeptr,#eepMask]
	and r1,r2,r1,lsl#1
	ldr r2,[eeptr,#eepMemory]
	ldrh r0,[r2,r1]
	strh r0,[eeptr,#eepData]
	mov r0,#1
	strb r0,[eeptr,#eepStatus]
	bx lr
;@----------------------------------------------------------------------------
wsEepromDoWrite:
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepAdrBits]
	ldr r1,[eeptr,#eepAddress]
	mov r2,r1,lsr r0
	and r2,r2,#0x7
	cmp r2,#0x5
	bxne lr
	ldr r2,[eeptr,#eepMask]
	and r1,r2,r1,lsl#1
	ldr r2,[eeptr,#eepMemory]
	ldrh r0,[eeptr,#eepData]
	strh r0,[r2,r1]
	mov r0,#2
	strb r0,[eeptr,#eepStatus]
	bx lr
;@----------------------------------------------------------------------------
wsEepromDoErase:
;@----------------------------------------------------------------------------
	ldrb r0,[eeptr,#eepAdrBits]
	ldr r1,[eeptr,#eepAddress]
	mov r2,r1,lsr r0
	and r2,r2,#0x7
	cmp r2,#0x7				;@ Erase?
	bxne lr
	ldr r2,[eeptr,#eepMask]
	and r1,r2,r1,lsl#1
	ldr r2,[eeptr,#eepMemory]
	mov r0,#-1
	strh r0,[r2,r1]
	mov r0,#4
	strb r0,[eeptr,#eepStatus]
	bx lr
;@----------------------------------------------------------------------------
wsEepromDoReset:
;@----------------------------------------------------------------------------
	mov r11,r11
	mov r0,#8
	strb r0,[eeptr,#eepStatus]
	bx lr

#endif // #ifdef __arm__
