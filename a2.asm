# Gwen Guan 260950108
# TODO: ADD OTHER COMMENTS YOU HAVE HERE AT THE TOP OF THIS FILE
# TODO: SEE LABELS FOR PROCEDURES YOU MUST IMPLEMENT AT THE BOTTOM OF THIS FILE



# Menu options
# r - read text buffer from file 
# p - print text buffer
# e - encrypt text buffer
# d - decrypt text buffer
# w - write text buffer to file
# q - quit

.data
MENU:              	.asciiz "Commands (read, print, encrypt, decrypt, write, quit):"
REQUEST_FILENAME:  	.asciiz "Enter file name:"
REQUEST_KEY: 	 	.asciiz "Enter key (a integer between -10 and 10):"
ERROR:		 		.asciiz "There was an error.\n"

FILE_NAME: 			.space 256		# maximum file name length, should not be exceeded
TEXT_BUFFER:  		.space 10000 	# pre-allocate some space for the text

##############################################################
.text
	move $s1 $0 	# Keep track of the buffer length (starts at zero)

MainLoop:	
	li $v0 4		# print string
	la $a0 MENU
	syscall
	
	li $v0 12		# read char into $v0
	syscall
	
	move $s0 $v0	# store command in $s0			
	jal PrintNewLine

	beq $s0 'r' read
	beq $s0 'p' print
	beq $s0 'w' write
	beq $s0 'e' encrypt
	beq $s0 'd' decrypt
	beq $s0 'q' exit
	b MainLoop

read:		
	jal GetFileName
	li $v0 13		# open file
	la $a0 FILE_NAME 
	li $a1 0		# flags (read)
	li $a2 0		# mode (set to zero)
	syscall
	
	move $s0 $v0
	bge $s0 0 read2	# negative means error
	li $v0 4		# print string
	la $a0 ERROR
	syscall
	
	b MainLoop
		
read2:		
	li $v0 14		# read file
	move $a0 $s0
	la $a1 TEXT_BUFFER
	li $a2 9999
	syscall
	
	move $s1 $v0	# save the input buffer length
	bge $s0 0 read3	# negative means error
	li $v0 4		# print string
	la $a0 ERROR
	syscall
	
	move $s1 $zero	# set buffer length to zero
	la $t0 TEXT_BUFFER
	sb $0 ($t0) 	# null terminate the buffer 
	b MainLoop
	
read3:		
	la $t0 TEXT_BUFFER
	add $t0 $t0 $s1
	sb $0 ($t0) 	# null terminate the buffer that was read
	li $v0 16		# close file
	move $a0 $s0
	syscall
	la $a0 TEXT_BUFFER
	jal ToUpperCase

print:		
	la $a0 TEXT_BUFFER
	jal PrintBuffer
	b MainLoop	

write:		
	jal GetFileName
	li 	$v0 13			# open file
	la 	$a0 FILE_NAME 
	li 	$a1 1			# flags (write)
	li 	$a2 0			# mode (set to zero)
	syscall
	
	move $s0 $v0
	bge $s0 0 write2	# negative means error
	li $v0 4			# print string
	la $a0 ERROR
	syscall
	b MainLoop
	
write2:	
	li $v0 15			# write file
	move $a0 $s0
	la $a1 TEXT_BUFFER
	move $a2 $s1		# set number of bytes to write
	syscall
	
	bge $v0 0 write3	# negative means error
	li $v0 4			# print string
	la $a0 ERROR
	syscall
	
	b MainLoop
	
write3:
	li $v0 16				# close file
	move $a0 $s0
	syscall
	b MainLoop

encrypt:		
	jal GetKey 				# get number of offset
	move $a1, $v0 			# copy the user input to $s1
	la 	$a0 TEXT_BUFFER 	# load the address of TEXT_BUFFER to $a0
	jal EncryptMessage 		# start encrypt the message
	la 	$a0 TEXT_BUFFER 	# load the address of TEXT_BUFFER to $a0
	jal PrintBuffer 		# print the message
	b 	MainLoop 			# jump back to the main loop

decrypt:		
	jal GetKey				# get number of offset
	move $a1, $v0			# copy the user input to $s1
	la $a0 TEXT_BUFFER 		# load the address of TEXT_BUFFER to $a0
	jal DecryptMessage 		# start decrypt the message
	la $a0 TEXT_BUFFER 		# load the address of TEXT_BUFFER to $a0
	jal PrintBuffer 		# print the message
	b MainLoop 				# jump back to the main loop

exit:	
	li $v0 10 	# exit
	syscall

###########################################################
PrintBuffer:	
	li $v0 4        # print contents of a0
	syscall
	li $v0 11		# print newline character
	li $a0 '\n'
	syscall
	jr $ra

###########################################################
PrintNewLine:	
	li $v0 11	# print char
	li $a0 '\n'
	syscall
	jr $ra

###########################################################
PrintSpace:	
	li $v0 11	# print char
	li $a0 ' '
	syscall
	jr $ra

#######################################################
GetFileName:	
	addi $sp $sp -4
	sw $ra ($sp)
	li $v0 4			# print string
	la $a0 REQUEST_FILENAME
	syscall
	
	li $v0 8			# read string
	la $a0 FILE_NAME  	# up to 256 characters into this memory
	li $a1 256
	syscall
	
	la 	$a0 FILE_NAME 
	jal TrimNewline
	lw 	 $ra ($sp)
	addi $sp $sp 4
	jr $ra

###########################################################
GetKey:		
	addi $sp $sp -4
	sw 	$ra ($sp)
	li 	$v0 4			# print string
	la 	$a0 REQUEST_KEY
	syscall
	
	li $v0 5			# read integer
	syscall
	
	lw $ra ($sp)
	addi $sp $sp 4
	jr $ra

###########################################################
# Given a null terminated text string pointer in $a0, if it contains a newline
# then the buffer will instead be terminated at the first newline
TrimNewline:	
	lb 	$t0 ($a0)
	beq $t0 '\n' TNLExit
	beq $t0 $0 TNLExit	# also exit if find null termination
	addi $a0 $a0 1
	b TrimNewline
		
TNLExit:		
	sb $0 ($a0)
	jr $ra

##################################################
# converts the provided null terminated buffer to upper case
# $a0 buffer pointer
ToUpperCase:	
	lb $t0 ($a0)
	beq $t0 $zero TUCExit
	blt $t0 'a' TUCSkip
	bgt $t0 'z' TUCSkip
	addi $t0 $t0 -32	# difference between 'A' and 'a' in ASCII
	sb $t0 ($a0)
	
TUCSkip:		
	addi $a0 $a0 1
	b ToUpperCase
	
TUCExit:		
	jr $ra





#####################################################################
#                     END OF PROVIDED CODE... 
#####################################################################




#####################################################################
# EncryptMessage
# $a0: the memory address of the message
# $a1: the key (size of the offset chosen by the user) 
# $s1: the number of characters in the message
#===================================================================#



EncryptMessage:	
	
# TODO: Put your implemententation for EncryptMessage here.
	#li $s2 0
	
Main:
	lbu $t1 0($a0)
	beq $t1 $0 Exit
	
	slti $s3 $t1 65 #$s3=1 if the ascii is smaller than 65
	bne $s3 $0 NotAlph
	slti $s3 $t1 91 #$s3=1 if the ascii is smaller than 91
	beq $s3 $0 NotAlph #branch if the ascii is greater than 90
	
	add $t2 $t1 $a1	
	slti $s4 $t2 65
	bne $s4 $0 TooSmall
	slti $s4 $t2 91
	beq $s4 $0 TooLarge
	
	j Final

	
NotAlph:
	sb $t1 0($a0)
	#addi $s2 $s2 1 #adding 1 to the counter 
	addi $a0 $a0 1 #adding 1 to $a0 to move to the next byte
	#slt $s5 $s2 $s1
	j Main
	
TooSmall:
	addi $t2 $t2 26
	#sub $t2 $t3 $a1
	j Final
	

TooLarge:
	subi $t2 $t2 26
	#add $t2 $t4 $a1
	j Final

Final:
	sb $t2 0($a0)
	#addi $s2 $s2 1 #adding 1 to the counter 
	addi $a0 $a0 1 #adding 1 to $a0 to move to the next byte
	#slt $s5 $s2 $s1
	#bne $s5 $s0 Main
	j Main
	
	
Exit:
#===================================================================#
#            DO NOT TOUCH THIS LINE
#===================================================================#
	jr $ra # DO NOT TOUCH THIS LINE

######################################################################
# DecryptMessage
# $a0: the memory address of the message
# $a1: the key (size of the offset chosen by the user) 
# $s1: the number of characters in the message
#===================================================================#



DecryptMessage:	

# TODO: Put your implemententation for DecryptMessage here.
Main1:
	lbu $t1 0($a0)
	beq $t1 $0 Exit1
	
	slti $s3 $t1 65 #$s3=1 if the ascii is smaller than 65
	bne $s3 $0 NotAlph1
	slti $s3 $t1 91 #$s3=1 if the ascii is smaller than 91
	beq $s3 $0 NotAlph1 #branch if the ascii is greater than 90
	
	sub $t2 $t1 $a1 #the decryted ascii
	slti $s4 $t2 65
	bne $s4 $0 TooSmall1
	slti $s4 $t2 91
	beq $s4 $0 TooLarge1
	j Final1

	
NotAlph1:
	sb $t1 0($a0) 
	addi $a0 $a0 1 #adding 1 to $a0 to move to the next byte
	j Main1
	
TooSmall1:
	addi $t2 $t2 26
	j Final1
	

TooLarge1:
	subi $t2 $t2 26
	
	j Final1

Final1:
	sb $t2 0($a0)
	#addi $s2 $s2 1 #adding 1 to the counter 
	addi $a0 $a0 1 #adding 1 to $a0 to move to the next byte
	#slt $s5 $s2 $s1
	#bne $s5 $s0 Main
	j Main1
	
	
Exit1:
		
			
#===================================================================#
	jr $ra # DO NOT TOUCH THIS LINE
