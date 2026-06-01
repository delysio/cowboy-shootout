; ============================================================
; src/cowboys.asm - Cowboy state, random AI movement, & shoot timers
; ============================================================

.proc cowboys

; ------------------------------------------------------------
; cowboys.init
; Initializes cowboy starting positions, movement values, and timers
; ------------------------------------------------------------
init
        mva #50 Y_POS_0
        mva #60 Y_POS_1
        mva #0 Y_DIR_0
        sta Y_DIR_1
        sta M0_ACTIVE
        sta M1_ACTIVE
        sta HIT_0
        sta HIT_1
        sta SND_SHOT
        sta SND_HIT
        sta SHOOT_0
        mva #0 SCORE_0
        sta SCORE_1
        
        mva #1 Y_TIMER_0
        mva #10 Y_TIMER_1
        mva #125 SHOOT_1

        ; --- Reset player colors to default ---
        mva #$2A PCOLR0         ; Normal color of Cowboy 0 (gold/brown)
        mva #$86 PCOLR1         ; Normal color of Cowboy 1 (blue)

        ; --- Initialize Bird Hazard state ---
        mva #0 BIRD_ACTIVE
        sta HPOSP2              ; Ensure bird is hidden initially
        mva #<750 BIRD_SPAWN_LO
        mva #>750 BIRD_SPAWN_HI
        
        ; Clear fractional parts
        mva #0 BIRD_X_FRAC
        sta BIRD_Y_FRAC
        sta BIRD_DX_FRAC
        sta BIRD_DY_FRAC

        ; Initialize tree spawn timer to 3 seconds (150 frames)
        mva #<150 tree_spawn_timer
        mva #>150 tree_spawn_timer+1
        rts


; ------------------------------------------------------------
; cowboys.update
; Runs AI movement changes and position updates for both cowboys
; ------------------------------------------------------------
update
        lda GAME_STATE
        bne @c0_player_control  ; If GAME_STATE != 0 (playing), run joystick controls

        ; === Cowboy 0 Attract Mode Random Movement ===
        dec Y_TIMER_0
        bne @move_c0
        
        ; Randomize duration (15 to 46 frames)
        lda RANDOM
        and #$1F
        clc
        adc #15
        sta Y_TIMER_0
        
        ; Randomize direction (-1, 0, 1)
        lda RANDOM
        and #$03
        cmp #0
        bne @test_c0_down
        mva #$FF Y_DIR_0        ; Move UP
        jmp @move_c0
        
@test_c0_down
        cmp #1
        bne @test_c0_still
        mva #1 Y_DIR_0          ; Move DOWN
        jmp @move_c0
        
@test_c0_still
        mva #0 Y_DIR_0          ; Stay still

@move_c0
        lda Y_POS_0
        clc
        adc Y_DIR_0
        sta Y_POS_0
        
        ; Check boundaries (16 to 96)
        cmp #16
        bcs @c0_check_bottom
        mva #16 Y_POS_0
        mva #1 Y_DIR_0          ; Bounce down
        jmp @update_c1
        
@c0_check_bottom
        cmp #96
        bcc @update_c1
        mva #96 Y_POS_0
        mva #$FF Y_DIR_0        ; Bounce up
        jmp @update_c1

@c0_player_control
        ; --- Process Cowboy 0 (Left / Player Controlled) ---
        lda STICK0
        and #$01                ; Bit 0 = UP (0 = active)
        bne @check_c0_down
        
        lda Y_POS_0
        cmp #17
        bcc @update_c1          ; Prevent moving past upper boundary (16)
        dec Y_POS_0
        jmp @update_c1

@check_c0_down
        lda STICK0
        and #$02                ; Bit 1 = DOWN (0 = active)
        bne @update_c1
        
        lda Y_POS_0
        cmp #96
        bcs @update_c1          ; Prevent moving past lower boundary (96)
        inc Y_POS_0

@update_c1
        ; --- Process Cowboy 1 (Right) ---
        dec Y_TIMER_1
        bne @move_c1            ; If timer not zero, proceed to move
        
        ; Randomize next movement duration and direction
        lda RANDOM
        and #$1F
        clc
        adc #15
        sta Y_TIMER_1
        
        lda RANDOM
        and #$03
        cmp #0
        bne @test_c1_down
        mva #$FF Y_DIR_1        ; Move UP
        jmp @move_c1

@test_c1_down
        cmp #1
        bne @test_c1_still
        mva #1 Y_DIR_1          ; Move DOWN
        jmp @move_c1

@test_c1_still
        mva #0 Y_DIR_1          ; Stay still

@move_c1
        lda Y_POS_1
        clc
        adc Y_DIR_1
        sta Y_POS_1
        
        ; Check screen bounds (upper edge = 16)
        cmp #16
        bcs @c1_check_bottom
        mva #16 Y_POS_1
        mva #1 Y_DIR_1          ; Bounce down
        rts

@c1_check_bottom
        ; Check screen bounds (lower edge = 96)
        cmp #96
        bcc @exit_c1
        mva #96 Y_POS_1
        mva #$FF Y_DIR_1        ; Bounce up

@exit_c1
        rts


; ------------------------------------------------------------
; cowboys.shoot
; Increments shoot timers and triggers shooting logic
; ------------------------------------------------------------
shoot
        ; --- Cowboy 0 (Player Controlled) Shooting ---
        lda STRIG0
        bne @shoot_c1_check     ; If trigger not pressed (1 = released), skip
        
        lda M0_ACTIVE
        bne @shoot_c1_check     ; Skip if missile is already active
        
        mva #1 M0_ACTIVE        ; Activate missile 0
        mva #68 M0_X            ; Starting horizontal offset
        
        lda Y_POS_0
        clc
        adc #7                  ; Adjust vertical height for gun barrel
        sta M0_Y
        
        mva #12 SND_SHOT        ; Play shot sound duration

; ------------------------------------------------------------
; cowboys.check_trajectory_blocked
; Input: A = vertical scanline (Y_POS_1 + 7)
; Output: Carry set if blocked by a tree, Carry clear if clear
; ------------------------------------------------------------
check_trajectory_blocked
        sta ones_temp           ; ones_temp = vertical scanline of the bullet
        
        ldy #0                  ; Y = Tree Index (0 to 7)
@loop
        tya
        asl @
        clc
        adc #$9E
        tax                     ; X = ZP address of TREE_X_I
        
        lda $01,x               ; A = TREE_Y_I
        beq @next               ; If 0, tree is inactive, skip it
        
        lda ones_temp
        cmp $01,x               ; TREE_Y_I
        bcc @next
        sec
        sbc $01,x               ; TREE_Y_I
        cmp #4                  ; Height of tree in PMG (4 scanline units)
        bcc @blocked            ; Blocked!
        
@next
        iny
        cpy #8
        bcc @loop
        
        clc                     ; Clear means not blocked
        rts
        
@blocked
        sec                     ; Set means blocked
        rts


@shoot_c1_check
        ; --- Cowboy 1 (Right / AI Controlled) Shooting ---
        inc SHOOT_1
        
        ; Prevent shooting if Missile 1 is already flying
        lda M1_ACTIVE
        bne @exit_shoot
        
        ; Prevent shooting if the trajectory (gun height) is blocked by any tree!
        lda Y_POS_1
        clc
        adc #7                  ; AI gun height
        jsr check_trajectory_blocked
        bcs @exit_shoot         ; Trajectory blocked -> DO NOT SHOOT!
        
        ; --- Smart AI Shoot condition: vertical alignment with player ---
        lda Y_POS_1
        sec
        sbc Y_POS_0
        bpl @diff_pos
        eor #$FF                ; Absolute value
        clc
        adc #1
@diff_pos
        cmp #7                  ; Vertically aligned if difference <= 6 scanlines
        bcs @check_regular_shoot ; If not aligned, fall back to regular interval timer
        
        ; Aligned! Shoot immediately if cooldown met (at least 30 frames / 0.6s)
        lda SHOOT_1
        cmp #30
        bcs @trigger_shoot
        jmp @exit_shoot

@check_regular_shoot
        ; Dynamic Difficulty Check for regular shooting intervals:
        lda SCORE_0
        cmp #10
        bcs @score_ge_10
        
        ; SCORE_0 < 10: shoot every 200 frames (~4 seconds at 50Hz)
        ldy #200
        jmp @apply_difficulty

@score_ge_10
        cmp #20
        bcs @score_ge_20
        
        ; SCORE_0 >= 10 and < 20: shoot every 100 frames (~2 seconds at 50Hz)
        ldy #100
        jmp @apply_difficulty

@score_ge_20
        ; SCORE_0 >= 20: shoot every 50 frames (~1 second at 50Hz)
        ldy #50
        
@apply_difficulty
        tya
        cmp SHOOT_1
        bcs @exit_shoot         ; Skip if timer threshold has not been reached

@trigger_shoot
        mva #0 SHOOT_1
        mva #1 M1_ACTIVE        ; Activate missile 1
        mva #192 M1_X           ; Starting horizontal offset
        
        lda Y_POS_1
        clc
        adc #7                  ; Adjust vertical height for gun barrel
        sta M1_Y
        
        mva #12 SND_SHOT        ; Play shot sound duration

@exit_shoot
        rts


; ------------------------------------------------------------
; cowboys.flash_colors
; Handles screen color changes and flashing when hit
; ------------------------------------------------------------
flash_colors
        ; --- Cowboy 0 Flashing ---
        lda HIT_0
        beq @restore_c0_color
        dec HIT_0
        lda RTCLOK
        and #$02                ; Fast blinking interval
        beq @flash_c0_red
        mva #$0F PCOLR0         ; Pure White
        jmp @update_c1_color

@flash_c0_red
        mva #$12 PCOLR0         ; Red
        jmp @update_c1_color

@restore_c0_color
        mva #$2A PCOLR0         ; Restore normal gold/brown cowboy color

@update_c1_color
        ; --- Cowboy 1 Flashing ---
        lda HIT_1
        beq @restore_c1_color
        dec HIT_1
        lda RTCLOK
        and #$02
        beq @flash_c1_red
        mva #$0F PCOLR1         ; Pure White
        rts

@flash_c1_red
        mva #$12 PCOLR1         ; Red
        rts

@restore_c1_color
        mva #$86 PCOLR1         ; Restore normal blue cowboy color
        rts

; ------------------------------------------------------------
; cowboys.update_bird
; Decrements spawn timer when GAME_STATE is 1, and processes bird logic if active
; ------------------------------------------------------------
update_bird
        lda GAME_STATE
        beq @exit_bird          ; Only update if game is active
        
        lda BIRD_ACTIVE
        bne @process_active_bird
        
        ; Decrement spawn timer (2-byte)
        lda BIRD_SPAWN_LO
        sec
        sbc #1
        sta BIRD_SPAWN_LO
        lda BIRD_SPAWN_HI
        sbc #0
        sta BIRD_SPAWN_HI
        
        ; Check if timer reached 0
        ora BIRD_SPAWN_LO
        bne @exit_bird          ; If not 0, exit
        
        ; Spawn the bird!
        mva #1 BIRD_ACTIVE
        
        ; Starting X position randomly on the right/middle side [110, 205]
        lda RANDOM
        and #$5F                ; 0-95
        clc
        adc #110                ; 110-205 (guaranteed right-middle start)
        sta BIRD_X
        mva #0 BIRD_X_FRAC
        
        ; Starting Y position near the top
        mva #12 BIRD_Y
        mva #0 BIRD_Y_FRAC
        
        ; Starting vertical speed DY = 1.25 pixels per frame
        ; 1.25 is High byte 1, Low byte 64 (0.25 * 256 = 64)
        mva #1 BIRD_DY
        mva #64 BIRD_DY_FRAC
        
        ; Calculate BIRD_DX = (BIRD_X - 60) / 64
        ; Total horizontal distance D = BIRD_X - 60.
        ; High byte: BIRD_DX = D >> 6
        ; Low byte: BIRD_DX_FRAC = D << 2
        lda BIRD_X
        sec
        sbc #60                 ; A = D
        
        ; Calculate low byte (D << 2)
        asl @
        asl @
        sta BIRD_DX_FRAC
        
        ; Calculate high byte (D >> 6)
        lda BIRD_X
        sec
        sbc #60
        lsr @
        lsr @
        lsr @
        lsr @
        lsr @
        lsr @
        sta BIRD_DX
        
        ; Ensure BIRD_DX_16 is at least 0.5 pixels/frame (0.5 * 256 = 128 frac)
        lda BIRD_DX
        bne @spawn_done
        lda BIRD_DX_FRAC
        cmp #128
        bcs @spawn_done
        mva #128 BIRD_DX_FRAC   ; Set minimum speed to 0.5 pixels/frame
        
@spawn_done
        mva #0 BIRD_FRAME
        mva #6 BIRD_ANIM_T
        
        ; Reset spawn timer to 750 frames (approx 15 seconds at 50Hz)
        mva #<750 BIRD_SPAWN_LO
        mva #>750 BIRD_SPAWN_HI
        
@exit_bird
        rts
        
@process_active_bird
        ; --- Update Animation Frame ---
        dec BIRD_ANIM_T
        bne @no_anim_toggle
        mva #6 BIRD_ANIM_T      ; Toggle frame every 6 frames
        inc BIRD_FRAME
        lda BIRD_FRAME
        cmp #3
        bcc @frame_ok
        mva #0 BIRD_FRAME
@frame_ok
        
@no_anim_toggle
        ; --- Move Bird ---
        ; Head left (subtract DX fixed-point from X)
        lda BIRD_X_FRAC
        sec
        sbc BIRD_DX_FRAC
        sta BIRD_X_FRAC
        lda BIRD_X
        sbc BIRD_DX
        sta BIRD_X
        
        ; Head down (add DY fixed-point to Y)
        lda BIRD_Y_FRAC
        clc
        adc BIRD_DY_FRAC
        sta BIRD_Y_FRAC
        lda BIRD_Y
        adc BIRD_DY
        sta BIRD_Y
        
        ; --- Check Boundaries ---
        ; If bird goes off-screen left (X < 48)
        lda BIRD_X
        cmp #48
        bcc @deactivate_bird
        
        ; If bird goes off-screen bottom (Y > 110)
        lda BIRD_Y
        cmp #110
        bcs @deactivate_bird
        rts
        
@deactivate_bird
        mva #0 BIRD_ACTIVE
        sta HPOSP2              ; Hide bird sprite
        rts

.endp
