#Matthew Flancer
#maf291

.include "macros.asm"

.eqv INPUT_SIZE 3
.eqv DURATION 1000
.eqv VOLUME 100

.data
# maps from ASCII to MIDI note numbers, or -1 if invalid.
key_to_note_table: .byte
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 60 -1 -1 -1
	75 -1 61 63 -1 66 68 70 -1 73 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 55 52 51 64 -1 54 56 72 58 -1 -1 59 57 74
	76 60 65 49 67 71 53 62 50 69 48 -1 -1 -1 -1 -1

demo_notes: .byte
	67 67 64 67 69 67 64 64 62 64 62
	67 67 64 67 69 67 64 62 62 64 62 60
	60 60 64 67 72 69 69 72 69 67
	67 67 64 67 69 67 64 62 64 65 64 62 60
	-1

demo_times: .word
	250 250 250 250 250 250 500 250 750 250 750
	250 250 250 250 250 250 500 375 125 250 250 1000
	375 125 250 250 1000 375 125 250 250 1000
	250 250 250 250 250 250 500 250 125 125 250 250 1000
	0

input: .space INPUT_SIZE

current_instrument:
	.word 0

recorded_notes: .byte -1:1024
recorded_times: .word 250:1024

.text

# -----------------------------------------------

.globl main
main:

	_main_loop:
		println_str "[k]eyboard, [d]emo, [r]ecord, [p]lay, [q]uit"
		la a0, input
		li a1, INPUT_SIZE
		li v0, 8
		syscall

		lb t0, input

		beq t0, 'q', _quit
		beq t0, 'k', _case_keyboard
		beq t0, 'd', _case_demo
		beq t0, 'r', _case_record
		beq t0, 'p', _case_play

		println_str "ERROR: UNKOWN COMMAND\n"
		j _main_loop

	
	_quit:
		li v0, 10
		syscall
	_case_keyboard:
		jal keyboard
		j _main_loop
	_case_demo:
		jal demo
		j _main_loop
	_case_record:
		jal record
		j _main_loop
	_case_play:
		jal play
		j _main_loop
# -----------------------------------------------
keyboard:
	push ra

	println_str "Play notes with letters and numbers, ` to change instrument, enter to stop"

	_key_loop:
		li v0, 12
		syscall

		beq v0, '\n', _exit
		beq v0, '`', _instrument_case

		j _key_entered

		_instrument_case:
			jal change_instrument
			j _key_loop

		_key_entered:

			move a0, v0
			jal translate_note

			beq v0, -1, _key_loop			#checks if the returned value from translate_note is -1 or not 

			move a0, v0						#moves translated note into a0
			jal play_note

			j _key_loop

	_exit:

	pop ra
	jr ra

# -----------------------------------------------
demo:
	push ra 

	la t0, demo_notes
	la t1, demo_times

	move a0, t0
	move a1, t1
	jal play_song

	pop ra
	jr ra

# -----------------------------------------------
record:
	push ra 

	push s0
	push s1
	push s2

	la s0, recorded_notes
	la s1, recorded_times

	println_str "Play notes with letters and numbers, enter to stop"

	_record_loop:
		li v0, 12
		syscall

		beq v0, '\n', _exit1

		move a0, v0
		jal translate_note

		beq v0, -1, _record_loop			#checks if the returned value from translate_note is -1 or not 					

		sb v0, (s0)							
		move a0, v0							#moves translated note into a0

		jal play_note

		li v0, 30							
		syscall
		sw v0, (s1)							#moves time of the note into current address of recorded_times

		add s0, s0, 1						#moves to next addrss in recorded_notes (by 1 because byte array)
		add s1, s1, 4						#moves to next address in recorded_times(by 4 because word array)

		j _record_loop

	_exit1:

	li t0, -1
	sb t0, (s0)

	li v0 30
	syscall
	sw v0, (s1)									#loads time when enter is pressed so time of last note can be recorded 
	
	la s0, recorded_notes
	la s1, recorded_times

	_times_loop:

		lb t2,(s0) #loads t2 with the note at address s0

		beq t2, -1, _times_exit

		add s2, s1, 4							#s2 = address of recorded_times[i+1]
		lw t0, (s1)							    #t0 = recorded_times[i]
		lw t1, (s2)								#t1 = recorded_times[i+1]

		sub t0, t1, t0							#t0 = recorded_times[i+1] - recorded_times[i]

		sw t0, (s1) 							#stores correct time at address in recorded_times

		add s1, s1, 4							#increments address in times array to the next time
		add s0, s0, 1							#increments address in note array to the next note

		j _times_loop

	_times_exit:

	li t0, 0
	sw t0, (s1)

	println_str "done!"

	pop s0
	pop s1
	pop s2

	pop ra
	jr ra

# -----------------------------------------------
play:
	push ra 
	
	la t0, recorded_notes
	la t1, recorded_times

	move a0, t0
	move a1, t1
	jal play_song

	pop ra
	jr ra

# -----------------------------------------------
play_note:
	push ra

	li a1, DURATION
	lw a2, current_instrument
	li a3,VOLUME
	li v0, 31
	syscall

	pop ra
	jr ra
# -----------------------------------------------
translate_note:
	push ra

	move t0, a0

	blt, t0, 0, _false_block 				#if t0 is less than 0 
	ble, t0, 127, _true_block				#or if t0 is less than 127
	
	_false_block:
		li v0, -1							#if note is invalid load it with -1
		j _done
	_true_block:
		lb v0, key_to_note_table(t0)		#if note is in the bounds it translates it to correct note
	_done:
		
	pop ra
	jr ra
# -----------------------------------------------
change_instrument:

	push ra
	
	_instrument_loop:
	println_str "\nEnter instrument number (1..128): "
	li v0, 5
	syscall

	blt v0, 1, _instrument_loop 		  #if it is less than 1 or greater than 128 ask user for another number
	bgt v0, 128, _instrument_loop

	sub v0, v0, 1 					      #subtracts 1 from number to get correct instrument
	sw v0, current_instrument

	pop ra
	jr ra
# -----------------------------------------------
play_song:

	push ra

	push s0
	push s1

	move s0, a0
	move s1, a1

	_song_loop:

		lb t0, (s0)     #loads t0 with the note at address s0

		beq t0, -1, _song_exit    #if note is -1, leave loop

		move a0, t0
		jal play_note

		lw t1, (s1) 	#loads t1 with the time at address s1
		move a0, t1
		li v0, 32
		syscall

		add s0, s0, 1    #increments address by 1 because it is a byte array
		add s1, s1, 4	 #increments address by 4 because it is a word array

		j _song_loop

		_song_exit:


	pop s0
	pop s1

	pop ra
	jr ra
