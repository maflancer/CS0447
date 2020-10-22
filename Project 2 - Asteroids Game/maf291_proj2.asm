# Matthew Flancer
# maf291

.include "constants.asm"
.include "macros.asm"

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
#                                            HEY!
#                   Turn on "Settings > Assemble all files in directory".
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# ------------------------------------------------------------------------------
# main state machine loop
.globl main
main:
_main_loop:
	lw  t0, game_state
	beq t0, GAME_STATE_INIT,   _main_init
	beq t0, GAME_STATE_NORMAL, _main_normal
	beq t0, GAME_STATE_WON,    _main_won
	beq t0, GAME_STATE_LOST,   _main_lost
	break # crashes on invalid game states

	_main_init:
		jal game_init
		j _main_loop
	_main_normal:
		jal game_normal
		j _main_loop
	_main_won:
		jal game_over
		j _main_loop
	_main_lost:
		jal game_over
		j _main_loop

# ------------------------------------------------------------------------------
game_init:
enter
	jal Object_delete_all
	jal player_init
	li  a0, 4
	jal rocks_init

	li  t0, GAME_STATE_NORMAL
	sw  t0, game_state
leave

# ------------------------------------------------------------------------------
game_normal:
enter
	# check for win condition - UNCOMMENT THIS ONCE YOU IMPLEMENT ROCKS!
	jal rocks_count
	bne v0, 0, _game_normal_keepgoing
	 	jal win_game
	_game_normal_keepgoing:

	# update
	jal Object_update_all
	jal player_collide_all

	# draw
	jal Object_draw_all
	jal hud_draw

	# end frame
	jal display_update_and_clear
	jal wait_for_next_frame
leave

# ------------------------------------------------------------------------------
game_over:
enter
	lw  t0, game_over_frames
	beq t0, 0, _game_over_init
		dec t0
		sw  t0, game_over_frames

		li   a0, 5
		li   a1, 29
		lstr a2, "GAME OVER"
		lw   t0, game_state
		bne  t0, GAME_STATE_WON, _game_over_draw
			lstr a2, "CONGRATS!"
		_game_over_draw:
		jal display_draw_text

		jal display_update_and_clear
		jal wait_for_next_frame
	j _game_over_return
	_game_over_init:
		li  t0, GAME_STATE_INIT
		sw  t0, game_state
	_game_over_return:
leave

# ------------------------------------------------------------------------------
.globl win_game
win_game:
enter
	li t0, GAME_WON_FRAMES
	sw t0, game_over_frames
	li t0, GAME_STATE_WON
	sw t0, game_state
leave

# ------------------------------------------------------------------------------
.globl lose_game
lose_game:
enter
	li t0, GAME_LOST_FRAMES
	sw t0, game_over_frames
	li t0, GAME_STATE_LOST
	sw t0, game_state
leave
