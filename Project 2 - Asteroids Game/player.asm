.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Player
# =================================================================================================

.globl player_init
player_init:
enter
	# NOTE: this is unique to the player object. All other objects are made using
	# Object_new. it's just a special object.

	la t0, player
	# player.type = TYPE_PLAYER
	li t1, TYPE_PLAYER
	sw t1, Object_type(t0)

	# player.hw = PLAYER_HW, player.hh = PLAYER_HH
	li t1, PLAYER_HW
	sw t1, Object_hw(t0)
	li t1, PLAYER_HH
	sw t1, Object_hh(t0)

	# reset lives
	li t1, PLAYER_INIT_LIVES
	sw t1, player_lives

	# reset the rest
	jal player_respawn
leave

# ------------------------------------------------------------------------------
player_respawn:
enter
	la t0, player

	# player.x = player.y = 32.0
	li t1, 0x2000
	sw t1, Object_x(t0)
	sw t1, Object_y(t0)

	# player.vx = player.vy = 0
	sw zero, Object_vx(t0)
	sw zero, Object_vy(t0)

	# reset the other variables
	sw zero, player_iframes
	sw zero, player_fire_time
	sw zero, player_deadframes
	sw zero, player_angle
	sw zero, player_accel
	li t1, PLAYER_MAX_HEALTH
	sw t1, player_health
leave

# ------------------------------------------------------------------------------
.globl player_update
player_update:
enter
	lw t0, player_deadframes			#if player_deadframes == 0
	bne t0, 0, _not_normal

	lw t0, player_fire_time				

	ble t0, 0, _no_limit				#if player_fire_time > 0

	dec t0								#player_fire_time--
	sw t0, player_fire_time

	_no_limit:

	lw t0, player_iframes

	ble t0, 0, _no_frame				#if player_iframes > 0

	dec t0								#player_iframes--
	sw t0, player_iframes

	_no_frame:

	jal player_check_input

	jal player_update_thrust

	la a0, player
	li a1, PLAYER_DRAG					#Object_damp_velocity(player,PLAYER_DRAG)
	jal Object_damp_velocity

	la a0, player
	jal Object_accumulate_velocity		#Object_accumulate_velocity(player)

	la a0, player						#Object_wrap_position(player)
	jal Object_wrap_position

	j _finished

	_not_normal:

	lw t0, player_deadframes
	dec t0						#player_deadframes--
	sw t0, player_deadframes

	bne t0, 0, _finished		#if player_deadframes != 0, returns

	lw t0, player_lives  		#otherwise
	ble t0, 0, _lose_game		#if player_lives > 0

	jal player_respawn

	li t0, PLAYER_HURT_IFRAMES
	sw t0, player_iframes

	j _finished

	_lose_game:

	jal lose_game

	_finished:

leave

# ------------------------------------------------------------------------------
.globl player_draw
player_draw:
enter
	# don't draw the player if they're dead.
	lw   t0, player_deadframes
	bnez t0, _player_draw_return

	# if they're invulnerable, draw them 4 frames on, 4 frames off.
	lw   t0, player_iframes
	beqz t0, _player_draw_doit
	lw   t0, frame_counter
	and  t0, t0, 4
	beqz t0, _player_draw_return

	_player_draw_doit:
		# there are 16 different directions in the rotation animation.
		# this chooses which frame to use based on the player's angle (0 = up, 90 = right)
		# a1 = spr_player[((player_angle + 11) % 360) / 23]
		lw  t0, player_angle
		add t0, t0, 11
		blt t0, 360, _player_draw_a_nowrap
			sub t0, t0, 360
		_player_draw_a_nowrap:
		div t0, t0, 23
		sll t0, t0, 2
		la  a1, spr_player
		add a1, a1, t0
		lw  a1, (a1)
		jal Object_blit_5x5_trans

	_player_draw_return:
leave

# ------------------------------------------------------------------------------
.globl player_check_input
player_check_input:
enter

	jal input_get_keys

	and t0, v0, KEY_L              
	beq t0, 0, _next_key         #checks if key pressed is left

	lw t0, player_angle           
	sub t0, t0, PLAYER_ANG_VEL   #player_angle -= PLAYER_ANG_VEL
	sw t0, player_angle

	lw t0, player_angle   
	bge t0, 0, _next_key         #if player_angle < 0 

	lw t0, player_angle
	add t0, t0, 360				 #player_angle += 360
	sw t0, player_angle

	_next_key:

	and t0, v0, KEY_R
	beq t0, 0, _next_key1		 #checks if key pressed is right

	lw t0, player_angle
	add t0, t0, PLAYER_ANG_VEL	 #player_angle += PLAYER_ANG_VEL
	sw t0, player_angle

	lw t0, player_angle   
	blt t0, 360, _next_key1      #if player_angle >= 360

	lw t0, player_angle
	sub t0, t0, 360				 #player_angle -= 360
	sw t0, player_angle

	_next_key1:

	and t0, v0, KEY_U
	beq t0, 0, _next_key2		#if up key is pressed -> accel = 1

	li t0, 1
	sw t0, player_accel	

	j _after

	_next_key2:

	li t0, 0       				#else -> accel = 0
	sw t0, player_accel

	_after:

	and t0, v0, KEY_B
	beq t0, 0, _next_key3

	jal player_fire

	_next_key3:

leave

# ------------------------------------------------------------------------------
.globl player_fire
player_fire:
enter
	lw t0, player_fire_time 
	bne t0, 0, _done_fire 		#if player_fire_time == 0

	li t0, PLAYER_FIRE_DELAY
	sw t0, player_fire_time

	la t0, player
	lw a0, Object_x(t0)
	lw a1, Object_y(t0)			#bullet_new(player.x, player.y, player_angle);
	lw a2, player_angle
	jal bullet_new

	_done_fire:

leave

# ------------------------------------------------------------------------------
.globl player_update_thrust
player_update_thrust:
enter
	
	lw t0, player_accel
	bne t0, 1, _no_thrust  		 #if player_accel is equal to 1

	li a0, PLAYER_THRUST
	lw a1, player_angle
	jal to_cartesian

	la a0, player
	move a1, v0
	move a2, v1

	jal Object_apply_acceleration

	_no_thrust:

leave

# ------------------------------------------------------------------------------
# void player_damage(int dmg)
#   can be called by other objects (like rocks) to damage the player.
#   the argument is how many points of damage to do.
.globl player_damage
player_damage:
enter s0
	lw t1, player_iframes 			#if player_iframes == 0
	bne t1, 0, _no_damage			

	 lw t0, player_health
	 sub t0, t0, a0					#damage player 
	 maxi, t0, t0, 0
	 sw t0, player_health

	 _no_damage:

	 lw t0, player_health
	 bne t0, 0, _not_dead			#if player_health == 0

	 la s0, player
	 lw a0, Object_x(s0)			#explosion_new(player.x,player.y)
	 lw a1, Object_y(s0)

	 jal explosion_new

	 lw t0, player_lives
	 dec t0							#player_lives--
	 maxi t0, t0, 0					
	 sw t0, player_lives

	 li t0, PLAYER_RESPAWN_TIME		#player_deadframes = PLAYER_RESPAWN_TIME
	 sw t0, player_deadframes

	 j _done

	 _not_dead:

	 li t0, PLAYER_HURT_IFRAMES
	 sw t0, player_iframes

	 _done:

leave s0

# ------------------------------------------------------------------------------
# player_collide_all()
# checks if the player collides with anything.
# call the appropriate player-collision function on all active objects that have one.
.globl player_collide_all
player_collide_all:
enter s0, s1, s2
	# s0 = obj
	# s1 = i
	# s2 = collision function

	# start at objects[1]
	la s0, objects
	add s0, s0, Object_sizeof
	li s1, 1
_player_collide_all_loop:
		# don't collide if the player is invulnerable or dead.
		lw   t0, player_deadframes
		bnez t0, _player_collide_all_return
		lw   t0, player_iframes
		bnez t0, _player_collide_all_return

		# s2 = player_collide_funcs[obj.type]
		lw  s2, Object_type(s0)
		sll s2, s2, 2
		la  t0, player_collide_funcs
		add s2, s2, t0
		lw  s2, (s2)

		# skip objects without a collision function
		beq s2, 0, _player_collide_all_continue

		# if Objects_overlap(obj, player)
		move a0, s0
		la   a1, player
		jal  Objects_overlap
		beq  v0, 0, _player_collide_all_continue

			# OKAY, we hit the player
			# call the function (in s2) with the object as the argument
			move a0, s0
			jalr s2

_player_collide_all_continue:
	add s0, s0, Object_sizeof
	inc s1
	blt s1, MAX_OBJECTS, _player_collide_all_loop

_player_collide_all_return:
leave s0, s1, s2