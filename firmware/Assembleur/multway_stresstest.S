.section .start;
.globl start;



start:
	li t0,0
	li t1,0x1f
	li t2,0xABC
	li t3,0x52

loop:
	addi t0,t0,1
	or t4,t2,t3
	and t5,t2,t3
	add t6,t2,t3
	sub t4,t2,t3
	xor t5,t2,t3
	sll t6,t2,t3
	srl t4,t2,t3
	sra t5,t2,t3
	slt t6,t2,t3
	sltu t4,t2,t3
	bltu t0, t1, loop

lab1 :  
	li ra, 0xDEADBEEF
	j  lab1

.end start

