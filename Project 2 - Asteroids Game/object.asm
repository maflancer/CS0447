
.include "constants.asm"
.include "macros.asm"

# ------------------------------------------------------------------------------
# Object_new(type: a0)
#   allocates a new object and returns pointer to object with type field set to "type".
#   returns null (0) if no empty object spaces available.
.globl Object_new
Object_new:
enter
	teqi a0, TYPE_EMPTY # invalid type

	la v0, objects
	li t0, MAX_OBJECTS

_Object_new_loop:
		# if obj.type == 0...
		lw   t1, Object_type(v0)
		bnez t1, _Object_new_continue

			# obj.type = type
			sw a0, Object_type(v0)

			# return obj
			j _Object_new_break
_Object_new_continue:
	add v0, v0, Object_sizeof
	dec t0
	bnez t0, _Object_new_loop

	# if we get here, no free slots found.
	li v0, 0
_Object_new_break:
leave

# ------------------------------------------------------------------------------
# Object_delete(self: a0)
#   mark this object as inactive (TYPE_EMPTY) and zeroes out all the fields.
#   (that avoids confusing bugs when reusing object slots.)
.globl Object_delete
Object_delete:
enter
	sw zero, Object_type(a0)
	sw zero, Object_x(a0)
	sw zero, Object_y(a0)
	sw zero, Object_vx(a0)
	sw zero, Object_vy(a0)
	sw zero, Object_hw(a0)
	sw zero, Object_hh(a0)
leave

# ------------------------------------------------------------------------------
# Object_delete_all()
#   deletes ALL objects.
.globl Object_delete_all
Object_delete_all:
enter s0, s1
	la s0, objects
	li s1, 0

	_Object_delete_all_loop:
		move a0, s0
		jal Object_delete
	add s0, s0, Object_sizeof
	inc s1
	blt s1, MAX_OBJECTS, _Object_delete_all_loop
leave s0, s1

# ------------------------------------------------------------------------------
# Object_accumulate_velocity(self: a0)
#   accumulates velocity into position (i.e. (x, y) += (vx, vy) )
.globl Object_accumulate_velocity
Object_accumulate_velocity:
enter
	lw  t0, Object_x(a0)
	lw  t1, Object_vx(a0)
	add t0, t0, t1
	sw  t0, Object_x(a0)

	lw  t0, Object_y(a0)
	lw  t1, Object_vy(a0)
	add t0, t0, t1
	sw  t0, Object_y(a0)
leave

# ------------------------------------------------------------------------------
# Object_apply_acceleration(self: a0, vx: a1, vy: a2)
#   adds vx, vy to object's velocity vector.
.globl Object_apply_acceleration
Object_apply_acceleration:
enter
	lw  t0, Object_vx(a0)
	add t0, t0, a1
	sw  t0, Object_vx(a0)

	lw  t0, Object_vy(a0)
	add t0, t0, a2
	sw  t0, Object_vy(a0)
leave

# ------------------------------------------------------------------------------

# Object_wrap_position(self: a0)
#   wraps an object's x/y coordinates to the range [0, 64.0) and [0, 64.0)
.globl Object_wrap_position
Object_wrap_position:
enter
	lw   t0, Object_x(a0)
	bgt  t0, 0, _Object_wrap_position_xmax
	add  t0, t0, OBJECT_XMAX
_Object_wrap_position_xmax:
	blt  t0, OBJECT_XMAX, _Object_wrap_position_store_x
	sub  t0, t0, OBJECT_XMAX
_Object_wrap_position_store_x:
	sw   t0, Object_x(a0)

	lw   t0, Object_y(a0)
	bgt  t0, 0, _Object_wrap_position_ymax
	add  t0, t0, OBJECT_YMAX
_Object_wrap_position_ymax:
	blt  t0, OBJECT_YMAX, _Object_wrap_position_store_y
	sub  t0, t0, OBJECT_YMAX
_Object_wrap_position_store_y:
	sw   t0, Object_y(a0)
leave

# ------------------------------------------------------------------------------

# Object_damp_velocity(self: a0, amount: a1)
#   damp velocity by dividing vx/vy by amount. VALUES LESS THAN 1 WILL MAKE THE
#   OBJECT ACCELERATE SO UH DON'T
.globl Object_damp_velocity
Object_damp_velocity:
enter
	lw  t0, Object_vx(a0)
	sll t0, t0, 8
	div t0, t0, a1
	sw  t0, Object_vx(a0)

	lw  t0, Object_vy(a0)
	sll t0, t0, 8
	div t0, t0, a1
	sw  t0, Object_vy(a0)
leave

# ------------------------------------------------------------------------------
# void Object_blit_5x5_trans(self: a0, pat: a1)
#   subtracts the object's halfwidth/halfheight from its coordinates, truncates
#   to int, and wraps those coordinates to the screen. then blits the given pattern 'pat'
#   at those coordinates.
.globl Object_blit_5x5_trans
Object_blit_5x5_trans:
enter
	move t1, a0
	move a2, a1

	lw  a0, Object_x(t1)
	lw  t0, Object_hw(t1)
	sub a0, a0, t0
	sra a0, a0, 8
	bgez a0, _Object_blit_5x5_trans_x_nowrap
		add a0, a0, DISPLAY_W
	_Object_blit_5x5_trans_x_nowrap:
	lw  a1, Object_y(t1)
	lw  t0, Object_hh(t1)
	sub a1, a1, t0
	sra a1, a1, 8
	bgez a1, _Object_blit_5x5_trans_y_nowrap
		add a1, a1, DISPLAY_H
	_Object_blit_5x5_trans_y_nowrap:

	jal display_blit_5x5_trans
leave

# ------------------------------------------------------------------------------
# Object_update_all()
#   calls the appropriate update function on all active objects.
.globl Object_update_all
Object_update_all:
enter s0, s1
	la s0, objects
	li s1, MAX_OBJECTS
_Object_update_all_loop:
		lw   t0, Object_type(s0)
		beqz t0, _Object_update_all_continue

		# object_update_funcs[obj.type](obj)
		sll  t0, t0, 2
		la   t1, object_update_funcs
		add  t0, t0, t1
		lw   t0, (t0)
		move a0, s0
		jalr t0

_Object_update_all_continue:
	add s0, s0, Object_sizeof
	dec s1
	bnez s1, _Object_update_all_loop

leave s0, s1

# ------------------------------------------------------------------------------
# Object_draw_all()
#   draws all active objects. draws object 0 (player) last so it's always on top.
.globl Object_draw_all
Object_draw_all:
enter s0, s1
	la s0, objects
	li s1, MAX_OBJECTS
	# s0 = &objects[MAX_OBJECTS - 1]
	mul t0, s1, Object_sizeof
	sub t0, t0, Object_sizeof
	add s0, s0, t0

	# then draw objects in reverse order from array so player comes last
_Object_draw_all_loop:
		lw   t0, Object_type(s0)
		beqz t0, _Object_draw_all_continue

		# object_draw_funcs[obj.type](obj)
		sll  t0, t0, 2
		la   t1, object_draw_funcs
		add  t0, t0, t1
		lw   t0, (t0)
		move a0, s0
		jalr t0

_Object_draw_all_continue:
	sub s0, s0, Object_sizeof
	dec s1
	bnez s1, _Object_draw_all_loop

leave s0, s1

# ------------------------------------------------------------------------------
# Object_contains_point(obj, x, y)
#   returns a boolean of whether the given point (x, y) is inside the object's hitbox.
.globl Object_contains_point
Object_contains_point:
enter
	li v0, 0

	# if abs(obj.x - x) > obj.hw, not inside
	lw  t0, Object_x(a0)
	sub t0, t0, a1
	abs t0, t0
	lw  t1, Object_hw(a0)
	bgt t0, t1, _Object_contains_point_return

	# if abs(obj.y - y) > obj.hh, not inside
	lw  t0, Object_y(a0)
	sub t0, t0, a2
	abs t0, t0
	lw  t1, Object_hh(a0)
	bgt t0, t1, _Object_contains_point_return

	li v0, 1
_Object_contains_point_return:
leave

# ------------------------------------------------------------------------------
# Objects_overlap(obj1, obj2)
#   returns a boolean of whether the two objects' hitboxes are overlapping.
.globl Objects_overlap
Objects_overlap:
enter
	li v0, 0

	# if abs(obj1.x - obj2.x) > (obj1.hw + obj2.hw), skip it
	lw  t0, Object_x(a0)
	lw  t1, Object_x(a1)
	sub t0, t0, t1
	abs t0, t0
	lw  t1, Object_hw(a0)
	lw  t2, Object_hw(a1)
	add t1, t1, t2
	bgt t0, t1, _Objects_overlap_return

	# if abs(obj1.y - obj2.y) > (obj1.hh + obj2.hh), skip it
	lw  t0, Object_y(a0)
	lw  t1, Object_y(a1)
	sub t0, t0, t1
	abs t0, t0
	lw  t1, Object_hh(a0)
	lw  t2, Object_hh(a1)
	add t1, t1, t2
	bgt t0, t1, _Objects_overlap_return

	li v0, 1
_Objects_overlap_return:
leave