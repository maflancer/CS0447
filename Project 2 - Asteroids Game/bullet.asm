.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Bullet
# =================================================================================================

# void bullet_new(x: a0, y: a1, angle: a2)
.globl bullet_new
bullet_new:
enter s0, s1, s2

	move s0, a0               #s0 = x
	move s1, a1				  #s1 = y
	move s2, a2			      #s2 = angle

	li a0, TYPE_BULLET		#Object_new(TYPE_BULLET)
	jal Object_new

	beq v0, 0, _no_object	#if 0 is returned no object could be allocated

	sw s0, Object_x(v0)		#stores x at bullet's x
	sw s1, Object_y(v0)		#stores y at bullet's y

	move s0, v0              #s0 = v0    -> v0 is bullet address

	li a0, BULLET_THRUST     #a0 = BULLET_THRUST
	move a1, s2              #a1 = angle

	jal to_cartesian		 #to_cartesian()

	sw v0, Object_vx(s0)     #sets objects x velocity to v0
	sw v1, Object_vy(s0)	 #sets objects y velocity to v1

	li t0, BULLET_LIFE
	sw t0, Bullet_frame(s0)

	_no_object:

leave s0, s1, s2

# ------------------------------------------------------------------------------

.globl bullet_update
bullet_update:
enter 
	
	lw t0, Bullet_frame(a0)			#decrements bullet frame
	dec t0
	sw t0, Bullet_frame(a0)

	bne t0, 0, _not_delete			#if bullet_frame is == 0

	jal Object_delete				#Object_delete(bullet)
	
	j _done_update
	
	_not_delete:

	jal Object_accumulate_velocity

	jal Object_wrap_position

	_done_update:

leave 

# ------------------------------------------------------------------------------

.globl bullet_draw
bullet_draw:
enter s0
	
	move s0, a0

	lw t0, Object_x(s0)			
	sra a0, t0, 8
	lw t1, Object_y(s0)				#display_set_pixel(bullet.x >> 8, bullet.y >> 8, COLOR_RED);
	sra a1, t1, 8
	li a2, COLOR_RED
	jal display_set_pixel

leave s0