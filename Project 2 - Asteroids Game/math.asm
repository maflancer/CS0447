.include "macros.asm"

# -------------------------------------------------------------------------------------------------
# random(x)
#   returns a random integer in the range [0, x - 1]
#   so random(100) will return numbers [0, 99]
.globl random
random:
	move a1, a0
	li   a0, 0
	syscall_rand_range
	jr ra

# -------------------------------------------------------------------------------------------------
# clamp(val: a0, lo: a1, hi: a2)
#   returns val clamped to range [lo, hi] (inclusive both ends)
.globl clamp
clamp:
enter
	# if(value < lo) return lo
	# else if(value > hi) return hi
	# else return value
	move v0, a0
	bge  a0, a1, _clamp_check_hi
		move v0, a1
	j    _clamp_exit
	_clamp_check_hi:
		ble  a0, a2, _clamp_exit
		move v0, a2
	_clamp_exit:
leave

# -------------------------------------------------------------------------------------------------
# fixed16_16 sin(int angle)
#   returns the sine of an angle (in degrees) as a 16.16 fixed point number.
.globl sin
sin:
	rem a0, a0, 360
	la  t0, sin_table
	sll a0, a0, 2
	add t0, t0, a0
	lw  v0, (t0)
	jr  ra

# -------------------------------------------------------------------------------------------------
# fixed16_16 cos(int angle)
#   returns the cosine of an angle (in degrees) as a 16.16 fixed point number.
.globl cos
cos:
	add a0, a0, 90
	rem a0, a0, 360
	la  t0, sin_table
	sll a0, a0, 2
	add t0, t0, a0
	lw  v0, (t0)
	jr  ra

# -------------------------------------------------------------------------------------------------
# (fixed16_16, fixed16_16) sin_cos(int angle)
#   returns the sine (v0) and cosine (v1) of an angle (in degrees) as 16.16 fixed point numbers.
.globl sin_cos
sin_cos:
	add a1, a0, 90
	rem a0, a0, 360
	rem a1, a1, 360
	la  t0, sin_table
	sll a0, a0, 2
	sll a1, a1, 2
	add v0, t0, a0
	lw  v0, (v0)
	add v1, t0, a1
	lw  v1, (v1)
	jr  ra

# -------------------------------------------------------------------------------------------------
# (fixed24_8, fixed24_8) to_cartesian(fixed24_8 r, int theta)
#   converts a polar coordinate/vector (r, theta) to cartesian coordinate (x, y).
#   returns x in v0, y in v1.
#   uses convention of theta=0 is up (negative Y on display), clockwise as angle increases
.globl to_cartesian
to_cartesian:
	# gets unscaled vector 16.16 from theta
	# (same as sin_cos code)
	add t1, a1, 90
	rem a1, a1, 360
	rem t1, t1, 360
	la  t0, sin_table
	sll a1, a1, 2
	sll t1, t1, 2
	add v0, t0, a1
	lw  v0, (v0)
	add v1, t0, t1
	lw  v1, (v1)

	# multiply by r
	mul v0, v0, a0
	neg a0, a0 # flip y axis
	mul v1, v1, a0

	# now they're 8.24. shift right to 24.8
	sra v0, v0, 16
	sra v1, v1, 16

	jr ra

# -------------------------------------------------------------------------------------------------
# fixed24_8 hypot(fixed24_8 dx, fixed24_8 dy)
#   computes the length of the hypotenuse of a right triangle with
#   side lengths dx and dy (i.e. √(dx^2 + dy^2))
.globl hypot_24_8
hypot_24_8:
enter
	# square dx and dy; leave in 16.16
	mul a0, a0, a0
	mul a1, a1, a1

	# sqrt(dx^2 + dy^2)
	add a0, a0, a1
	jal sqrt_16_16

	# 16.16 -> 24.8
	sra v0, v0, 8
leave

# -------------------------------------------------------------------------------------------------
# (fixed24_8, fixed24_8) normalize(fixed24_8 x, fixed24_8 y)
#   normalizes a 2D vector to unit length (i.e. length == 1).
#   returns x in v0, y in v1.
.globl normalize_24_8
normalize_24_8:
enter s0, s1
move s0, a0
move s1, a1
	jal hypot_24_8
	sll s1, s1, 8
	div v1, s1, v0
	sll s0, s0, 8
	div v0, s0, v0
leave s0, s1

# -------------------------------------------------------------------------------------------------
# fixed16_16 sqrt_16_16(fixed16_16 x)
#   returns the square root (√x) of a 16.16 fixed-point number,
#   as a 16.16 fixed-point number. adapted from:
#   https://github.com/chmike/fpsqrt/blob/master/fpsqrt.c
.globl sqrt_16_16
sqrt_16_16:
	# t0 = 0x40000000
	li t0, 0x40000000

	# v0 = 0
	li v0, 0

	# while( t0 > 0x40 )
	_sqrt_16_16_loop:
	ble t0, 0x40, _sqrt_16_16_break
		# t1 = v0 + t0
		add t1, v0, t0

		# if( a0 >= t1 )
		blt a0, t1, _sqrt_16_16_less
			# a0 -= t1
			sub a0, a0, t1
			# v0 = t1 + t0 // equivalent to v0 += 2*t0
			add v0, t1, t0
		_sqrt_16_16_less:

		# a0 <<= 1
		sll a0, a0, 1
		# t0 >>= 1
		srl t0, t0, 1
	j _sqrt_16_16_loop

_sqrt_16_16_break:
	# v0 >>= 8
	srl v0, v0, 8
	jr ra

# -------------------------------------------------------------------------------------------------
# fixed16_16 rsq_16_16(fixed16_16 x)
#   returns the reciprocal square root (1/√x) of a 16.16 fixed-point number,
#   as a 16.16 fixed-point number. how's this work? I DUNNO LOL
#   adapted from https://stackoverflow.com/a/32337283
.macro umulhi %rd, %rs, %rt
	multu %rs, %rt
	mfhi %rd
.end_macro

.globl rsq_16_16
rsq_16_16:
	# if(a == 0) return ~a;                      // handle special case of zero input
	bnez a0, _rsq_16_16_not_zero
		not v0, a0
		j _rsq_16_16_return
	_rsq_16_16_not_zero:

	# scal:t0 = __clz(a) & 0xfffffffe;     // normalize argument
	clz t0, a0
	andi t0, t0, 0xFFFFFFFE

	# a = a << scal;
	sllv a0, a0, t0

	# t:t1 = rsq_16_16_table[(a >> 25) - 32];    // initial approximation
	srl  t1, a0, 23
	subu t1, t1, 128
	la   t2, rsq_16_16_table
	add  t2, t2, t1
	lw   t1, (t2)

	# r:t2 = (t << 22) - __umulhi(t, a);   // first NR iteration
	sll    t2, t1, 22
	umulhi t3, t1, a0
	subu   t2, t2, t3

	# s:t3 = __umulhi(r, a);               // second NR iteration
	umulhi t3, t2, a0

	# s:t3 = 0x30000000 - __umulhi(r, s);
	umulhi t3, t2, t3
	li     t4, 0x30000000
	subu   t3, t4, t3

	# r:t2 = __umulhi(r, s);
	umulhi t2, t2, t3

	# return ((r >> (18 - (scal >> 1))) + 1) >> 1;  // denormalize and round result
	srl  t0, t0, 1  # t0 = scal >> 1
	li   t4, 18
	subu t0, t4, t0 # t0 = (18 - (scal >> 1))
	srlv t0, t2, t0 # t0 = (r >> (18 - (scal >> 1)))
	addu t0, t0, 1  # t0 = ((r >> (18 - (scal >> 1))) + 1)
	srl  v0, t0, 1

_rsq_16_16_return:
	jr ra

.data
.globl sin_table
sin_table: .word
	0x00000000 0x00000477 0x000008EF 0x00000D65 0x000011DB 0x0000164F
	0x00001AC2 0x00001F32 0x000023A0 0x0000280C 0x00002C74 0x000030D8
	0x00003539 0x00003996 0x00003DEE 0x00004241 0x00004690 0x00004AD8
	0x00004F1B 0x00005358 0x0000578E 0x00005BBE 0x00005FE6 0x00006406
	0x0000681F 0x00006C30 0x00007039 0x00007438 0x0000782F 0x00007C1C
	0x00007FFF 0x000083D9 0x000087A8 0x00008B6D 0x00008F27 0x000092D5
	0x00009679 0x00009A10 0x00009D9B 0x0000A11B 0x0000A48D 0x0000A7F3
	0x0000AB4C 0x0000AE97 0x0000B1D5 0x0000B504 0x0000B826 0x0000BB39
	0x0000BE3E 0x0000C134 0x0000C41B 0x0000C6F3 0x0000C9BB 0x0000CC73
	0x0000CF1B 0x0000D1B3 0x0000D43B 0x0000D6B3 0x0000D919 0x0000DB6F
	0x0000DDB3 0x0000DFE7 0x0000E208 0x0000E419 0x0000E617 0x0000E803
	0x0000E9DE 0x0000EBA6 0x0000ED5B 0x0000EEFF 0x0000F08F 0x0000F20D
	0x0000F378 0x0000F4D0 0x0000F615 0x0000F746 0x0000F865 0x0000F970
	0x0000FA67 0x0000FB4B 0x0000FC1C 0x0000FCD9 0x0000FD82 0x0000FE17
	0x0000FE98 0x0000FF06 0x0000FF60 0x0000FFA6 0x0000FFD8 0x0000FFF6
	0x00010000 0x0000FFF6 0x0000FFD8 0x0000FFA6 0x0000FF60 0x0000FF06
	0x0000FE98 0x0000FE17 0x0000FD82 0x0000FCD9 0x0000FC1C 0x0000FB4B
	0x0000FA67 0x0000F970 0x0000F865 0x0000F746 0x0000F615 0x0000F4D0
	0x0000F378 0x0000F20D 0x0000F08F 0x0000EEFF 0x0000ED5B 0x0000EBA6
	0x0000E9DE 0x0000E803 0x0000E617 0x0000E419 0x0000E208 0x0000DFE7
	0x0000DDB3 0x0000DB6F 0x0000D919 0x0000D6B3 0x0000D43B 0x0000D1B3
	0x0000CF1B 0x0000CC73 0x0000C9BB 0x0000C6F3 0x0000C41B 0x0000C134
	0x0000BE3E 0x0000BB39 0x0000B826 0x0000B504 0x0000B1D5 0x0000AE97
	0x0000AB4C 0x0000A7F3 0x0000A48D 0x0000A11B 0x00009D9B 0x00009A10
	0x00009679 0x000092D5 0x00008F27 0x00008B6D 0x000087A8 0x000083D9
	0x00007FFF 0x00007C1C 0x0000782F 0x00007438 0x00007039 0x00006C30
	0x0000681F 0x00006406 0x00005FE6 0x00005BBE 0x0000578E 0x00005358
	0x00004F1B 0x00004AD8 0x00004690 0x00004241 0x00003DEE 0x00003996
	0x00003539 0x000030D8 0x00002C74 0x0000280C 0x000023A0 0x00001F32
	0x00001AC2 0x0000164F 0x000011DB 0x00000D65 0x000008EF 0x00000477
	0x00000000 0xFFFFFB89 0xFFFFF711 0xFFFFF29B 0xFFFFEE25 0xFFFFE9B1
	0xFFFFE53E 0xFFFFE0CE 0xFFFFDC60 0xFFFFD7F4 0xFFFFD38C 0xFFFFCF28
	0xFFFFCAC7 0xFFFFC66A 0xFFFFC212 0xFFFFBDBF 0xFFFFB970 0xFFFFB528
	0xFFFFB0E5 0xFFFFACA8 0xFFFFA872 0xFFFFA442 0xFFFFA01A 0xFFFF9BFA
	0xFFFF97E1 0xFFFF93D0 0xFFFF8FC7 0xFFFF8BC8 0xFFFF87D1 0xFFFF83E4
	0xFFFF8000 0xFFFF7C27 0xFFFF7858 0xFFFF7493 0xFFFF70D9 0xFFFF6D2B
	0xFFFF6987 0xFFFF65F0 0xFFFF6265 0xFFFF5EE5 0xFFFF5B73 0xFFFF580D
	0xFFFF54B4 0xFFFF5169 0xFFFF4E2B 0xFFFF4AFC 0xFFFF47DA 0xFFFF44C7
	0xFFFF41C2 0xFFFF3ECC 0xFFFF3BE5 0xFFFF390D 0xFFFF3645 0xFFFF338D
	0xFFFF30E5 0xFFFF2E4D 0xFFFF2BC5 0xFFFF294D 0xFFFF26E7 0xFFFF2491
	0xFFFF224D 0xFFFF2019 0xFFFF1DF8 0xFFFF1BE7 0xFFFF19E9 0xFFFF17FD
	0xFFFF1622 0xFFFF145A 0xFFFF12A5 0xFFFF1101 0xFFFF0F71 0xFFFF0DF3
	0xFFFF0C88 0xFFFF0B30 0xFFFF09EB 0xFFFF08BA 0xFFFF079B 0xFFFF0690
	0xFFFF0599 0xFFFF04B5 0xFFFF03E4 0xFFFF0327 0xFFFF027E 0xFFFF01E9
	0xFFFF0168 0xFFFF00FA 0xFFFF00A0 0xFFFF005A 0xFFFF0028 0xFFFF000A
	0xFFFF0000 0xFFFF000A 0xFFFF0028 0xFFFF005A 0xFFFF00A0 0xFFFF00FA
	0xFFFF0168 0xFFFF01E9 0xFFFF027E 0xFFFF0327 0xFFFF03E4 0xFFFF04B5
	0xFFFF0599 0xFFFF0690 0xFFFF079B 0xFFFF08BA 0xFFFF09EB 0xFFFF0B30
	0xFFFF0C88 0xFFFF0DF3 0xFFFF0F71 0xFFFF1101 0xFFFF12A5 0xFFFF145A
	0xFFFF1622 0xFFFF17FD 0xFFFF19E9 0xFFFF1BE7 0xFFFF1DF8 0xFFFF2019
	0xFFFF224D 0xFFFF2491 0xFFFF26E7 0xFFFF294D 0xFFFF2BC5 0xFFFF2E4D
	0xFFFF30E5 0xFFFF338D 0xFFFF3645 0xFFFF390D 0xFFFF3BE5 0xFFFF3ECC
	0xFFFF41C2 0xFFFF44C7 0xFFFF47DA 0xFFFF4AFC 0xFFFF4E2B 0xFFFF5169
	0xFFFF54B4 0xFFFF580D 0xFFFF5B73 0xFFFF5EE5 0xFFFF6265 0xFFFF65F0
	0xFFFF6987 0xFFFF6D2B 0xFFFF70D9 0xFFFF7493 0xFFFF7858 0xFFFF7C27
	0xFFFF8000 0xFFFF83E4 0xFFFF87D1 0xFFFF8BC8 0xFFFF8FC7 0xFFFF93D0
	0xFFFF97E1 0xFFFF9BFA 0xFFFFA01A 0xFFFFA442 0xFFFFA872 0xFFFFACA8
	0xFFFFB0E5 0xFFFFB528 0xFFFFB970 0xFFFFBDBF 0xFFFFC212 0xFFFFC66A
	0xFFFFCAC7 0xFFFFCF28 0xFFFFD38C 0xFFFFD7F4 0xFFFFDC60 0xFFFFE0CE
	0xFFFFE53E 0xFFFFE9B1 0xFFFFEE25 0xFFFFF29B 0xFFFFF711 0xFFFFFB89

rsq_16_16_table: .word
	0xFA0BDEFA 0xEE6AF6EE 0xE5EFFAE5 0xDAF27AD9
	0xD2EFF6D0 0xC890AEC4 0xC10366BB 0xB9A71AB2
	0xB4DA2EAC 0xADCE7EA3 0xA6F2B29A 0xA279A694
	0x9BEB568B 0x97A5C685 0x9163027C 0x8D4FD276
	0x89501E70 0x8563DA6A 0x818AC664 0x7DC4FE5E
	0x7A122258 0x7671BE52 0x72E44A4C 0x6F68FA46
	0x6DB22A43 0x6A52623D 0x67041A37 0x65639634
	0x622FFE2E 0x609CBA2B 0x5D837E25 0x5BFCFE22
	0x58FD461C 0x57838619 0x560E1216 0x53300A10
	0x51C72E0D 0x50621A0A 0x4DA48204 0x4C4C2E01
	0x4AF789FE 0x49A689FB 0x485A11F8 0x4710F9F5
	0x45CC2DF2 0x448B4DEF 0x421505E9 0x40DF5DE6
	0x3FADC5E3 0x3E7FE1E0 0x3D55C9DD 0x3D55D9DD
	0x3C2F41DA 0x39EDD9D4 0x39EDC1D4 0x38D281D1
	0x37BAE1CE 0x36A6C1CB 0x3595D5C8 0x3488F1C5
	0x3488FDC5 0x337FBDC2 0x3279DDBF 0x317749BC
	0x307831B9 0x307879B9 0x2F7D01B6 0x2E84DDB3
	0x2D9005B0 0x2D9015B0 0x2C9EC1AD 0x2BB0A1AA
	0x2BB0F5AA 0x2AC615A7 0x29DED1A4 0x29DEC9A4
	0x28FABDA1 0x2819E99E 0x2819ED9E 0x273C3D9B
	0x273C359B 0x2661DD98 0x258AD195 0x258AF195
	0x24B71192 0x24B6B192 0x23E6058F 0x2318118C
	0x2318718C 0x224DA189 0x224DD989 0x21860D86
	0x21862586 0x20C19183 0x20C1B183 0x20001580