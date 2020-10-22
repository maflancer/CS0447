.data

.include "constants.asm"
.include "macros.asm"

# ------------------------------------------------------------------------------
# Game variables

	.globl game_state
	.globl game_over_frames

	game_state:       .word GAME_STATE_INIT
	game_over_frames: .word 0 # frame counter for displaying game over/won message

# ------------------------------------------------------------------------------
# Object variables

	.globl player
	.globl objects
	.globl object_update_funcs
	.globl object_draw_funcs

	.align 2
	player:  # alias for objects[0]
	objects: .space 2400 # Object_sizeof * MAX_OBJECTS = 48 * 50 = 2400

	object_update_funcs: .word
		0 # empty
		player_update
		bullet_update
		rock_update # all three sizes use the same update function
		rock_update
		rock_update
		explosion_update

	object_draw_funcs: .word
		0 # empty
		player_draw
		bullet_draw
		rock_draw_l
		rock_draw_m
		rock_draw_s
		explosion_draw

# ------------------------------------------------------------------------------
# Player variables

	.globl player_iframes
	.globl player_fire_time
	.globl player_deadframes
	.globl player_angle
	.globl player_accel
	.globl player_health
	.globl player_lives
	.globl player_collide_funcs

	player_iframes:    .word 0 # frame counter - when nonzero, player is invulnerable
	player_fire_time:  .word 0 # frame counter - when nonzero, can't fire
	player_deadframes: .word 0 # frame counter - when nonzero, player is dead.
	player_angle:      .word 0 # 0 .. 359
	player_accel:      .word 0 # boolean - true when holding up
	player_health:     .word PLAYER_MAX_HEALTH
	player_lives:      .word PLAYER_INIT_LIVES

	player_collide_funcs: .word
		0 # empty
		0 # player
		0 # bullet
		rock_collide_l
		rock_collide_m
		rock_collide_s
		0 # explosion