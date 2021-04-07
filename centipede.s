#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Muhammad Sohaib Saqib, 1005870041
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the project handout for descriptions of the milestones)
# - Milestone 1, 2 and 3
#
# Which approved additional features have been implemented?
# N/A
#
# Any additional information that the TA needs to know:
# - The brown squares represent the mushrooms
# - The pink chain is the centipede with a white head
# - The green square moving zig zag represents the flea
# - The blue square at the bottom represents the bug blaster 
# - The yellow squares shot by the blaster represent the darts
# - All keys as described in the handout are functional, along with the additional 'Q' key, which resets the game
#####################################################################

.data
	displayAddress:	.word 0x10008000

	bugBlasterLocation: .word 1007
	mushroomLocations: .word 0:25
	numMushrooms: .word 25
	fleaLocation: .word -1
	fleaIndicator: .word 3
	dartLocation: .word 990
	dartIndicator: .word -1
	
	centipedeLocation: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	centipedeDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	centipedeLives: .word 3
	turn_indicator: .word 1:10
	
	letter_e: .word 453, 454, 455, 456, 485, 517, 518, 519, 520, 549, 581, 582, 583, 584
	length_e: .word 14
	letter_r: .word  650, 651, 652, 653, 654, 686, 718, 717, 716, 715, 682, 714, 746, 778, 749, 781
	length_r: .word 16
	letter_x: .word 458, 491, 524, 557, 590, 462, 493, 555, 586
	length_x: .word 9
	letter_i: .word 464, 496, 528, 560, 592
	length_i: .word 5
	letter_t: .word 466, 467, 468, 469, 470, 500, 532, 564, 596
	length_t: .word 9
	letter_dash: .word 64,65,66
	length_dash: .word 3
	letter_s: .word 0, 1, 2, 32, 64, 65, 66, 98, 130, 129, 128
	length_s: .word 11
	letter_q: .word 5, 6, 7, 8, 37, 69, 101, 133, 40, 72, 103, 104, 135, 136, 134, 169 
	length_q: .word 16
	
	
.text 
Main:	jal delay_function	
	jal clear_screen
	jal reset_centipede		# Reset centipede to original spawn location
	jal build_mushroom_locations	# Initialize mushrooms
	jal draw_mushrooms		# Draw the mushrooms
	jal draw_centipede		# Initialize centipede
	
Loop:	jal delay_function
	jal erase_centipede
	jal collision_and_movement_check
	jal check_centi_lives
	jal draw_centipede
	
	la $a2, fleaIndicator		# Load the address of the fleaIndicator from memory
	lw $t8, 0($a2)			# Load the fleaIndicator itself in $t8
	bgt $t8, 0, Loop2		# Loop to check whether or not to draw flea
	jal generate_flea		# Initialize randomized flea
	
Loop2:	jal draw_flea
	jal check_keystroke
	jal draw_dart
	
	# Exit Loop check
	beq $v0, 4, Exit		# Branch to Exit if $v0 == 4
	j Loop	

Exit:
	jal delay_function
	jal clear_screen
	jal delay_function
	jal draw_text
	
	addi $v1, $zero, 90		# Initialize $v0 to counter 
	
key_check: 				# Loop after game exits for restart option
	jal delay_function
	jal check_keystroke
	addi $v1, $v1, -1
	bgt $v1, 0, key_check		# Branch back to key_check if $v1 > 0
	
	jal clear_screen
	li $v0, 10			# Terminate the program
	syscall


#####################################################################
#MUSHROOM FUNCTIONS

# function to build mushroomLocations
build_mushroom_locations:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, numMushrooms		# load a3 with the loop count
	addi $t5, $zero, 0 		# $t5 represents i=0
	la $a2, mushroomLocations 	# load the address of the mushroom array into $a2
	
build_loop:	
	beq $t5, $a3, build_exit 	# branch to build exit if $t5 == $a3
	# generate a random number between 1 and 30
	li $v0, 42
	li $a0, 0
	li $a1, 29			# upper bound is 29
	syscall
	addi $t0, $a0, 1 		# $t0 = random number between 1 and 30 (x value)
	
	# generate a random number between 1 and 29
	li $v0, 42 			# get ready to generate random number
	li $a0, 0
	li $a1, 28			# upper bound is 28
	syscall
	addi $t1, $a0, 1  		# $t1 = random number between 1 and 29 (y value)
	
	mul $t1, $t1, 32  		# $t1 = $t1 * 32
	add $t0, $t0, $t1 		# $t0 = $t0 + $t1, representing the current mushroom position
	sw $t0, 0($a2)    		# store back the mushroom position into $a2, the mushroomLocations array
	
	addi $a2, $a2, 4  		# increment to next location
	addi $t5, $t5, 1  		# increment $t5 by 1
	
	j build_loop	   		# jump back to loop
	
build_exit:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# function to draw mushrooms	
draw_mushrooms:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $a3, numMushrooms	 # a3 represents the loop counter
	la $a1, mushroomLocations # load the address of the mushroom array into $a1
	
draw_mushroom_loop: #iterate over the elements to draw each mushroom
	lw $t1, 0($a1)		 # load a word from the mushrooms array into $t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0xbdb76b	# $t3 stores the brown colour code

	sll $t4,$t1, 2		# $t4 is the bias of the mushroom location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the mushroom location
	sw $t3, 0($t4)		# paint the body with brown
	
	addi $a1, $a1, 4	 # increment $a1 to point to the next element in the mushroom array
	addi $a3, $a3, -1	 # decrement $a3 by 1
	
	bne $a3, $zero, draw_mushroom_loop	# branch back to draw_mushroom_loop if $a3 != 0
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#####################################################################
#FLEA FUNCTIONS

# function to randomly generate the flea
generate_flea:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#####
	la $a2, fleaLocation	# load the address of fleaLocation onto $a2
	
	# Random Number generator
	li $v0, 42
	li $a0, 0		# $a0 will hold the randomly generated number
	li $a1, 32		# upper bound is 32
	syscall
	
	add $t1, $a0, $zero	# $t1 stores the random number generated from $a0
	sw $t1, 0($a2)		# fleaLocation = $t1
	
	# paint the flee
	lw $t2, displayAddress # $t2 stores the base address for display
	li $t3, 0x32cd32	# $t3 stores the green colour code
	
	sll $t4,$t1, 2		# $t4 is the bias of the flea location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the flea location
	sw $t3, 0($t4)		# paint the flea with green
	
	# reset fleaIndicator to 3
	la $a0, fleaIndicator	# load the address of fleaIndicator from memory
	addi $t6, $zero, 3	# initialize $t6 to 3
	sw $t6, 0($a0)		# reset fleaIndicator to starting value
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


# function to draw flea
draw_flea:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#####
randomize: 				# build random number between 31 and 33
	li $v0, 42
	li $a0, 0			# $a0 will hold the randomly generated number
	li $a1, 34			# upper bound is 34
	syscall
	
	add $t1, $a0, $zero		# $t1 stores the random number generated from $a0
	blt $t1, 31, randomize		# branch back to randomize if $t1 < 31
	
	#####
	
	la $a0, fleaLocation		# load the address of fleaLocation from memory
	lw $t0, 0($a0)			# load the fleaLocation itself in $t0
	beq $t0, -1, flea_exit		# branch to flea_exit if fleaLocation == -1
	
	#####
	add $t1, $t1, $t0		# $t1 represents the random location one row below the flea
	
	lw $a2, displayAddress  	# $a2 stores the base address for display
	li $a3, 0x000000		# $a3 stores the black colour code
	
	sll $t4, $t0, 2			# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4		# $t4 is the address of the old flea location
	sll $t5, $t1, 2			# $t5 stores the bias of the new flea location
	add $t5, $a2, $t5		# $t5 is the address of the new flea location
	
flea_collision:
	li $t3, 0xffff33		# $t3 stores the colour yellow
	li $t6, 0x00bfff		# $t6 stores the colour blue
	lw $t7, 0($t5)			# $t7 stores the colour at the new flea location
	
	beq $t7, $t3, erase_flea	# branch to erase_flea if $t7 is yellow
	beq $t7, $t6, terminate	# branch to terminate game if $t7 is blue
	j proceed			# jump to proceed otherwise
	
erase_flea:
	sw $a3, 0($t4)			# paint the old location with black
	# sw $a3, 0($t5)		# paint the new location with black
	addi $t1, $zero, -1		# $t1 = 0
	sw $t1, 0($a0)			# reset fleaLocation to 0
	j flea_exit			# jump to flea_exit block

terminate:
	addi $v0, $zero, 4		# returns the value 4 as exit indicator
	addi $t1, $zero, -1		# $t1 = 0
	sw $t1, 0($a0)			# reset fleaLocation to 0
	j flea_exit			# jump to flea_exit block
		
proceed:
	li $t8, 0x32cd32		# $t8 stores the green colour code
	sw $a3, 0($t4)			# paint the old block with black
	sw $t8, 0($t5)			# paint the new block with green
	sw $t1, 0($a0)			# store the new location of flea into address of fleaLocation
	
	blt $t1, 992, flea_exit	# branch to dart_exit if $t1 < 992
	addi $t1, $zero, -1		# $t1 = 0
	sw $t1, 0($a0)			# reset fleaLocation to 0
	sw $a3, 0($t5)			# repaint the last flea position black
	
flea_exit:	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


#####################################################################
#CENTIPEDE FUNCTIONS

# main function to check for collisions and compute movement of the centipede
collision_and_movement_check:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)

centipede_slither: 		# responsible for moving the centipede
	addi $a0, $zero, 10 	# initialize a0 to the length of the centipede
	la $a1, centipedeLocation
	la $a1, 36($a1) 	# load the address of the array into $a1
	la $a2, centipedeDirection
	la $a2, 36($a2) 	# load the address of the array into $a2
	
slither_loop: 
	lw $t5, 0($a1)  	# load the value of centipedeLocation at that section
	lw $t6, 0($a2)  	# load the value of centipedeDirection at that section
	
	addi $t1, $t5, 1	# $t1 = $t5 + 1
	addi $t2, $zero, 32	# $t2 is initialized to 32
	div $t1, $t2		# divide $t1 by $t2
	mfhi $t2		# store the remainder in $t2 (mod)
	
	add $t1, $t5, $t6 	# $t1 = $t5 + $t6, represents the next position in centipede as an index
	
	li, $t3, 0xbdb76b	# store the mushroom colour in $t3
	lw $t9, displayAddress # $t9 stores the base address for display
	sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t9, $t4, $t9	# $t9 = pixel address of the next pixel
	lw $t9, 0($t9)		# store the pixel colour in $t9
	beq $t9, $t3, rotate_centipede_section # if next pixel is a mushroom, turn.
	
	bge $t2, 2, section_increment # branch to section_increment if $t2 >= 2
	
	# if the current segment does not yet encounter a collision, proceed ahead
	# else, rotate the centipede section in the appropriate direction

rotate_centipede_section: 	# this code block serves to store the new location of the rotated section
	la $t8, turn_indicator # load initial address to $t8
	sll $t1, $a0, 2 	# t1 = $a0 left shifted by 2
	add $t1, $t8, $t1  	# t1 = address of the section's respective turn indicator
	lw $t0, 0($t1) 		# load the indicator value to t0
	bnez $t0, section_increment # branch to section_increment if $t0 != 0, impling that this segment has already travelled down
	
	addi $t4, $t5, 32  	# $t4 now stores the index value of $t5 shifted down an entire row for the turning section
	blt $t4, 1024, update_rotation_section # if t4 is <= outer bound of the map, rotate upwards
	addi $t4, $t5, -32 	# $t4 now stores the index value of $t5 shifted up an entire row for the turning section
	
update_rotation_section: 	# this code block updates the new position of the rotated segment to the memory address
	la $t8, turn_indicator # load the initial address to $t8
	sll $t1, $a0, 2 	# $t1 = $a0 left shifted by 2
	add $t1, $t8, $t1  	# $t1 = address of the section's representative turn indicator
	lw $t0, 0($t1) 		# load the indicator value to $t0
	
	move $t3, $a2		# Set $t3 to $a2's contents
	lw $t2, 0($t3)
	mul $t2, $t2, -1   	# t2 = - $t2. This is in order to cause the turn in direction
	
	sw $t4, 0($a1) 		# store value of new location from $t4 to centipedeDirection
	sw $t2, 0($a2)  	# store value of new direction from $t2 to centipedeLocation
	
	addi $t0, $zero, 1 	# initialize $t0 to 1
	sw $t0, 0($t1) 		# revert the turn_indicator to 1 since it has already been decremented
	
	j slither_condition 	# we have updated location and direction for segment a3 so we can proceed to the next segment
	
	
section_increment: 		# This code block executes only if section moves normally
	la $t8, turn_indicator # load the initial address to $t8
	sll $t1, $a0, 2 	# t1 = $a0 left shifted by 2
	add $t1, $t8, $t1  	# $t1 = address of the section's representative turn indicator
	addi $t0, $zero, 0 	# initialize $t0 to 0
	sw $t0, 0($t1) 		# store 0 into respective indicator, implying it has moved
	
	move $t3, $a2   	# Set $t3 to $a2's contents
	lw $t2, 0($a2)  	# Set $t2 to the section's respective value for centipedeDirection
	move $t6, $a1   	# Set $t6 to $a1's contents
	lw $t5, 0($a1)  	# Set $t5 to the section's respective value for centipedeLocation
	
	add $t4, $t5, $t2 	# $t4 = $t5 + $t2, representing updated location in appropriate direction
	
	sw $t4, 0($t6) 		# store value of $t4 into centipedeDirection's respective inde within memory

slither_condition:
	addi $a2, $a2, -4 	# decrement $a2 to point to the next element in the array
	addi $a0, $a0, -1   	# decrement $a0 to point to next section
	addi $a1, $a1, -4	# decrement $a1 to point to the next element in the array
	bnez $a0, slither_loop	# branch back to slither_loop if $a0 != 0
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	

# function to display a static centiped	
draw_centipede:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a0, $zero, 10	 # a0 represents loop count
	addi $t6, $zero, 1	 # load t6 with the value 1
	
	la $a1, centipedeLocation # load the address of the array into $a1
	la $a2, centipedeDirection # load the address of the array into $a2

arr_loop:	#iterate over the loops elements to draw each body in the centiped
	lw $t1, 0($a1)		 # load a word from the centipedLocation array into $t1
	lw $t5, 0($a2)		 # load a word from the centipedDirection  array into $t5
	lw $t2, displayAddress  # $t2 stores the base address for display
	
	#####
	bne $a0, $t6, ELSE	# branch to ELSE if $a0 != $t6
	li $t3, 0xffffff	# t3 stores the white colour code
	j END  			# jump to END
ELSE:	li $t3, 0xff69b4	# $t3 stores the pink colour code

END:	sll $t4,$t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the old body location
	sw $t3, 0($t4)		# paint the body with given colour
	
	addi $a1, $a1, 4	 # increment $a1 to the next element in the array
	addi $a2, $a2, 4	 # increment $a2 to point to the next element in the array
	addi $a0, $a0, -1	 # decrement $a0 by 1
	bnez $a0, arr_loop	 # branch back to arr_loop if $a0 != 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# function to clear the centipede	
erase_centipede:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a0, $zero, 10	 # $a0 = 10
	addi $t6, $zero, 0	 # $t6 represents i=0
	la $a1, centipedeLocation # load the address of centipedeLocation onto $a1
	la $a2, centipedeDirection # load the address of centipedeDirection onto $a2
	
clear_loop:			 # loop to draw each centipede section
	beq $t6, $a0, clear_exit # branch to clear_exit if $t6 == $a0
	
	lw $t1, 0($a1)		 # $t1 represents the first value of $a1
	
	#####
	lw $t2, displayAddress  # $t2 stores the base address for display
	add $t3, $zero, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 is the bias of the old body location in memory (offset*4)
	add $t4, $t2, $t4	# $t4 is the address of the old body location
	sw $t3, 0($t4)		# paint the old body position with black
	
	addi $a1, $a1, 4	 # increment $a1 to point to the next element in the array
	addi $t6, $t6, 1	 # increment $t6 by 1
	
	j clear_loop		 # jump back to clear_loop
	
clear_exit:	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


# function to reset the centipede
reset_centipede:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, centipedeLives 		# load centipedeLives
	
	# else reset centipede.
	addi $t0, $zero, 3			# initialize $t0 to 3 
	sw $t0, centipedeLives 		# reset centipedeLives to starting value
	
	
	addi $t3, $zero, 0 			# $t3 = 0
	addi $t0, $zero, 1 			# $t0 = 1
	la $a1, centipedeLocation		# load address of centipedeLocation onto $a1
	la $a2, centipedeDirection		# load address of centipedeDirection onto $a2
	la $a3, turn_indicator			# load address of turn_indicator onto $a3
	
reset_loop:
	sw $t3, 0($a1) 				# reset position of the current centipede section
	sw $t0, 0($a2) 				# reset direction of current centipede section to 1
	sw $t0, 0($a3) 				# reset turn_indicator section to 1
	
	addi $t3, $t3, 1			# $t3 += 1
	addi $a1, $a1, 4			# increment to next address of $a1
	addi $a2, $a2, 4			# increment to next address of $a2
	addi $a3, $a3, 4			# increment to next address of $a3

	blt $t3, 10 reset_loop			# branch back to reset_loop if $t3 < 10
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


#####################################################################
#DART FUNCTIONS

# function to move and draw the dart
draw_dart:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a0, dartIndicator		# load the address of dartIndicator from memory
	lw $t2, 0($a0)			# load the dartIndicator itself in $t2
	
	beq $t2, -1, dart_exit		# branch to exit if $t2 == -1
	
	la $a1, dartLocation		# load the address of dartLocation from memory
	lw $t0, 0($a1)			# load the dart location itself onto $t0
	addi $t1, $t0, -32		# $t1 represents the location one row above the dart
	
	lw $a2, displayAddress  	# $t2 stores the base address for display
	li $a3, 0x000000		# $t5 stores the black colour code
	
	sll $t4, $t0, 2			# $t4 stores the bias of the old location
	add $t4, $a2, $t4		# $t4 is the address of the old dart location
	
	sll $t5, $t1, 2			# $t5 stores the bias of the new location
	add $t5, $a2, $t5		# $t5 is the address of the new dart location
	
	bge $t0, 32, dart_collision	# branch to dart_collision if $t0 >= 32
	addi $t2, $zero, -1		# $t2 = -1
	sw $t2, 0($a0)			# reset dartIndicator to -1
	sw $a3, 0($t4)			# paint the last dart position black
	j dart_exit			# jump to dart_exit
	
dart_collision:
	li $t6, 0xff69b4		# $t6 stores the colour pink
	li $t7, 0xffffff		# $t7 stores the colour white
	li $t8, 0x32cd32		# $t8 stores the colour green
	li $t9, 0xbdb76b		# $t9 stores the colour brown
	
	lw $t3, 0($t5)			# $t3 stores the colour at the new location
	beq $t3, $t6, decrement	# branch to decrement if the colour at position $t5 is pink
	beq $t3, $t7, decrement	# branch to decrement if the colour at position $t5 is white
	beq $t3, $t8, execute		# branch to execute if the colour at position $t5 is green
	beq $t3, $t9, execute		# branch to execute if the colour at position $t5 is brown
	j continue			# jump to continue otherwise
decrement:
	la $t6, centipedeLives		# load address of centipedeLives onto $t6
	lw $t7, 0($t6)			# load the value of $t6 onto $t7	
	addi $t7, $t7, -1		# decrement $t7 by 1
	sw $t7, 0($t6)			# store the value of $t7 in centipedeLives

execute:
	sw $a3, 0($t4)			# paint the old block with black
	sw $a3, 0($t5)			# paint the new block with black
	addi $t2, $zero, -1		# $t2 = -1
	sw $t2, 0($a0)			# reset dartIndicator to -1
	j dart_exit			# jump to dart_exit after execute code block


continue:	li $t3, 0xffff33	# $t3 stores the yellow colour code
	sw $a3, 0($t4)			# paint the old block with black
	sw $t3, 0($t5)			# paint the new block with yellow
	sw $t1, 0($a1)			# store the new location of dart into address of dartLocation
	
	bge $t1, 32, dart_exit		# branch to dart_exit if $t1 >= 32
	addi $v1, $zero, 0		# $v1 = 0
	sw $a3, 0($t5)			# repaint the last dart position black
	

dart_exit:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


#####################################################################
#FUNCTIONALITY METHODS

# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000 
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	li $t3, 0x00bfff	# $t3 stores the blue colour code
	lw $t2, displayAddress # $t2 stores the base address for display
	la $t1, bugBlasterLocation # $t0 stores the address for bugBlasterLocation
	lw $t0, 0($t1)		# $t1 stores the value in address for $t0
	sll $t4,$t0, 2		# $t4 = $t1 left shifted by 2 
	add $t4, $t2, $t4	# $t4 = $t4 + $t2
	sw $t3, 0($t4)		# paint the block with blue
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	     # ignore in default situation
	beq $t2, 0x73, respond_to_s # calls the function that handles the s key
	beq $t2, 0x78, respond_to_x # calls the function that handles the x key
	beq $t2, 0x6A, respond_to_j # calls the function that handles the j key
	beq $t2, 0x6B, respond_to_k # calls the function that handles the k key
	beq $t2, 0x71, respond_to_q # calls the function that handles the q key
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
# Call back function of x key	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# check whether a dart is already in play
	la $a1, dartIndicator		# load the address of the dartIndicator from memory
	lw $t7, 0($a1)			# load the value of dartIndicator onto $t7
	bne $t7, -1, shooter_exit 
	
	#####
	la $t0, bugBlasterLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)			# load the bug location itself in $t1
	la $t5, dartLocation		# load the address of dartLocation from memory
	lw $t6, 0($t5)			# load the dart location itself in $t6
	
	addi $t1, $t1, -32		# $t1 = $t1 - 32, represents the position right above the blaster
	lw $t2, displayAddress  	# $t2 stores the base address for display
	li $t3, 0xffff33		# $t3 stores the yellow colour code
	
	sll $t4,$t1, 2			# $t4 the bias of the location
	add $t4, $t2, $t4		# $t4 is the address of the new dart location
	sw $t3, 0($t4)			# paint the block with yellow
	sw $t1, 0($t5) 			# store the new location of dart into $t5 (dartLocation)
	
	la $a1, dartIndicator		# load the address of the dartIndicator from memory
	addi $t7, $zero, 1		# initialize $t7 to 1	
	sw  $t7, 0($a1)			# store the value of $t7 into $a1
	
	la $a2, fleaIndicator		# load the address of the fleaIndicator from memory
	lw $t8, 0($a2)			# load the fleaIndicator itself in $t8
	addi $t8, $t8, -1		# $t8 = $t8 - 1
	sw $t8, 0($a2)			# store the value of $t8 into $a2
	
shooter_exit:	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
# Call back function of s key	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 4	# returns the value 4 as exit indicator
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
# Call back function of r key	
respond_to_q:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	j Main
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

	
# Call back function of j key
respond_to_j:
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugBlasterLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 992, skip_movement1 # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the left
	
skip_movement1: sw $t1, 0($t0)		# save the bug location
	li $t3, 0x00bfff	# $t3 stores the blue colour code
	sll $t4,$t1, 2		# $t4 = $t1 left shifted by 2
	add $t4, $t2, $t4	# $t4 = $t4 + $t2
	sw $t3, 0($t4)		# paint the block with blue
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, bugBlasterLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 1023, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right
	
skip_movement2: sw $t1, 0($t0)		# save the bug location
	li $t3, 0x00bfff	# $t3 stores the blue colour code
	sll $t4,$t1, 2		# $t4 = $t1 left shifted by 2
	add $t4, $t2, $t4	# $t4 = $t4 + $t2
	sw $t3, 0($t4)		# paint the block with blue
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


#########################################
check_centi_lives:
# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#####
	la $a0, centipedeLives		# load address of centipedeLives onto $a0
	lw $t1, 0($a0)			# set $t1 to value of centipedeLives
	
	bgt $t1, 0, lives_else		# branch to lives_else if centipede_lives > 0
	j reset_centipede		# jump to reset_centipede
	
lives_else:
# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	

# function to clear screen
clear_screen:
# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	addi $t8, $zero, 1024	# Set $t8 to 1024
	li $a3, 0x000000	# $a3 stores the blue colour code
	lw $a2, displayAddress # $a2 stores the base address for display
	add $t1, $zero, $a2	# $t1 = $a2

screen_loop:
	sw $a3, 0($t1)			# paint the body with blue
	
	addi $t1, $t1, 4	 	# increment $t1 to point to the next element in the mushroom array
	addi $t8, $t8, -1	 	# decrement $t8 by 1
	bgt $t8, 0, screen_loop 	# branch back to screen_loop if $t8 > 0


# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
# function to display message
draw_text:
	##### draw e
	# move stack pointer a word and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#####
	la $a0, letter_e		# load the address of fleaLocation from memory
	addi $t6, $zero, -68 	# offset for position of letter
	
	la $a1, length_e
	lw $t1, 0($a1)
	
	li $a3, 0x0000ff	# $a3 stores the blue colour code
	lw $a2, displayAddress # $a2 stores the base address for display

e_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, e_loop
	
	
	##### draw x
	la $a0, letter_x		# load the address of fleaLocation from memory
	addi $t6, $zero, -68 	# offset for position of letter
	
	la $a1, length_x
	lw $t1, 0($a1)
	
x_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, x_loop


	##### draw i
	la $a0, letter_i		# load the address of fleaLocation from memory
	addi $t6, $zero, -68 	# offset for position of letter
	
	la $a1, length_i
	lw $t1, 0($a1)
	
i_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, i_loop


	##### draw t
	la $a0, letter_t		# load the address of fleaLocation from memory
	addi $t6, $zero, -68 	# offset for position of letter
	
	la $a1, length_t
	lw $t1, 0($a1)
	
t_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, t_loop


	##### draw r
	la $a0, letter_r		# load the address of fleaLocation from memory
	addi $t6, $zero, -9 	# offset for position of letter
	
	la $a1, length_r
	lw $t1, 0($a1)
	
r_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, r_loop
	

	##### draw e again
	la $a0, letter_e		# load the address of fleaLocation from memory
	addi $t6, $zero, 194 	# offset for position of letter
	
	la $a1, length_e
	lw $t1, 0($a1)
	
	li $a3, 0x0000ff	# $a3 stores the blue colour code
	lw $a2, displayAddress # $a2 stores the base address for display
	
final_e_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, final_e_loop
	
		
	##### draw dash
	la $a0, letter_dash		# load the address of fleaLocation from memory
	addi $t6, $zero, 404 	# offset for position of letter
	
	la $a1, length_dash
	lw $t1, 0($a1)
	
dash_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, dash_loop	
		

##### draw dash again
	la $a0, letter_dash		# load the address of fleaLocation from memory
	addi $t6, $zero, 652 	# offset for position of letter
	
	la $a1, length_dash
	lw $t1, 0($a1)
	
dash_loop_2:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, dash_loop_2


##### draw s
	la $a0, letter_s		# load the address of fleaLocation from memory
	addi $t6, $zero, 409 	# offset for position of letter
	
	la $a1, length_s
	lw $t1, 0($a1)
	
s_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, s_loop
	
	
##### draw q
	la $a0, letter_q		# load the address of fleaLocation from memory
	addi $t6, $zero, 651 	# offset for position of letter
	
	la $a1, length_q
	lw $t1, 0($a1)
	
q_loop:	lw $t0, 0($a0)		# load the fleaLocation itself in $t0
	add $t0, $t0, $t6	# final location to paint
	sll $t4, $t0, 2		# $t4 stores the bias of the old flea location
	add $t4, $a2, $t4	# $t4 is the address of the old flea location
	sw $a3, 0($t4)		# paint the body with blue
	
	addi $a0, $a0, 4	 # increment $a0 to point to the next element in the mushroom array
	addi $t1, $t1, -1	 # decrement $a3 by 1
	bgt $t1, 0, q_loop

	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
	
# function to induce a time delay
delay_function:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a0, $zero, 10000	# $a0 represents the delay counter value
	
time_loop: addi $a0, $a0, -1	# decrement $a0 by 1
	bgtz $a0, time_loop	# branch back to time_loop if $a0 > 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
