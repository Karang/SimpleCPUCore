/*----------------------------------------------------------------
//                            LEDS                              //
----------------------------------------------------------------*/
	.text
	.globl	_start 
_start:               
	/* 0x00 Reset Interrupt vector address */
	b	setup     

	/* 0x04 Undefined Instruction Interrupt vector address */
	b	_bad             

setup:
    // r5 = AdrLeds
	ldr r5, AdrLeds
	
	// r4 = 1
    mov r4, #0
loop:
    // r4 ++
	add r4, r4, #1
	// update leds
	str r4, [r5] 
	
	// delay 2**25 closest to 25000000
	mov r3, #33554432
delay:
    subs r3, r3, #1
    bne delay
		
	// boucle infinie
	b loop          
	b _good

	add r2, r2, r2
_bad :
	add r0, r0, r0       
_good :
	add r1, r1, r1
AdrLeds:  .word 0x20000000