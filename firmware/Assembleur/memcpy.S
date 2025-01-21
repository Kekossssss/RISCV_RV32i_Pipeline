.section .start;
.globl start;



start:
	li t0, 0x0     		//Base adress for the location of the old array
	li t1, 0x100   		//Number of values in the array
	li t2, 0x1000  		//Base adress for the location of the new array
	li t3, 0xa     		//Value to add to each cell of the array

loop:
	lw t4, 0(t0)		//Load of the array cell value from memory
	add t4,t4,t3		//Adding the offset value to the cell
	sw t4,0(t2)		//Store the new array cell value in memory at the new adress
	addi t0,t0,0x4		//Incrementation of the adress for the next array cells
	addi t2,t2,0x4		//Incrementation of the adress for the next array cells
	bltu t0, t1, loop	//End of loop branch verification

lab1 :  
	li ra, 0xDEADBEEF	//End verification value for the testbench
	j  lab1

.end start
