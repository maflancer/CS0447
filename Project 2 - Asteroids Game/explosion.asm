.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Explosions
# =================================================================================================

# void explosion_new(x, y)
.globl explosion_new
explosion_new:
enter s0, s1
	
	move s0, a0               #s0 = x
	move s1, a1				  #s1 = y

	li a0, TYPE_EXPLOSION	#Object_new(TYPE_EXPLOSION)
	jal Object_new

	beq v0, 0, _no_object2	#if 0 is returned no object could be allocated

	sw s0, Object_x(v0)		#stores x at explosion's x
	sw s1, Object_y(v0)		#stores y at explosion's y

	li t0, EXPLOSION_HW
	sw t0, Object_hw(v0)

	li t0, EXPLOSION_HH
	sw t0, Object_hh(v0)

	li t0, EXPLOSION_ANIM_DELAY
	sw t0, Explosion_timer(v0)		#stores EXPLOSION_ANIM_DELAY into Explosion_timer

	li t0, 0					
	sw t0, Explosion_frame(v0)		#stores 0 into Explosion_frame

	_no_object2:

leave s0 s1

# ------------------------------------------------------------------------------

.globl explosion_update
explosion_update:
enter s0
	move s0, a0 

	lw t0, Explosion_timer(s0)			#decrements explosion timer
	dec t0
	sw t0, Explosion_timer(s0)

	bne t0, 0, _not_zero				#if explosion timer is equal to 0

	li t0, EXPLOSION_ANIM_DELAY         #stores explosion timer with EXPLOSION_ANIM_DELAY
	sw t0, Explosion_timer(s0)

	lw t0, Explosion_frame(s0)
	inc t0								#increments explosion_frame
	sw t0, Explosion_frame(s0)

	blt t0, 6, _not_zero				#if explosion_frame is >= 6

	move a0, s0			
	jal Object_delete					#delete object

	_not_zero:

leave s0

# ------------------------------------------------------------------------------

.globl explosion_draw
explosion_draw:
enter s0
	move s0, a0

	la t0, spr_explosion_frames            #puts address of spr_explosion_frames into
	lw t1, Explosion_frame(s0)			   #adds explosion_frame t0 address

	add t1, t1, t0

	move a1, t1							#a1 = spr_explosion_frames[explosion.Explosion_frame]

	jal Object_blit_5x5_trans
leave s0
