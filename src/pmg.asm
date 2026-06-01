; ============================================================
; src/pmg.asm - PMG init, actor/missile drawing & collisions
; ============================================================

.proc pmg

; ------------------------------------------------------------
; pmg.init
; Clears PMG buffers and configures hardware registers
; ------------------------------------------------------------
init
        ; --- Clear PMG memory area (1 KB: $4000-$43FF) ---
        lda #$00
        sta $80
        mva #$40 $81
        ldx #$04
        ldy #$00
        lda #$00        ; Reload accumulator with zero
@clear_pmg_loop
        sta ($80),y
        iny
        bne @clear_pmg_loop
        inc $81
        dex
        bne @clear_pmg_loop

        ; --- PMG Hardware Registers configuration ---
        mva #$40 PMBASE  ; Base memory location for PMG ($4000)
        mva #$2E SDMCTL  ; Enable Player-Missile DMA (shadow register)
        mva #$03 GRACTL  ; Enable players and missiles in GTIA
        mva #$01 GPRIOR  ; Set priority (players in front of background)

        ; --- Missile sizing configuration ---
        mva #%00000101 SIZEM ; Double width for Missile 0 and Missile 1
        mva #0 HPOSP2        ; Hide Tree 0
        sta HPOSP3           ; Hide Tree 1
        mva #$FF HITCLR      ; Wiping out all stale hardware collision latches
        rts


; ------------------------------------------------------------
; pmg.update_missiles
; Handles movement, boundary checking and rendering of missiles
; ------------------------------------------------------------
update_missiles
        ; --- Clear whole missile buffer in PMG RAM ($4180-$41FF, 128 bytes) ---
        ldy #127
        lda #0
@clear_missiles_loop
        sta $4180,y
        dey
        bpl @clear_missiles_loop

        ; --- Process Missile 0 (Left Cowboy's projectile) ---
        lda M0_ACTIVE
        beq @hide_m0
        
        lda M0_X
        clc
        adc #3                  ; Speed of missile = 3
        sta M0_X
        cmp #208                ; Check if out of bounds (right edge)
        bcc @draw_m0
        
        mva #0 M0_ACTIVE        ; Deactivate missile 0
        sta HPOSM0
        jmp @check_m1

@draw_m0
        ldx M0_Y
        lda #%00000011          ; Missile 0 bits in PMG memory (bits 0-1)
        sta $4180,x
        sta $4181,x             ; Draw 2 pixels high vertical line
        mva M0_X HPOSM0
        jmp @check_m1

@hide_m0
        mva #0 HPOSM0

@check_m1
        ; --- Process Missile 1 (Right Cowboy's projectile) ---
        lda M1_ACTIVE
        beq @hide_m1
        
        lda M1_X
        sec
        sbc #3                  ; Speed of missile = 3
        sta M1_X
        cmp #48                 ; Check if out of bounds (left edge)
        bcs @draw_m1
        
        mva #0 M1_ACTIVE        ; Deactivate missile 1
        sta HPOSM1
        rts

@draw_m1
        ldx M1_Y
        lda #%00001100          ; Missile 1 bits in PMG memory (bits 2-3)
        sta $4180,x
        sta $4181,x             ; Draw 2 pixels high vertical line
        mva M1_X HPOSM1
        rts

@hide_m1
        mva #0 HPOSM1
        rts


; ------------------------------------------------------------
; pmg.check_collisions
; Queries hardware registers and triggers damage state
; ------------------------------------------------------------
; ------------------------------------------------------------
; pmg.check_missile_tree_collision
; Input: A = Missile Y, X = Missile X
; Output: Carry set if collision detected, Carry clear if not.
; ------------------------------------------------------------
check_missile_tree_collision
        sta ones_temp           ; ones_temp = Missile Y
        stx temp_x              ; temp_x = Missile X
        
        ; --- Check Tree 0 ---
        lda ones_temp
        clc
        adc #1                  ; Adjust for missile height (2 units)
        cmp TREE_Y_0
        bcc @check_t1
        sec
        sbc TREE_Y_0
        cmp #6                  ; Allow 6 units of vertical overlap (Missile 2 + Tree 4 + 1 tolerance)
        bcs @check_t1
        
        lda temp_x              ; Missile X
        cmp TREE_X_0
        bcc @check_t1
        sec
        sbc TREE_X_0
        cmp #6                  ; Tree width with tolerance (allows 0 to 5 clocks difference)
        bcs @check_t1
        
        sec                     ; Collision!
        rts

@check_t1
        ; --- Check Tree 1 ---
        lda ones_temp
        clc
        adc #1
        cmp TREE_Y_1
        bcc @check_t2
        sec
        sbc TREE_Y_1
        cmp #6
        bcs @check_t2
        
        lda temp_x
        cmp TREE_X_1
        bcc @check_t2
        sec
        sbc TREE_X_1
        cmp #6
        bcs @check_t2
        
        sec
        rts

@check_t2
        ; --- Check Tree 2 ---
        lda ones_temp
        clc
        adc #1
        cmp TREE_Y_2
        bcc @check_t3
        sec
        sbc TREE_Y_2
        cmp #6
        bcs @check_t2_no
        
        lda temp_x
        cmp TREE_X_2
        bcc @check_t2_no
        sec
        sbc TREE_X_2
        cmp #6
        bcs @check_t2_no
        
        sec
        rts
@check_t2_no

@check_t3
        ; --- Check Tree 3 ---
        lda ones_temp
        clc
        adc #1
        cmp TREE_Y_3
        bcc @no_collision
        sec
        sbc TREE_Y_3
        cmp #6
        bcs @no_collision
        
        lda temp_x
        cmp TREE_X_3
        bcc @no_collision
        sec
        sbc TREE_X_3
        cmp #6
        bcs @no_collision
        
        sec
        rts

@no_collision
        clc
        rts


; ------------------------------------------------------------
; pmg.check_collisions
; Software-based tree check and hardware-based cowboy hit check
; ------------------------------------------------------------
check_collisions
        ; --- Check Missile 0 collision with Playfield (Trees) ---
        lda M0_ACTIVE
        beq @check_c0_hit
        
        lda M0PF                ; Read Missile 0 to Playfield collision register
        and #$07                ; Mask for COLPF0, COLPF1, COLPF2 (playfield layers)
        beq @check_c1_cowboy_hit
        
        ; Hit a tree! Find which tree was hit and handle damage
        mva M0_X temp_x
        mva M0_Y ones_temp
        jsr damage_tree_at_coords

        ; Hit a tree! Destroy projectile 0 cleanly
        mva #0 M0_ACTIVE
        sta HPOSM0
        jmp @check_c0_hit

@check_c1_cowboy_hit
        lda M0PL                ; Read Missile-to-Player collision register
        and #$02                ; Bit 1 = Player 1 hit
        beq @check_c0_hit
        
        ; Trigger Hit Cowboy 1
        mva #0 M0_ACTIVE
        sta HPOSM0
        mva #15 HIT_1           ; Flash for 15 frames
        mva #15 SND_HIT         ; Play hit sound for 15 frames
        
        inc SCORE_0             ; Increment Player score
        jsr graphics.update_score_display ; Update score display on screen line 1

@check_c0_hit
        ; --- Check Missile 1 collision with Playfield (Trees) ---
        lda M1_ACTIVE
        beq @check_bird_hit
        
        lda M1PF                ; Read Missile 1 to Playfield collision register
        and #$07                ; Mask for COLPF0, COLPF1, COLPF2
        beq @check_c0_cowboy_hit
        
        ; Hit a tree! Find which tree was hit and handle damage
        mva M1_X temp_x
        mva M1_Y ones_temp
        jsr damage_tree_at_coords

        ; Hit a tree! Destroy projectile 1 cleanly
        mva #0 M1_ACTIVE
        sta HPOSM1
        jmp @check_bird_hit

@check_c0_cowboy_hit
        lda M1PL                ; Read Missile-to-Player collision register
        and #$01                ; Bit 0 = Player 0 hit
        beq @check_bird_hit
        
        ; Trigger Hit Cowboy 0
        mva #0 M1_ACTIVE
        sta HPOSM1
        mva #15 HIT_0           ; Flash for 15 frames
        mva #15 SND_HIT         ; Play hit sound for 15 frames

        inc SCORE_1             ; Increment AI score
        jsr graphics.update_score_display ; Update score display on screen line 1

        ; --- Game Over Condition Check: AI reaches 10 points ---
        lda SCORE_1
        cmp #10
        bne @check_bird_hit
        
        ; Trigger Game Over state and return to Attract Mode
        mva #0 GAME_STATE
        jsr graphics.set_game_over_text
        mva #$00 COLOR4         ; Black border
        mva #0 M0_ACTIVE        ; Hide/reset active missiles
        sta M1_ACTIVE
        sta HPOSM0
        sta HPOSM1
        
        ; Restore normal player colors immediately
        mva #$2A PCOLR0
        mva #$86 PCOLR1
        mva #0 HIT_0
        sta HIT_1
        
        jmp @exit_collisions

@check_bird_hit
        ; --- Check Bird (Player 2) collision with Cowboy 0 (Player 0) ---
        lda BIRD_ACTIVE
        beq @exit_collisions
        
        lda P2PL                ; Read hardware Player 2 to Player collision register
        and #$01                ; Bit 0 = Player 0 (Cowboy 0)
        beq @exit_collisions
        
        ; Collision! Bird successfully hit Player 0!
        mva #0 BIRD_ACTIVE      ; Deactivate bird
        sta HPOSP2              ; Hide bird sprite
        
        mva #15 HIT_0           ; Flash player
        mva #15 SND_HIT         ; Play hit sound
        inc SCORE_1             ; AI gets a point!
        jsr graphics.update_score_display
        
        ; --- Instant Game Over upon bird contact ---
        mva #0 GAME_STATE
        jsr graphics.set_game_over_text
        mva #$00 COLOR4         ; Black border
        mva #0 M0_ACTIVE        ; Hide/reset active missiles
        sta M1_ACTIVE
        sta HPOSM0
        sta HPOSM1
        
        ; Restore normal player colors immediately
        mva #$2A PCOLR0
        mva #$86 PCOLR1
        mva #0 HIT_0
        sta HIT_1

@exit_collisions
        mva #$FF HITCLR         ; Clear all hardware collision flags for next frame
        rts




; ------------------------------------------------------------
; pmg.draw_actors
; Updates PMG memory patterns and positions for player sprites
; ------------------------------------------------------------
draw_actors
        ; --- Clear Player 0, Player 1 and Player 2 PMG buffers (128 bytes each) ---
        ldy #127
        lda #0
@clear_actors_loop
        sta $4200,y
        sta $4280,y
        sta $4300,y             ; Clear Player 2 RAM (Bird)
        dey
        bpl @clear_actors_loop

        ; --- Draw Cowboy 0 (Player 0 under $4200) ---
        lda Y_POS_0
        sec
        sbc #1                  ; Adjust for top empty margin padding byte
        sta $80
        mva #$42 $81
        ldy #0
@copy_c0_loop
        lda cowboy0_shape,y
        sta ($80),y
        iny
        cpy #17                 ; Copy all 17 pattern bytes
        bne @copy_c0_loop

        mva #60 HPOSP0          ; Cowboy 0 static horizontal offset (60)

        ; --- Draw Cowboy 1 (Player 1 under $4280) ---
        lda Y_POS_1
        sec
        sbc #1                  ; Adjust for top margin
        clc
        adc #$80                ; Add Player 1 offset ($80 bytes from $4200 base)
        sta $80
        mva #$42 $81
        adc #0                  ; Handle high byte page carry if necessary
        sta $81
        ldy #0
@copy_c1_loop
        lda cowboy1_shape,y
        sta ($80),y
        iny
        cpy #17                 ; Copy all 17 pattern bytes
        bne @copy_c1_loop

        mva #196 HPOSP1         ; Cowboy 1 static horizontal offset (196)

        ; --- Draw Bird (Player 2 under $4300) if active ---
        lda BIRD_ACTIVE
        beq @hide_bird
        
        lda BIRD_Y
        sec
        sbc #1                  ; Adjust for top margin
        sta $80
        mva #$43 $81            ; Player 2 buffer is at $4300
        
        lda BIRD_FRAME
        beq @draw_frame_0
        cmp #1
        beq @draw_frame_1
        
        ; Draw bird_shape_2
        ldy #0
@copy_b2_loop
        lda bird_shape_2,y
        sta ($80),y
        iny
        cpy #6
        bne @copy_b2_loop
        jmp @apply_bird_x
        
@draw_frame_0
        ldy #0
@copy_b0_loop
        lda bird_shape_0,y
        sta ($80),y
        iny
        cpy #6                  ; Height of bird shape is 6 bytes
        bne @copy_b0_loop
        jmp @apply_bird_x
        
@draw_frame_1
        ldy #0
@copy_b1_loop
        lda bird_shape_1,y
        sta ($80),y
        iny
        cpy #6
        bne @copy_b1_loop
        
@apply_bird_x
        mva BIRD_X HPOSP2
        rts
        
@hide_bird
        mva #0 HPOSP2
        rts

; ------------------------------------------------------------
; pmg.damage_tree_at_coords
; Input: temp_x = Missile X, ones_temp = Missile Y
; Checks all active trees and decrements the hit counter of the nearest matching tree.
; ------------------------------------------------------------
damage_tree_at_coords
        ldy #0                  ; Y = Tree Index (0 to 7)
@tree_loop
        tya
        asl @                   ; I * 2
        clc
        adc #$9E                ; Base ZP address for X
        tax                     ; X = ZP address of TREE_X_I
        
        lda $01,x               ; A = TREE_Y_I
        beq @next_tree          ; If 0, tree is inactive
        
        ; Check vertical Y proximity: |M_Y - TREE_Y_I| <= 12 (covers entire character and timing offsets)
        sec
        sbc ones_temp           ; TREE_Y_I - M_Y
        bpl @y_diff_ok
        eor #$FF
        clc
        adc #1                  ; Absolute value
@y_diff_ok
        cmp #12
        bcs @next_tree          ; Too far vertically
        
        ; Check horizontal X proximity: |M_X - TREE_X_I| <= 10
        lda $00,x               ; A = TREE_X_I
        sec
        sbc temp_x              ; TREE_X_I - M_X
        bpl @x_diff_ok
        eor #$FF
        clc
        adc #1                  ; Absolute value
@x_diff_ok
        cmp #10
        bcs @next_tree          ; Too far horizontally
        
        tya
        tax
        dec tree_hits,x
        bne @tree_damaged       ; If hits remaining > 0, exit
        
        ; Tree destroyed! Erase it from screen and memory!
        jsr erase_tree
        
@tree_damaged
        rts                     ; processed the hit, exit
        
@next_tree
        iny
        cpy #8
        bcc @tree_loop
        rts


; ------------------------------------------------------------
; pmg.erase_tree
; Input: Y = tree index (0 to 4)
; Erases the tree character from screen RAM and clears ZP coordinates to 0.
; ------------------------------------------------------------
erase_tree
        tya
        pha                     ; Save tree index Y on stack
        
        ; Get ZP address for Tree Y
        tya
        asl @
        clc
        adc #$9E
        tax                     ; X = ZP address of TREE_X_Y
        
        ; Calculate C_plot = (TREE_X_Y - 48) / 4 + 8
        lda $00,x               ; TREE_X_Y
        sec
        sbc #48
        lsr @                   ; / 2
        lsr @                   ; / 4
        clc
        adc #8                  ; C_plot
        pha                     ; Save C_plot
        
        ; Calculate L = (TREE_Y_Y - 12) / 4
        lda $01,x               ; TREE_Y_Y
        sec
        sbc #12
        lsr @
        lsr @                   ; L
        
        ; Call graphics.plot_space_char to write space character ($00) at L (Y) and C_plot (X)
        tay                     ; Y = L
        pla                     ; Retrieve C_plot
        tax                     ; X = C_plot
        jsr graphics.plot_space_char
        
        ; Clear the tree's ZP coordinates to 0 so it's inactive!
        pla                     ; Retrieve tree index Y from stack
        tay
        tya
        asl @
        clc
        adc #$9E
        tax
        mva #0 $00,x            ; TREE_X_Y = 0
        sta $01,x               ; TREE_Y_Y = 0
        rts

.endp


; ============================================================
; PMG BITMAP PATTERNS
; ============================================================

cowboy0_shape
        .byte 0
        .byte %00011100  ; Hat top
        .byte %00111110  ; Hat middle
        .byte %01111111  ; Hat brim
        .byte %00011110  ; Head
        .byte %00011000  ; Neck
        .byte %00011100  ; Torso
        .byte %00111110  ; Arm
        .byte %00011111  ; Gun barrel pointing right
        .byte %00011100  ; Belt
        .byte %00011110  ; Holster
        .byte %00011100  ; Legs
        .byte %00011100  ; Legs
        .byte %00010100  ; Legs
        .byte %00010100  ; Legs
        .byte %00110110  ; Boots
        .byte 0

cowboy1_shape
        .byte 0
        .byte %00111000  ; Hat top
        .byte %01111100  ; Hat middle
        .byte %11111110  ; Hat brim
        .byte %01111000  ; Head
        .byte %00011000  ; Neck
        .byte %00111000  ; Torso
        .byte %01111100  ; Arm
        .byte %11111000  ; Gun barrel pointing left
        .byte %00111000  ; Belt
        .byte %01111000  ; Holster
        .byte %00111000  ; Legs
        .byte %00111000  ; Legs
        .byte %00101000  ; Legs
        .byte %00101000  ; Legs
        .byte %01101100  ; Boots
        .byte 0

; --- Wings Up animation frame shape (6 bytes) ---
bird_shape_0
        .byte %00010000  ;    *    (wing tip up)
        .byte %00111000  ;   ***   (wing up)
        .byte %11111110  ; ******* (beak, head, body, tail)
        .byte %00011000  ;    **   (lower body)
        .byte 0
        .byte 0

; --- Wings Horizontal transition animation frame shape (6 bytes) ---
bird_shape_1
        .byte 0
        .byte %01111000  ;  ****   (wing horizontal)
        .byte %11111110  ; ******* (beak, head, body, tail)
        .byte %00011000  ;    **   (lower body)
        .byte 0
        .byte 0

; --- Wings Down animation frame shape (6 bytes) ---
bird_shape_2
        .byte 0
        .byte %00011000  ;    **   (upper body)
        .byte %11111110  ; ******* (beak, head, body, tail)
        .byte %00111000  ;   ***   (wing down)
        .byte %00010000  ;    *    (wing tip down)
        .byte 0
