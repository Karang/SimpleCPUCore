/*----------------------------------------------------------------
//        Test des 2 cas restants de transferts multiple        //
----------------------------------------------------------------*/
	.text
	.globl	_start 
_start:               
	/* 0x00 Reset Interrupt vector address */
	b	startup
	
	/* 0x04 Undefined Instruction Interrupt vector address */
	b	_bad

main:
    mov r1, #1
    mov r5, #2
    mov r7, #3
    mov r14, sp // save sp to store its initial value in the stack
    mov r10, sp // save sp for further comparaisons
    
    sub sp, sp, #4 // dec sp because 0x80000000 is outside memory
    
    stmed sp!, {r1, r5, r7, sp, r14} // post-decrement store
    // use r14 (lr) to load into the last spot
    
    mov r1, #0 // reset registers
    mov r5, #0
    mov r7, #0
    mov r9, sp // save sp for further comparaisons
    
    ldmed sp!, {r1, r5, r7, r8, sp} // pre-increment load
    // here the wb is overwritten by the load in sp 
    
    cmp r1, #1
    bne _bad
    
    cmp r5, #2
    bne _bad
    
    cmp r7, #3
    bne _bad
    
    cmp r8, r9
    bne _bad
    
    cmp sp, r10 // ?=0x80000000
    bne _bad
    
    b _good
    
startup:
	@ init SP
	ldr	sp, AdrStack
	
	bl main
	movs r0, r0
	beq _good
	bne _bad

	add r2, r2, r2 // nop de protection
_bad:
	add r0, r0, r0
_good:
	add r1, r1, r1
AdrStack:  .word 0x80000000
