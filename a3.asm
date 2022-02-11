# Gwen Guan
# 260950108
		
		.data
input_str:	.asciiz "Please enter a number: "
output_str:	.asciiz "The answer is: "
		.text
	
Main:		li $v0 4
		la $a0 input_str
		syscall
		
		li $v0 5
		syscall		#asking the user for input
		
		add $a0 $zero $v0
		jal Func	#call the first function
		add $s1 $v0 $0	#store the result of the program to $s1
		
		li $v0 4
		la $a0 output_str
		syscall
		
		li $v0 1
		add $a0 $0 $s1
		syscall 
		
		j Exit

# $v0 return value
# $a0 current n value
# $s0 intermediate result

Func:		addi $sp $sp -12
		sw $ra 8($sp)
		sw $a0 4($sp)
		sw $s0 0($sp)
		
		li $v0 1
		ble $a0 $v0 Return
		
		#(n-1)
		sub $a0 $a0 1
		jal Func
		
		#save the intermediate result
		add $s0 $v0 $0		
		
		#(n-3)
		lw $a0 4($sp)
		subi $a0 $a0 3
		jal Func
		
		add $v0 $v0 $s0
		addi $v0 $v0 1
		
Return:		lw $ra 8($sp)
		lw $a0 4($sp)
		lw $s0 0($sp)
		
		addi $sp $sp 12
		jr $ra
		
Exit:		li $v0 10
		syscall
		
				
		
		


	