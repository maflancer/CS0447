# MMIO Registers
.eqv DISPLAY_CTRL       0xFFFF0000
.eqv DISPLAY_KEYS       0xFFFF0004
.eqv DISPLAY_BASE       0xFFFF0008
.eqv DISPLAY_END        0xFFFF1008
.eqv DISPLAY_SIZE           0x1000

# Display stuff
.eqv DISPLAY_W                  64
.eqv DISPLAY_H                  64
.eqv DISPLAY_W_SHIFT             6

# LED Colors
.eqv COLOR_BLACK                 0
.eqv COLOR_RED                   1
.eqv COLOR_ORANGE                2
.eqv COLOR_YELLOW                3
.eqv COLOR_GREEN                 4
.eqv COLOR_BLUE                  5
.eqv COLOR_MAGENTA               6
.eqv COLOR_WHITE                 7
.eqv COLOR_NONE                 -1

# Input key flags
.eqv KEY_NONE                 0x00
.eqv KEY_U                    0x01
.eqv KEY_D                    0x02
.eqv KEY_L                    0x04
.eqv KEY_R                    0x08
.eqv KEY_B                    0x10

# ------------------------------------------------------------------------------

# Misc game-related constants
.eqv MS_PER_FRAME               16 # 60 FPS
.eqv MAX_OBJECTS                50
.eqv GAME_WON_FRAMES           300 # 5 sec.
.eqv GAME_LOST_FRAMES          240 # 4 sec.
.eqv OBJECT_XMAX            0x4000 # 64.0
.eqv OBJECT_YMAX            0x4000 # 64.0

# Game states
.eqv GAME_STATE_INIT             0 # starting up or restarting
.eqv GAME_STATE_NORMAL           1 # playing
.eqv GAME_STATE_WON              2 # "CONGRATS!"
.eqv GAME_STATE_LOST             3 # "GAME OVER"

# Object types
.eqv TYPE_EMPTY                  0 # unused object slot
.eqv TYPE_PLAYER                 1 # the player...
.eqv TYPE_BULLET                 2 # a bullet the player shoots
.eqv TYPE_ROCK_L                 3 # large rock
.eqv TYPE_ROCK_M                 4 # medium rock
.eqv TYPE_ROCK_S                 5 # small rock
.eqv TYPE_EXPLOSION              6 # explosion animation

# Object struct fields
.eqv Object_type                 0 # one of the TYPE constants
.eqv Object_x                    4 # (24.8) x pos
.eqv Object_y                    8 # (24.8) y pos
.eqv Object_vx                  12 # (24.8) x vel
.eqv Object_vy                  16 # (24.8) y vel
.eqv Object_hw                  20 # (24.8) half-width  (measured from center)
.eqv Object_hh                  24 # (24.8) half-height
# that leaves 5 free fields (28, 32, 36, 40, 44)
# or more if you wanna make some byte/half...
.eqv Object_sizeof              48

# Player constants
.eqv PLAYER_THRUST           0x00C # 0.09375
.eqv PLAYER_ANG_VEL              5 # degrees/frame
.eqv PLAYER_MAX_VEL          0x180 # 1.5 pix/frame (90 pix/sec)
.eqv PLAYER_DRAG             0x108 # 1.03125
.eqv PLAYER_MAX_POS         0x4000 # 59.0
.eqv PLAYER_HW               0x280 # 2.5
.eqv PLAYER_HH               0x280 # 2.5
.eqv PLAYER_HURT_IFRAMES        60 # frames (1 sec)
.eqv PLAYER_FIRE_DELAY          20 # frames (1/3 sec)
.eqv PLAYER_MAX_HEALTH           5 # hits
.eqv PLAYER_RESPAWN_TIME       120 # frames (2 sec)
.eqv PLAYER_RESPAWN_IFRAMES    120 # frames (2 sec)
.eqv PLAYER_INIT_LIVES           3 #

# Explosion constants
.eqv Explosion_timer            28 # extra field
.eqv Explosion_frame            32 # extra field
.eqv EXPLOSION_ANIM_DELAY        5 # frames
.eqv EXPLOSION_HW            0x280 # 2.5
.eqv EXPLOSION_HH            0x280 # 2.5

# Bullet constants
.eqv Bullet_frame               28 # extra field
.eqv BULLET_LIFE                12 # frames (0.2 sec)
.eqv BULLET_THRUST          0x0200 # 0.75

# Rock constants
.eqv ROCK_VEL                0x009 # pretty dang slow
.eqv ROCK_L_HW               0x300 # 3.0
.eqv ROCK_L_HH               0x300 # 3.0
.eqv ROCK_M_HW               0x280 # 2.5
.eqv ROCK_M_HH               0x280 # 2.5
.eqv ROCK_S_HW               0x200 # 2.0
.eqv ROCK_S_HH               0x200 # 2.0
