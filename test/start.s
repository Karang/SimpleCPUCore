/*----------------------------------------------------------------
//           Mon premier programme                              //
----------------------------------------------------------------*/
	.text
	.globl	_start 
_start:               
	/* 0x00 Reset Interrupt vector address */
	b	startup
	
	/* 0x04 Undefined Instruction Interrupt vector address */
	b	_bad

startup:
	@ init SP
	ldr	sp, AdrStack
	
	bl		main
	movs r0, r0
	beq _good
	bne _bad

	add r2, r2, r2 // nop de protection
_bad :
	add r0, r0, r0
_good :
	add r1, r1, r1
AdrStack:  .word 0x80000000
