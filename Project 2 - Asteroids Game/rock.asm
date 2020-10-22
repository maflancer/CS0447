.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Rocks
# =================================================================================================

.globl rocks_count
rocks_count:
enter
	la t0, objects
	li t1, 0
	li v0, 0

	_rocks_count_loop:
		lw t2, Object_type(t0)
		beq t2, TYPE_ROCK_L, _rocks_count_yes
		beq t2, TYPE_ROCK_M, _rocks_count_yes
		bne t2, TYPE_ROCK_S, _rocks_count_continue
		_rocks_count_yes:
			inc v0
	_rocks_count_continue:
	add t0, t0, Object_sizeof
	inc t1
	blt t1, MAX_OBJECTS, _rocks_count_loop
leave

# ------------------------------------------------------------------------------

# void rocks_init(int num_rocks)
.globl rocks_init
rocks_init:
enter s0, s1, s2

	li s0, 0   #i = 0
	move a2, a0

	init_loop:
		add s0, s0, 1

		li a0, 0x2000
		jal random

		add v0, v0, 0x3000
		remu v0, v0 ,0x4000

		move s1, v0   			#stores x into s1

		li a0, 0x2000
		jal random

		add v0, v0, 0x3000
		remu v0, v0, 0x4000

		move a0, s1				#a0 = x
		move a1, v0 			#a1 = y

		li a2, TYPE_ROCK_L

		jal rock_new

		blt s0, a2, init_loop
	
leave s0, s1, s2

# ------------------------------------------------------------------------------

# void rock_new(x, y, type) 
rock_new:
	enter s0, s1, s2, s3

	move s0, a0               #s0 = x
	move s1, a1				  #s1 = y
	move s2, a2				  #s2 = type


	move a0, a2				  #moves a2(the type) to a0 so it can be used for Object_new
	jal Object_new

	beq v0, 0, _no_object1	#if 0 is returned no object could be allocated

	sw s0, Object_x(v0)		#stores x at rock's x
	sw s1, Object_y(v0)		#stores y at rock's y

	li t0, TYPE_ROCK_L
	bne s2, t0, _not_L 		#if its a large rock

	li t0, ROCK_L_HW
	sw t0, Object_hw(v0)   
 							#stores ROCK_L_HW and ROCK_L_HH
	li t0, ROCK_L_HH
	sw t0, Object_hh(v0)
	
	li s3, ROCK_VEL			#sets velocity = to ROCK_VEL

	_not_L:

	li t0, TYPE_ROCK_M
	bne s2, t0, _not_M		#if its a medium rock

	li t0, ROCK_M_HW
	sw t0, Object_hw(v0)
							#stores ROCK_M_HW and ROCK_M_HH
	li t0, ROCK_M_HH
	sw t0, Object_hh(v0)

	li s3, ROCK_VEL			#sets velocity = to ROCK_VEL*4
	mul s3, s3, 4

	_not_M:

	li t0, TYPE_ROCK_S
	bne s2, t0, _not_S		#if its a small rock

	li t0, ROCK_S_HW
	sw t0, Object_hw(v0)
							#stores ROCK_S_HW and ROCK_S_HH
	li t0, ROCK_S_HH
	sw t0, Object_hh(v0)

	li s3, ROCK_VEL
	mul s3, s3, 12			#sets velocity = to ROCK_VEL*12

	_not_S:

	_no_object1:

	move s0, v0              #s0 = v0    -> v0 is rock's address

	li a0, 360
	jal random

	move a1, v0	

	move a0, s3

	jal to_cartesian		 #to_cartesian()

	sw v0, Object_vx(s0)     #sets objects x velocity to v0
	sw v1, Object_vy(s0)	 #sets objects y velocity to v1

leave s0, s1, s2, s3

# ------------------------------------------------------------------------------

.globl rock_update
rock_update:
enter
	jal Object_accumulate_velocity

	jal Object_wrap_position

	jal rock_collide_with_bullets

leave

# ------------------------------------------------------------------------------

rock_collide_with_bullets:
enter s0, s1, s2

	move s2, a0    #s2 = rock's address

	la s0, objects
	li s1, 0

	_collide_loop:
		
	li t0, TYPE_BULLET
	lw t1, Object_type(s0)

	bne t0, t1, _not_bullet				#checks if object type is bullet

	move a0, s2
	lw a1, Object_x(s0)	
	lw a2, Object_y(s0)

	jal Object_contains_point			#Object_contains_point(obj,x,y)

	bne v0, 1, _not_bullet

	move a0, s2							#calls rock_get_hit(rock)
	jal rock_get_hit

	move a0, s0							#calls Object_delete(bullet)
	jal Object_delete

	j _out_of_loop

	_not_bullet:

	add s0, s0, Object_sizeof			#moves to next object in array
	inc s1 								#i++
	blt s1, MAX_OBJECTS, _collide_loop

	_out_of_loop:

leave s0, s1, s2

# ------------------------------------------------------------------------------

rock_get_hit:
enter s0
	move s0, a0 		#s0 = rock's address

	lw t0, Object_type(s0) #loads t0 with rock's size
	li t1, TYPE_ROCK_L

	bne t0, t1, _next_size

	lw a0, Object_x(s0)
	lw a1, Object_y(s0)
	li a2, TYPE_ROCK_M

	jal rock_new			#if a large rock was hit, it splits into two medium rocks 

	lw a0, Object_x(s0)
	lw a1, Object_y(s0)
	li a2, TYPE_ROCK_M

	jal rock_new

	_next_size:

	lw t0, Object_type(s0)
	li t1, TYPE_ROCK_M

	bne t0, t1, _next_size1

	lw a0, Object_x(s0)
	lw a1, Object_y(s0)
	li a2, TYPE_ROCK_S

	jal rock_new 			#if a medium rock was hit, it splits into two small rocks

	lw a0, Object_x(s0)
	lw a1, Object_y(s0)
	li a2, TYPE_ROCK_S

	jal rock_new

	_next_size1:

	lw a0, Object_x(s0)
	lw a1, Object_y(s0)

	jal explosion_new		#explosion_new(rock.x, rock.y)

	move a0, s0				#deletes rock
	jal Object_delete

leave s0

# ------------------------------------------------------------------------------

.globl rock_collide_l
rock_collide_l:
enter
	jal rock_get_hit 

	li a0, 3
	jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_collide_m
rock_collide_m:
enter
	jal rock_get_hit 

	li a0, 2
	jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_collide_s
rock_collide_s:
enter
	jal rock_get_hit 

	li a0, 1
	jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_draw_l
rock_draw_l:
enter
	la a1, spr_rock_l	
	jal Object_blit_5x5_trans
leave

# ------------------------------------------------------------------------------

.globl rock_draw_m
rock_draw_m:
enter
	la a1, spr_rock_m	
	jal Object_blit_5x5_trans
leave

# ------------------------------------------------------------------------------

.globl rock_draw_s
rock_draw_s:
enter
	la a1, spr_rock_s
	jal Object_blit_5x5_trans
leave
