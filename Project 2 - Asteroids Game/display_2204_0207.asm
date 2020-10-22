# Keypad and LED Display Simulator driver/API file.
# All the public functions in this file are marked .globl.
# DO NOT .include THIS FILE.
# Instead, turn on "settings > assemble all files in directory".

.include "constants.asm"
.include "macros.asm"

.data
# each character is a 5x5 pixel block, stored row-by-row.
# have a look at the comments on the right to see what each character is.
pat_bang:   .byte 0 0 7 0 0  0 0 7 0 0  0 0 7 0 0  0 0 0 0 0  0 0 7 0 0 # !
pat_quote:  .byte 0 7 0 7 0  0 7 0 7 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0 # "
pat_pound:  .byte 0 7 0 7 0  7 7 7 7 7  0 7 0 7 0  7 7 7 7 7  0 7 0 7 0 # #
pat_dollar: .byte 0 7 7 7 0  7 0 7 0 0  0 7 7 7 0  0 0 7 0 7  0 7 7 7 0 # $
pat_percent:.byte 7 0 0 0 7  0 0 0 7 0  0 0 7 0 0  0 7 0 0 0  7 0 0 0 7 # %
pat_and:    .byte 0 7 0 0 0  7 0 7 0 0  0 7 0 0 0  7 0 7 0 7  0 7 0 7 0 # &
pat_apos:   .byte 0 0 7 0 0  0 0 7 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0 # '
pat_lpar:   .byte 0 0 0 7 0  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0  0 0 0 7 0 # (
pat_rpar:   .byte 0 7 0 0 0  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0  0 7 0 0 0 # )
pat_star:   .byte 0 0 7 0 0  7 0 7 0 7  0 7 7 7 0  0 7 0 7 0  7 0 0 0 7 # *
pat_plus:   .byte 0 0 0 0 0  0 0 7 0 0  0 7 7 7 0  0 0 7 0 0  0 0 0 0 0 # +
pat_comma:  .byte 0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 7 0 0 0  7 0 0 0 0 # ,
pat_dash:   .byte 0 0 0 0 0  0 0 0 0 0  0 7 7 7 0  0 0 0 0 0  0 0 0 0 0 # -
pat_dot:    .byte 0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  7 0 0 0 0 # .
pat_fsl:    .byte 0 0 0 0 7  0 0 0 7 0  0 0 7 0 0  0 7 0 0 0  7 0 0 0 0 # /
pat_colon:  .byte 0 0 0 0 0  0 7 0 0 0  0 0 0 0 0  0 7 0 0 0  0 0 0 0 0 # :
pat_semi:   .byte 0 0 0 0 0  0 7 0 0 0  0 0 0 0 0  0 7 0 0 0  7 0 0 0 0 # ;
pat_lt:     .byte 0 0 0 7 7  0 7 7 0 0  7 0 0 0 0  0 7 7 0 0  0 0 0 7 7 # <
pat_eq:     .byte 0 0 0 0 0  0 7 7 7 0  0 0 0 0 0  0 7 7 7 0  0 0 0 0 0 # =
pat_gt:     .byte 7 7 0 0 0  0 0 7 7 0  0 0 0 0 7  0 0 7 7 0  7 7 0 0 0 # >
pat_ques:   .byte 0 7 7 7 0  7 0 0 0 7  0 0 0 7 0  0 0 0 0 0  0 0 0 7 0 # ?
pat_lsq:    .byte 0 7 7 7 0  0 7 0 0 0  0 7 0 0 0  0 7 0 0 0  0 7 7 7 0 # [
pat_bsl:    .byte 7 0 0 0 0  0 7 0 0 0  0 0 7 0 0  0 0 0 7 0  0 0 0 0 7 # \
pat_rsq:    .byte 0 7 7 7 0  0 0 0 7 0  0 0 0 7 0  0 0 0 7 0  0 7 7 7 0 # ]
pat_caret:  .byte 0 0 7 0 0  0 7 0 7 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0 # ^
pat_under:  .byte 0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  7 7 7 7 7 # _
pat_lbra:   .byte 0 0 7 7 0  0 0 7 0 0  0 7 0 0 0  0 0 7 0 0  0 0 7 7 0 # {
pat_or:     .byte 0 0 7 0 0  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0 # |
pat_rbra:   .byte 0 7 7 0 0  0 0 7 0 0  0 0 0 7 0  0 0 7 0 0  0 7 7 0 0 # }
pat_tilde:  .byte 0 7 0 7 0  7 0 7 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 0 # ~
pat_at:     .byte 0 7 7 7 0  7 0 0 0 7  7 0 7 7 7  7 0 0 0 0  0 7 7 7 0 # @
pat_back:   .byte 0 7 0 0 0  0 0 7 0 0  0 0 0 7 0  0 0 0 0 0  0 0 0 0 0 # `
pat_A:      .byte 0 7 7 7 0  7 0 0 0 7  7 7 7 7 7  7 0 0 0 7  7 0 0 0 7
pat_B:      .byte 7 7 7 7 0  7 0 0 0 7  7 7 7 7 0  7 0 0 0 7  7 7 7 7 0
pat_C:      .byte 0 7 7 7 0  7 0 0 0 0  7 0 0 0 0  7 0 0 0 0  0 7 7 7 0
pat_D:      .byte 7 7 7 7 0  7 0 0 0 7  7 0 0 0 7  7 0 0 0 7  7 7 7 7 0
pat_E:      .byte 7 7 7 7 7  7 0 0 0 0  7 7 7 0 0  7 0 0 0 0  7 7 7 7 7
pat_F:      .byte 7 7 7 7 7  7 0 0 0 0  7 7 7 0 0  7 0 0 0 0  7 0 0 0 0
pat_G:      .byte 0 7 7 7 0  7 0 0 0 0  7 0 0 7 7  7 0 0 0 7  0 7 7 7 0
pat_H:      .byte 7 0 0 0 7  7 0 0 0 7  7 7 7 7 7  7 0 0 0 7  7 0 0 0 7
pat_I:      .byte 0 7 7 7 0  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0  0 7 7 7 0
pat_J:      .byte 0 7 7 7 0  0 0 7 0 0  0 0 7 0 0  7 0 7 0 0  0 7 0 0 0
pat_K:      .byte 7 0 0 7 0  7 0 7 0 0  7 7 0 0 0  7 0 7 0 0  7 0 0 7 0
pat_L:      .byte 7 0 0 0 0  7 0 0 0 0  7 0 0 0 0  7 0 0 0 0  7 7 7 7 7
pat_M:      .byte 7 0 0 0 7  7 7 0 7 7  7 0 7 0 7  7 0 0 0 7  7 0 0 0 7
pat_N:      .byte 7 0 0 0 7  7 7 0 0 7  7 0 7 0 7  7 0 0 7 7  7 0 0 0 7
pat_O:      .byte 0 7 7 7 0  7 0 0 0 7  7 0 0 0 7  7 0 0 0 7  0 7 7 7 0
pat_P:      .byte 7 7 7 7 0  7 0 0 0 7  7 7 7 7 7  7 0 0 0 0  7 0 0 0 0
pat_Q:      .byte 0 7 7 7 0  7 0 0 0 7  7 0 7 0 7  7 0 0 7 7  0 7 7 7 7
pat_R:      .byte 7 7 7 7 0  7 0 0 0 7  7 7 7 7 7  7 0 0 7 0  7 0 0 0 7
pat_S:      .byte 7 7 7 7 7  7 0 0 0 0  7 7 7 7 7  0 0 0 0 7  7 7 7 7 7
pat_T:      .byte 7 7 7 7 7  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0
pat_U:      .byte 7 0 0 0 7  7 0 0 0 7  7 0 0 0 7  7 0 0 0 7  0 7 7 7 0
pat_V:      .byte 7 0 0 0 7  7 0 0 0 7  0 7 0 7 0  0 7 0 7 0  0 0 7 0 0
pat_W:      .byte 7 0 0 0 7  7 0 0 0 7  7 0 7 0 7  7 7 0 7 7  7 0 0 0 7
pat_X:      .byte 7 0 0 0 7  0 7 0 7 0  0 0 7 0 0  0 7 0 7 0  7 0 0 0 7
pat_Y:      .byte 7 0 0 0 7  0 7 0 7 0  0 0 7 0 0  0 0 7 0 0  0 0 7 0 0
pat_Z:      .byte 7 7 7 7 7  0 0 0 7 0  0 0 7 0 0  0 7 0 0 0  7 7 7 7 7
pat_0:      .byte 0 7 7 7 0  7 0 0 7 7  7 0 7 0 7  7 7 0 0 7  0 7 7 7 0
pat_1:      .byte 0 0 7 0 0  0 7 7 0 0  0 0 7 0 0  0 0 7 0 0  0 7 7 7 0
pat_2:      .byte 7 7 7 7 7  0 0 0 0 7  7 7 7 7 7  7 0 0 0 0  7 7 7 7 7
pat_3:      .byte 7 7 7 7 0  0 0 0 0 7  0 0 7 7 0  0 0 0 0 7  7 7 7 7 0
pat_4:      .byte 7 0 0 0 7  7 0 0 0 7  7 7 7 7 7  0 0 0 0 7  0 0 0 0 7
pat_5:      .byte 7 7 7 7 7  7 0 0 0 0  7 7 7 7 0  0 0 0 0 7  7 7 7 7 0
pat_6:      .byte 0 7 7 7 0  7 0 0 0 0  7 7 7 7 0  7 0 0 0 7  0 7 7 7 0
pat_7:      .byte 7 7 7 7 7  0 0 0 0 7  0 0 0 7 0  0 0 7 0 0  0 7 0 0 0
pat_8:      .byte 0 7 7 7 0  7 0 0 0 7  0 7 7 7 0  7 0 0 0 7  0 7 7 7 0
pat_9:      .byte 0 7 7 7 0  7 0 0 0 7  0 7 7 7 7  0 0 0 0 7  0 7 7 7 0

# start at ASCII 32 since anything below that is unprintable
# a 0 means NULL i.e. unprintable character
ASCII_patterns: .word
	0        pat_bang pat_quote pat_pound pat_dollar pat_percent pat_and   pat_apos
	pat_lpar pat_rpar pat_star  pat_plus  pat_comma  pat_dash    pat_dot   pat_fsl
# overlapping arrays!
Digit_patterns:  .word
	pat_0    pat_1    pat_2     pat_3     pat_4      pat_5       pat_6     pat_7
	pat_8    pat_9    pat_colon pat_semi  pat_lt     pat_eq      pat_gt    pat_ques
	pat_at
Letter_patterns: .word
	pat_A    pat_B    pat_C     pat_D     pat_E      pat_F       pat_G
	pat_H    pat_I    pat_J     pat_K     pat_L      pat_M       pat_N     pat_O
	pat_P    pat_Q    pat_R     pat_S     pat_T      pat_U       pat_V     pat_W
	pat_X    pat_Y    pat_Z     pat_lsq   pat_bsl    pat_rsq     pat_caret pat_under
	pat_back pat_A    pat_B     pat_C     pat_D      pat_E       pat_F     pat_G
	pat_H    pat_I    pat_J     pat_K     pat_L      pat_M       pat_N     pat_O
	pat_P    pat_Q    pat_R     pat_S     pat_T      pat_U       pat_V     pat_W
	pat_X    pat_Y    pat_Z     pat_lbra  pat_or     pat_rbra    pat_tilde 0

.globl frame_counter
frame_counter:    .word 0
last_frame_time:  .word 0

.text
# -------------------------------------------------------------------------------------------------
# returns a bitwise OR of the key constants, indicating which keys are being held down.
.globl input_get_keys
input_get_keys:
	lw       v0, DISPLAY_KEYS
	jr       ra

# -------------------------------------------------------------------------------------------------
# call once per main loop to keep the game running at a given FPS.
# also increments frame_counter once per call.
.globl wait_for_next_frame
wait_for_next_frame:
enter s0
	lw s0, last_frame_time
	_wait_next_frame_loop:
		# while (sys_time() - last_frame_time) < MS_PER_FRAME {}
		syscall_time
		sub  t1, v0, s0
	bltu t1, MS_PER_FRAME, _wait_next_frame_loop

	# save the time
	sw v0, last_frame_time

	# frame_counter++
	lw  t0, frame_counter
	inc t0
	sw  t0, frame_counter
leave s0

# -------------------------------------------------------------------------------------------------
# copies the color data from display RAM onto the screen.
.globl display_update
display_update:
	sw zero, DISPLAY_CTRL
	jr ra

# -------------------------------------------------------------------------------------------------
# copies the color data from display RAM onto the screen, and then clears display RAM.
# does not clear the display, only the RAM so you can draw a new frame from scratch!
.globl display_update_and_clear
display_update_and_clear:
	li t0, 1
	sw t0, DISPLAY_CTRL
	jr ra

# -------------------------------------------------------------------------------------------------
# sets 1 pixel to a given color.
# (0, 0) is in the top LEFT, and Y increases DOWNWARDS!
# arguments:
#	a0 = x
#	a1 = y
#	a2 = color (use one of the constants above)
.globl display_set_pixel
display_set_pixel:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	add t0, t0, DISPLAY_BASE
	sb  a2, (t0)
	jr  ra

# -------------------------------------------------------------------------------------------------
# draws a horizontal line starting at (x, y) and going to (x + width - 1, y).
# (0, 0) is in the top LEFT of the screen.
# arguments:
#	a0 = x
#	a1 = y
#	a2 = width
#	a3 = color (use one of the constants above)
.globl display_draw_hline
display_draw_hline:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	add t0, t0, DISPLAY_BASE

	_display_draw_hline_loop:
		sb   a3, (t0)
		inc  t0
	dec  a2
	bnez a2, _display_draw_hline_loop

	jr       ra

# -------------------------------------------------------------------------------------------------
# draws a vertical line starting at (x, y) and going to (x, y + height - 1).
# (0, 0) is in the top LEFT, and Y increases DOWNWARDS!
# arguments:
#	a0 = x
#	a1 = y
#	a2 = height
#	a3 = color (use one of the constants above)
.globl display_draw_vline
display_draw_vline:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	add t0, t0, DISPLAY_BASE

	_display_draw_vline_loop:
		sb  a3, (t0)
		add t0, t0, DISPLAY_W
	dec  a2
	bnez a2, _display_draw_vline_loop

	jr       ra

# -------------------------------------------------------------------------------------------------
# fills a rectangle of pixels with a given color.
# there are FIVE arguments, and I was naughty and used 'v1' as a "fifth argument register."
# this is technically bad practice. sue me.
# arguments:
#	a0 = top-left corner x
#	a1 = top-left corner y
#	a2 = width
#	a3 = height
#	v1 = color (use one of the constants above)
.globl display_fill_rect
display_fill_rect:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	# turn w/h into x2/y2
	add a2, a2, a0
	add a3, a3, a1

	# turn y1/y2 into addresses
	li  t0, DISPLAY_BASE
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	move t0, a1
	_display_fill_rect_loop_y:
		move t1, t0
		move t2, a0
		_display_fill_rect_loop_x:
			sb   v1, (t1)
			inc t1
		inc t2
		blt t2, a2, _display_fill_rect_loop_x
	addi t0, t0, DISPLAY_W
	blt  t0, a3, _display_fill_rect_loop_y

	jr       ra

# -------------------------------------------------------------------------------------------------
# exactly the same as display_fill_rect, but works faster for rectangles whose width and X coord
# are a multiple of 4.
# IF X IS NOT A MULTIPLE OF 4, IT WILL CRASH.
# IF WIDTH IS NOT A MULTIPLE OF 4, IT WILL DO WEIRD THINGS.
# arguments:
#	same as display_fill_rect.
.globl display_fill_rect_fast
display_fill_rect_fast:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	# duplicate color across v1
	and v1, v1, 0xFF
	mul v1, v1, 0x01010101
	add a2, a2, a0 # a2 = x2
	add a3, a3, a1 # a3 = y2

	# t0 = display base address
	li t0, DISPLAY_BASE

	# a1 = start address
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0

	# a3 = end address
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	# t0 = current row's start address
	move t0, a1
	_display_fill_rect_fast_loop_y:
		move t1, t0 # t1 = current address
		move t2, a0 # t2 = current x
		_display_fill_rect_fast_loop_x:
			sw   v1, (t1)
			addi t1, t1, 4
		addi t2, t2, 4
		blt  t2, a2, _display_fill_rect_fast_loop_x
	addi t0, t0, DISPLAY_W
	blt  t0, a3, _display_fill_rect_fast_loop_y

	jr       ra

# ------------------------------------------------------------------------------
# void display_draw_line(x1, y1, x2, y2, color: v1)
# Bresenham's line algorithm, integer error version adapted from wikipedia
.globl display_draw_line
display_draw_line:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	# dx:t0 =  abs(x2-x1);
	sub t0, a2, a0
	abs t0, t0

	# sx:t1 = x1<x2 ? 1 : -1;
	slt t1, a0, a2 # 1 if true, 0 if not
	add t1, t1, t1 # 2 if true, 0 if not
	sub t1, t1, 1  # 1 if true, -1 if not

	# dy:t2 = -abs(y2-y1);
	sub t2, a3, a1
	abs t2, t2
	neg t2, t2

	# sy:t3 = y1<y2 ? 1 : -1;
	slt t3, a1, a3
	add t3, t3, t3
	sub t3, t3, 1

	# err:t4 = dx+dy;
	add t4, t0, t2

	_display_draw_line_loop:
		# plot(x1, y1);
		sll t7, a1, DISPLAY_W_SHIFT
		add t7, t7, a0
		add t7, t7, DISPLAY_BASE
		sb  v1, (t7)

		# if(x1==x2 && y1==y2) break;
		bne a0, a2, _display_draw_line_continue
		beq a1, a3, _display_draw_line_exit

		_display_draw_line_continue:
			add t5, t4, t4 # e2:t5 = 2*err;

			# if(e2 >= dy)
			blt t5, t2, _display_draw_line_dx
				add t4, t4, t2 # err += dy;
				add a0, a0, t1 # x1 += sx;

			_display_draw_line_dx:
				# if(e2 <= dx)
				bgt t5, t0, _display_draw_line_loop
					add t4, t4, t0 # err += dx;
					add a1, a1, t3 # y1 += sy;

	j _display_draw_line_loop

_display_draw_line_exit:
	jr ra

# -------------------------------------------------------------------------------------------------
# draws a string of text (using the font data at the top of the file)
#	a0 = top-left x
#	a1 = top-left y
#	a2 = pointer to string to print
.globl display_draw_text
display_draw_text:
enter s0, s1, s2
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	move s0, a0 # s0: x
	move s1, a1 # s1: y
	move s2, a2 # s2: char*

	_display_draw_text_loop:
		lbu  t0, (s2)                         # t0 = ch
		beqz t0, _display_draw_text_exit      # zero terminator?
		ble  t0, 32, _display_draw_text_next  # nonprintable?
		bge  t0, 127, _display_draw_text_next # nonprintable?

		# pattern = ASCII_patterns[ch - 32]
		sub  t0, t0, 32
		sll  t0, t0, 2
		la   t1, ASCII_patterns
		add  t0, t0, t1
		lw   a2, (t0)
		beqz a2, _display_draw_text_next      # nonprintable?

		# display_blit_5x5(x, y, pattern)
		move a0, s0
		move a1, s1
		jal  display_blit_5x5

	_display_draw_text_next:
	add s0, s0, 6
	inc s2
	j   _display_draw_text_loop

_display_draw_text_exit:
leave s0, s1, s2

# -------------------------------------------------------------------------------------------------
# draws a textual representation of an int.
#	a0 = top-left x,
#	a1 = top-left y
#	a2 = integer to display (can be negative, will show a - sign)

.globl display_draw_int
display_draw_int:
enter s0, s1, s2, s3
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	move s0, a0 # current x
	move s1, a1 # y
	move s2, a2 # remaining digits to draw
	li   s3, 1  # radix (1, 10, 100 etc)

	# if it's negative...
	bgez s2, _display_draw_int_determine_length
		# make it positive
		neg  s2, s2

		# draw a -
		move a0, s0
		move a1, s1
		la   a2, pat_dash
		jal  display_blit_5x5

		# move right by 6
		add  s0, s0, 6

	# determine the number of digits needed by multiplying radix
	# by 10 until the radix no longer divides into the number
	_display_draw_int_determine_length:
		div  t0, s2, s3
		blt  t0, 10, _display_draw_int_loop
		mul  s3, s3, 10
	j _display_draw_int_determine_length

	_display_draw_int_loop:
		# extract and strip off top digit
		div  s2, s3
		mfhi s2 # keep lower digits in s2
		mflo a2 # print top digit

		# get digit pattern address
		la   t0, Digit_patterns
		sll  a2, a2, 2
		add  a2, a2, t0
		lw   a2, (a2)
		move a0, s0
		move a1, s1
		jal  display_blit_5x5

		# scoot over, decrease radix until it's 0
		add  s0, s0, 6
		div  s3, s3, 10
	bnez s3, _display_draw_int_loop
leave s0, s1, s2, s3

# -------------------------------------------------------------------------------------------------
# draws a textual representation of an int in hex (WITHOUT leading 0x).
# does not display negatives with a -, just FFF...etc.
#	a0 = top-left x,
#	a1 = top-left y
#	a2 = integer to display
#   a3 = digits to display [1..8]

.globl display_draw_int_hex
display_draw_int_hex:
enter s0, s1, s2, s3
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64
	tlti a3, 1
	tgei a3, 9

	move s0, a0 # current x
	move s1, a1 # y
	move s2, a2 # remaining digits to draw
	sub  s3, a3, 1
	sll  s3, s3, 2 # shift amount (28, 24, 20...)

	_display_draw_int_hex_loop:
		# extract current digit ((value >> shift_distance) & 0xF)
		srlv a2, s2, s3
		and  a2, a2, 0xF

		la t0, Digit_patterns
		blt a2, 10, _display_draw_int_hex_decimal
			sub a2, a2, 10
			la  t0, Letter_patterns
		_display_draw_int_hex_decimal:

		# get pattern address
		sll  a2, a2, 2
		add  a2, a2, t0
		lw   a2, (a2)
		move a0, s0
		move a1, s1
		jal  display_blit_5x5

		# scoot over, decrease shift amount until it's < 0
		add s0, s0, 6
		sub s3, s3, 4
	bgez s3, _display_draw_int_hex_loop
leave s0, s1, s2, s3

# -------------------------------------------------------------------------------------------------
# quickly draw a 5x5-pixel pattern to the display. it can have transparent
# pixels; those with COLOR_NONE will not change the display. This way you can
# have "holes" in your images.
# this function screen-wraps vertically properly. horizontally it just cheats
# and takes advantage of the fact that writing past the end of a row writes to
# the next row, but it's one pixel... cmon...........
#	a0 = top-left x
#	a1 = top-left y
#	a2 = pointer to pattern (an array of 25 bytes stored row-by-row)

.globl display_blit_5x5_trans
display_blit_5x5_trans:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll t1, a1, DISPLAY_W_SHIFT
	add t1, t1, DISPLAY_BASE
	add t1, t1, a0

.macro BLIT_TRANS_PIXEL %off1, %off2
	lb   t0, %off1(a2)
	bltz t0, _transparent
	sb   t0, %off2(t1)
_transparent:
.end_macro

.macro NEXT_ROW
	add t1, t1, 64
	blt t1, DISPLAY_END, _nowrap
	sub t1, t1, DISPLAY_SIZE
_nowrap:
.end_macro

	BLIT_TRANS_PIXEL 0, 0
	BLIT_TRANS_PIXEL 1, 1
	BLIT_TRANS_PIXEL 2, 2
	BLIT_TRANS_PIXEL 3, 3
	BLIT_TRANS_PIXEL 4, 4
	NEXT_ROW
	BLIT_TRANS_PIXEL 5, 0
	BLIT_TRANS_PIXEL 6, 1
	BLIT_TRANS_PIXEL 7, 2
	BLIT_TRANS_PIXEL 8, 3
	BLIT_TRANS_PIXEL 9, 4
	NEXT_ROW
	BLIT_TRANS_PIXEL 10, 0
	BLIT_TRANS_PIXEL 11, 1
	BLIT_TRANS_PIXEL 12, 2
	BLIT_TRANS_PIXEL 13, 3
	BLIT_TRANS_PIXEL 14, 4
	NEXT_ROW
	BLIT_TRANS_PIXEL 15, 0
	BLIT_TRANS_PIXEL 16, 1
	BLIT_TRANS_PIXEL 17, 2
	BLIT_TRANS_PIXEL 18, 3
	BLIT_TRANS_PIXEL 19, 4
	NEXT_ROW
	BLIT_TRANS_PIXEL 20, 0
	BLIT_TRANS_PIXEL 21, 1
	BLIT_TRANS_PIXEL 22, 2
	BLIT_TRANS_PIXEL 23, 3
	BLIT_TRANS_PIXEL 24, 4
	jr       ra

# -------------------------------------------------------------------------------------------------
# quickly draw a 5x5-pixel pattern to the display without transparency.
# if it has any COLOR_NONE pixels, the result is undefined.
#	a0 = top-left x
#	a1 = top-left y
#	a2 = pointer to pattern (an array of 25 bytes stored row-by-row)

.globl display_blit_5x5
display_blit_5x5:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, DISPLAY_BASE
	add a1, a1, a0

.macro BLIT_PIXEL %off1, %off2
	lb t0, %off1(a2)
	sb t0, %off2(a1)
.end_macro

	BLIT_PIXEL 0, 0
	BLIT_PIXEL 1, 1
	BLIT_PIXEL 2, 2
	BLIT_PIXEL 3, 3
	BLIT_PIXEL 4, 4

	BLIT_PIXEL 5, 64
	BLIT_PIXEL 6, 65
	BLIT_PIXEL 7, 66
	BLIT_PIXEL 8, 67
	BLIT_PIXEL 9, 68

	BLIT_PIXEL 10, 128
	BLIT_PIXEL 11, 129
	BLIT_PIXEL 12, 130
	BLIT_PIXEL 13, 131
	BLIT_PIXEL 14, 132

	BLIT_PIXEL 15, 192
	BLIT_PIXEL 16, 193
	BLIT_PIXEL 17, 194
	BLIT_PIXEL 18, 195
	BLIT_PIXEL 19, 196

	BLIT_PIXEL 20, 256
	BLIT_PIXEL 21, 257
	BLIT_PIXEL 22, 258
	BLIT_PIXEL 23, 259
	BLIT_PIXEL 24, 260
	jr       ra