/*----------------------------------------------------------------
//                            PGCD                              //
----------------------------------------------------------------*/
	.text
	.globl	_start 
_start:               
	/* 0x00 Reset Interrupt vector address */
	b	startup          // ea00 0000 @00

	/* 0x04 Undefined Instruction Interrupt vector address */
	b	_bad             // ea00 0008 @04

startup:	
	// pgcd(a, b) : a=r0 b=r1
	mov r0, #12          // e3a0 000c @08
	mov r1, #8           // e3a0 1008 @0C

	// a-b == 0 ?
	subs r2, r0, r1      // e050 2001 @10
	beq _good            // 0a00 0005 @14

loop:
	// a-b
	subs r2, r0, r1      // e050 2001 @18
	// b = b-a (si a<b => (a-b)<0)
	sublt r1, r1, r0     // b041 1000 @1C
	// a = a-b (si a>b => (a-b)>0) 
	subgt r0, r0, r1     // c040 0001 @20
		
	// a-b != 0 ?
	bne loop             // 1aff fffb @24
	b _good              // ea00 0000 @28

	add r2, r2, r2
_bad :
	add r0, r0, r0       //           @2C
_good :
	add r1, r1, r1       //           @30
