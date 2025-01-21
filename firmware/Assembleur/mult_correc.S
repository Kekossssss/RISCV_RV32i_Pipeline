.section .start;
.globl start;



start:
	li t0, 0x8
	li t1, 0x7
	li t2, 0x0
	li t3, 0x0
	li t4, 16
	li t6, 0x1

loop :
	andi t5, t1, 0x001
	addi t2,t2,1
	NOP
	NOP
	bne t5,t6,endIf
	NOP
	NOP
	add t3,t3,t0

endIf :
	slli t0,t0,1
	srli t1,t1,1
	bltu t2,t4,loop
	NOP
	NOP

lab1 :  j  lab1
	nop

.end start
