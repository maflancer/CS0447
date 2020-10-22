.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# HUD
# =================================================================================================

.globl hud_draw
hud_draw:
enter
	#jal debug_draw_frame_counter
	#jal debug_draw_player_pos
	#jal debug_draw_player_velocity
	#jal debug_draw_angle

	# lives
	li  a0, 1
	li  a1, 58
	la  a2, spr_player_0
	jal display_blit_5x5_trans
	li  a0, 6
	li  a1, 58
	la  a2, spr_times
	jal display_blit_5x5_trans
	li  a0, 11
	li  a1, 58
	lw  a2, player_lives
	jal display_draw_int

	# health
	li  a0, 20
	li  a1, 58
	la  a2, spr_health
	lw  t0, player_health
	sll t0, t0, 2
	add a2, a2, t0
	lw  a2, (a2)
	jal display_blit_5x5_trans

	# rocks remaining
	jal rocks_count
	move a2, v0
	li  a0, 29
	li  a1, 58
	jal display_draw_int
leave

debug_draw_frame_counter:
enter
	li  a0, 1
	li  a1, 2
	lw  a2, frame_counter
	li  a3, 4
	jal display_draw_int_hex
leave

debug_draw_player_velocity:
enter
	li  a0, 1
	li  a1, 1
	la  a2, player
	lw  a2, Object_vx(a2)
	jal display_draw_int

	li  a0, 1
	li  a1, 6
	la  a2, player
	lw  a2, Object_vy(a2)
	jal display_draw_int
leave

debug_draw_player_pos:
enter
	li  a0, 1
	li  a1, 11
	la  a2, player
	lw  a2, Object_x(a2)
	sra a2, a2, 8
	jal display_draw_int

	li  a0, 1
	li  a1, 16
	la  a2, player
	lw  a2, Object_y(a2)
	sra a2, a2, 8
	jal display_draw_int
leave

debug_draw_angle:
enter
	li a0, 1
	li a1, 2 
	lw a2, player_accel
	jal display_draw_int

leave