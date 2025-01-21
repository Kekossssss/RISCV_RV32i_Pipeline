.section .start;
.globl start;



start:
	li t1, 0x10
	li t2, 0x20
	li t6, 0x1f

loop :
	addi t5,t5,1
	add t3,t1,t2
	or t4, t1, t3
	and t1, t3, t4
	bltu t5,t6,loop

lab1 :  li ra, 0xDEADBEEF
	j  lab1

.end start
