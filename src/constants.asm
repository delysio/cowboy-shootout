; ============================================================
; src/constants.asm - Hardware registers, OS shadows, & constants
; ============================================================

; --- Zero Page (ZP) Variables ---
Y_POS_0    = $82   ; Vertical position of cowboy 0 (left)
Y_POS_1    = $83   ; Vertical position of cowboy 1 (right)
Y_DIR_0    = $84   ; Movement direction of cowboy 0 (-1, 0, 1)
Y_DIR_1    = $85   ; Movement direction of cowboy 1 (-1, 0, 1)
Y_TIMER_0  = $86   ; Timer before cowboy 0 changes direction
Y_TIMER_1  = $87   ; Timer before cowboy 1 changes direction

SCROLL_X   = $88   ; Scroll window offset inside scroll_buf
SCROLL_DIR = $89   ; Scroll direction (+1 = left, $FF = right)
FINE_X     = $8B   ; Fine horizontal scroll value (0-7)

SHOOT_0    = $8C   ; Shot timer for cowboy 0 (0-249)
SHOOT_1    = $8D   ; Shot timer for cowboy 1 (0-249)

M0_ACTIVE  = $8E   ; Missile 0 active state (1 = active, 0 = inactive)
M1_ACTIVE  = $8F   ; Missile 1 active state (1 = active, 0 = inactive)
M0_X       = $90   ; Horizontal position of missile 0
M1_X       = $91   ; Horizontal position of missile 1
M0_Y       = $92   ; Vertical position of missile 0
M1_Y       = $93   ; Vertical position of missile 1

HIT_0      = $94   ; Cowboy 0 hit flashing frame counter
HIT_1      = $95   ; Cowboy 1 hit flashing frame counter

SND_SHOT   = $96   ; Active shooting sound duration counter
SND_HIT    = $97   ; Active hit (explosion) sound duration counter
GAME_STATE = $98   ; Game state (0 = attract mode/wait for start, 1 = playing)
ATTRACT_TIMER = $99 ; Frame counter for attract mode auto-start
SCORE_0    = $9A   ; Player 0 score
SCORE_1    = $9B   ; Player 1 score
SCROLLER_TIMER_LO = $9C ; 30s timer low byte
SCROLLER_TIMER_HI = $9D ; 30s timer high byte
TREE_X_0   = $9E   ; Horizontal position of tree 0
TREE_Y_0   = $9F   ; Vertical position of tree 0
TREE_X_1   = $A0   ; Horizontal position of tree 1
TREE_Y_1   = $A1   ; Vertical position of tree 1
TREE_X_2   = $A2   ; Horizontal position of tree 2
TREE_Y_2   = $A3   ; Vertical position of tree 2
TREE_X_3   = $A4   ; Horizontal position of tree 3
TREE_Y_3   = $A5   ; Vertical position of tree 3
TREE_X_4   = $A6   ; Horizontal position of tree 4
TREE_Y_4   = $A7   ; Vertical position of tree 4
TREE_X_5   = $A8   ; Horizontal position of tree 5
TREE_Y_5   = $A9   ; Vertical position of tree 5
TREE_X_6   = $AA   ; Horizontal position of tree 6
TREE_Y_6   = $AB   ; Vertical position of tree 6
TREE_X_7   = $AC   ; Horizontal position of tree 7
TREE_Y_7   = $AD   ; Vertical position of tree 7

; --- Bird Hazard ZP variables ---
BIRD_ACTIVE   = $AE   ; Bird active state (1 = active, 0 = waiting)
BIRD_X        = $AF   ; Horizontal position of bird
BIRD_Y        = $B0   ; Vertical position of bird
BIRD_FRAME    = $B1   ; Active animation frame index (0 or 1)
BIRD_ANIM_T   = $B2   ; Animation frame ticks countdown
BIRD_DX       = $B3   ; Horizontal speed step
BIRD_DY       = $B4   ; Vertical speed step
BIRD_SPAWN_LO = $B5   ; Bird spawn countdown timer low byte
BIRD_SPAWN_HI = $B6   ; Bird spawn countdown timer high byte
BIRD_X_FRAC   = $B7   ; Bird X coordinate fractional part
BIRD_Y_FRAC   = $B8   ; Bird Y coordinate fractional part
BIRD_DX_FRAC  = $B9   ; Bird horizontal speed step fractional part
BIRD_DY_FRAC  = $BA   ; Bird vertical speed step fractional part
ones_temp     = $BB   ; Global scratch variable for binary conversion and Y calculations
temp_x        = $BC   ; Global scratch variable for X calculations in collisions


; --- Game Constants ---
TITLE_LEN      = 43    ; Length of title text string
SCROLL_PAD     = 48    ; Number of spaces prepended to scroll buffer
SCROLL_BUF_LEN = 130   ; Total length of scroll buffer (pad + text + pad)
SCROLL_MAX     = SCROLL_BUF_LEN - 48 ; Max starting scroll position (82)
ATTRACT_TIMEOUT = 200 ; Frames until auto-start (~4s at 50Hz)

; --- Memory Map Locations ---
screen_ram = $3000     ; Screen memory base address (ANTIC mode 4)

; --- GTIA Write Registers ---
HPOSP0   = $D000   ; Player 0 horizontal position
HPOSP1   = $D001   ; Player 1 horizontal position
HPOSP2   = $D002   ; Player 2 horizontal position
HPOSP3   = $D003   ; Player 3 horizontal position
HPOSM0   = $D004   ; Missile 0 horizontal position
HPOSM1   = $D005   ; Missile 1 horizontal position
SIZEP0   = $D008   ; Player 0 size configuration
SIZEP1   = $D009   ; Player 1 size configuration
SIZEP2   = $D00A   ; Player 2 size configuration
SIZEP3   = $D00B   ; Player 3 size configuration
SIZEM    = $D00C   ; Missile size configuration
COLPM0   = $D012   ; Player 0 color (write)
COLPM1   = $D013   ; Player 1 color (write)
COLBK    = $D01A   ; Background color (write)
GRACTL   = $D01D   ; Graphics control (write)
HITCLR   = $D01E   ; Clear collision registers (write)
CONSOL   = $D01F   ; Console keys: START/SELECT/OPTION (read)
SKSTAT   = $D20F   ; POKEY keyboard/serial status (read)
KBCODE   = $D209   ; POKEY raw keyboard scancode (read)

; --- GTIA Read Registers (Collision) ---
M0PF     = $D000   ; Collision: Missile 0 to Playfield (read)
M1PF     = $D001   ; Collision: Missile 1 to Playfield (read)
M0PL     = $D008   ; Collision: Missile 0 to Player (read)
M1PL     = $D009   ; Collision: Missile 1 to Player (read)
P2PL     = $D00E   ; Collision: Player 2 to Player (read)

; --- POKEY Registers ---
AUDF1    = $D200   ; Channel 1 audio frequency
AUDC1    = $D201   ; Channel 1 audio control (volume/distortion)
AUDF2    = $D202   ; Channel 2 audio frequency
AUDC2    = $D203   ; Channel 2 audio control (volume/distortion)
AUDCTL   = $D208   ; Audio control settings (write)
RANDOM   = $D20A   ; Random number generator register (read)

; --- ANTIC Hardware Registers ---
DMACTL   = $D400   ; DMA control settings (write)
HSCROL   = $D404   ; Horizontal fine scroll register (write)
PMBASE   = $D407   ; Player-Missile memory base pointer (write)
CHBASE   = $D409   ; Character set memory base pointer (write)

; --- OS Shadow Registers ---
SDMCTL   = $022F   ; Shadow for DMACTL
SDLSTL   = $0230   ; Shadow for DLIST pointer (2 bytes)
GPRIOR   = $026F   ; Shadow for PRIOR ($D01B)
CHBAS    = $02F9   ; Shadow for CHBASE
PCOLR0   = $02C0   ; Shadow for COLPM0
PCOLR1   = $02C1   ; Shadow for COLPM1
PCOLR2   = $02C2   ; Shadow for COLPM2
PCOLR3   = $02C3   ; Shadow for COLPM3
COLOR0   = $02C4   ; Shadow for COLPF0
COLOR1   = $02C5   ; Shadow for COLPF1
COLOR2   = $02C6   ; Shadow for COLPF2
COLOR3   = $02C7   ; Shadow for COLPF3
COLOR4   = $02C8   ; Shadow for COLBK
RTCLOK   = $0014   ; System real-time clock (1 byte, updates every frame)
CH       = $02FC   ; Last key pressed code ($FF = no key)
STICK0   = $0278   ; OS shadow for joystick 0 direction
STRIG0   = $0284   ; OS shadow for joystick 0 trigger (0 = pressed)
