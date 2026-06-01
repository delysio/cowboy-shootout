; ============================================================
; src/graphics.asm - Display List, screen setup & scrolling
; ============================================================

.proc graphics

; ------------------------------------------------------------
; graphics.init_screen
; Clears screen RAM and initializes scroll buffer and offsets
; ------------------------------------------------------------
init_screen
        ; --- Set Display List ---
        mwa #display_list SDLSTL

        ; --- Clear Screen RAM ($3000, 4 pages = 1KB) with spaces ($00) ---
        lda #$00
        sta $80
        mva #$30 $81
        ldx #$04
        ldy #$00
        lda #$00        ; Reload accumulator with space ($00)
@clear_screen_loop
        sta ($80),y
        iny
        bne @clear_screen_loop
        inc $81
        dex
        bne @clear_screen_loop

        ; --- Initialize Scroll Buffer with spaces ($00) ---
        ldy #SCROLL_BUF_LEN-1
        lda #$00
@fill_scroll_buf
        sta scroll_buf,y
        dey
        cpy #$FF
        bne @fill_scroll_buf

        ; --- Copy static title text to the scroll buffer pad ---
        ldy #0
@copy_text_loop
        lda title_text,y
        sta scroll_buf+SCROLL_PAD,y
        iny
        cpy #TITLE_LEN
        bne @copy_text_loop

        ; --- Initialize scrolling offsets and registers ---
        mva #0 SCROLL_X
        mva #1 SCROLL_DIR
        mva #3 FINE_X
        rts


; ------------------------------------------------------------
; graphics.update_scroller
; Moves the scroller window and copies text to screen RAM
; ------------------------------------------------------------
update_scroller
        ; --- Check scrolling direction ---
        lda SCROLL_DIR
        cmp #1
        bne @scroll_right

        ; --- Move Left ---
        dec FINE_X
        bpl @scroll_apply        ; If fine-scroll >= 0, apply scroll
        mva #3 FINE_X            ; Reset fine-scroll to 3
        inc SCROLL_X            ; Shift text window by 1 character
        lda SCROLL_X
        cmp #SCROLL_MAX+1
        bcc @scroll_apply
        
        mva #$FF SCROLL_DIR      ; Reverse direction to move right
        mva #0 FINE_X
        mva #SCROLL_MAX SCROLL_X
        jmp @scroll_apply

@scroll_right
        ; --- Move Right ---
        inc FINE_X
        lda FINE_X
        cmp #4
        bcc @scroll_apply
        
        mva #0 FINE_X            ; Reset fine-scroll to 0
        dec SCROLL_X            ; Shift text window back by 1 character
        lda SCROLL_X
        bpl @scroll_apply
        
        mva #1 SCROLL_DIR        ; Reverse direction to move left
        mva #3 FINE_X
        mva #0 SCROLL_X

@scroll_apply
        ; --- Apply hardware scrolling value ---
        mva FINE_X HSCROL

        ; --- Copy active 48-character window from scroll_buf to screen_ram+40 ---
        ldx SCROLL_X            ; X = Source scroll_buf index
        ldy #0                  ; Y = Destination screen_ram+40 index
@copy_loop
        lda scroll_buf,x
        sta screen_ram+40,y
        inx
        iny
        cpy #48
        bne @copy_loop
        rts


; ------------------------------------------------------------
; graphics.set_play_text
; Copies play_text into scroll buffer and resets scroll offsets
; ------------------------------------------------------------
set_play_text
        ldy #0
@copy_play_loop
        lda play_text,y
        sta scroll_buf+SCROLL_PAD,y
        iny
        cpy #TITLE_LEN
        bne @copy_play_loop

        mva #0 SCROLL_X
        mva #1 SCROLL_DIR
        mva #3 FINE_X
        rts


; ------------------------------------------------------------
; graphics.init_score
; Copies the initial score header text to the first screen line
; ------------------------------------------------------------
init_score
        ldy #39
@copy_header_loop
        lda score_header_text,y
        sta screen_ram,y
        dey
        bpl @copy_header_loop
        rts

; ------------------------------------------------------------
; graphics.update_score_display
; Converts SCORE_0 and SCORE_1 to decimal digits and updates screen RAM
; ------------------------------------------------------------
update_score_display
        ; --- Convert SCORE_0 (Player) ---
        lda SCORE_0
        jsr bin_to_dec
        txa
        clc
        adc #$10                ; Add screen code offset for digits '0'-'9'
        sta screen_ram+12       ; Tens digit position
        lda ones_temp
        clc
        adc #$10
        sta screen_ram+13       ; Ones digit position

        ; --- Convert SCORE_1 (AI) ---
        lda SCORE_1
        jsr bin_to_dec
        txa
        clc
        adc #$10
        sta screen_ram+33       ; Tens digit position
        lda ones_temp
        clc
        adc #$10
        sta screen_ram+34       ; Ones digit position
        rts
; Helper subroutines

bin_to_dec
        ldx #0
@dec_loop
        cmp #10
        bcc @dec_done
        sec
        sbc #10
        inx
        jmp @dec_loop
@dec_done
        sta ones_temp
        rts

score_header_text
        dta d'    PLAYER: 00               AI: 00     '

; ------------------------------------------------------------
; graphics.set_game_over_text
; Copies game_over_text into scroll buffer and resets scroll offsets
; ------------------------------------------------------------
set_game_over_text
        ldy #0
@copy_game_over_loop
        lda game_over_text,y
        sta scroll_buf+SCROLL_PAD,y
        iny
        cpy #TITLE_LEN
        bne @copy_game_over_loop

        mva #0 SCROLL_X
        mva #1 SCROLL_DIR
        mva #3 FINE_X
        rts

; ------------------------------------------------------------
; graphics.pick_random_message
; Picks a random message (0-9) using hardware RANDOM, copies it
; to the scroll buffer, and resets scrolling offsets.
; ------------------------------------------------------------
pick_random_message
        lda RANDOM
@mod_loop
        cmp #10
        bcc @got_index
        sec
        sbc #10
        jmp @mod_loop
@got_index
        ; Index (0-9) is in A.
        ; Calculate source pointer: play_messages + index * 43
        ; We store the 16-bit address in zero page $80-$81 (free ZP scratch)
        tay                     ; Preserve index in Y IMMEDIATELY before overwriting A
        
        ; Start with the base address of play_messages
        lda #<play_messages
        sta $80
        lda #>play_messages
        sta $81
        
        ; If index is 0, we are ready
        cpy #0
        beq @pointer_ready
        
@mult_loop
        lda $80
        clc
        adc #43                 ; Add size of one message
        sta $80
        lda $81
        adc #0
        sta $81
        dey
        bne @mult_loop
        
@pointer_ready
        ; Now ($80) points to the selected message
        ; Copy 43 bytes to scroll_buf+SCROLL_PAD
        ldy #0
@copy_msg_loop
        lda ($80),y
        sta scroll_buf+SCROLL_PAD,y
        iny
        cpy #TITLE_LEN          ; 43
        bne @copy_msg_loop
        
        mva #0 SCROLL_X
        mva #1 SCROLL_DIR
        mva #3 FINE_X
        rts


; ------------------------------------------------------------
; graphics.generate_trees
; Generates 4 random tree obstacles plotted in screen RAM as character 'Y'
; and sets their pixel-based ZP coordinates.
; ------------------------------------------------------------
generate_trees
        ; Initialize all 8 tree hit counters to 3
        lda #3
        ldy #7
@init_hits_loop
        sta tree_hits,y
        dey
        bpl @init_hits_loop

        ; Clear remaining tree slots 5, 6, 7 so they are inactive
        lda #0
        sta TREE_X_5
        sta TREE_Y_5
        sta TREE_X_6
        sta TREE_Y_6
        sta TREE_X_7
        sta TREE_Y_7

        ldx #TREE_X_0
        ldy #TREE_Y_0
        jsr generate_and_plot_tree
        
        ldx #TREE_X_1
        ldy #TREE_Y_1
        jsr generate_and_plot_tree
        
        ldx #TREE_X_2
        ldy #TREE_Y_2
        jsr generate_and_plot_tree
        
        ldx #TREE_X_3
        ldy #TREE_Y_3
        jsr generate_and_plot_tree
        
        ldx #TREE_X_4
        ldy #TREE_Y_4
        jsr generate_and_plot_tree
        rts

; Helper to generate and plot one tree at ZP addresses in X and Y
; Input: X = ZP address of TREE_X_n, Y = ZP address of TREE_Y_n
generate_and_plot_tree
        stx $80                 ; Save TREE_X_n address in ZP $80
        sty $81                 ; Save TREE_Y_n address in ZP $81
        
        ; 1. Generate column C_plot in [23, 33] (size 11)
        lda #11
        jsr get_random_mod
        clc
        adc #23                 ; C_plot is in [23, 33]
        pha                     ; Save C_plot on stack
        
        ; Calculate C_actual = C_plot - 8
        sec
        sbc #8
        
        ; Calculate TREE_X = C_actual * 4 + 48
        asl @                   ; C_actual * 2
        asl @                   ; C_actual * 4
        clc
        adc #48
        ldx $80
        sta $00,x               ; Write to TREE_X_n
        
        ; 2. Generate line L in [5, 20] (size 16)
        lda RANDOM
        and #$0F                ; L offset in 0-15
        clc
        adc #5                  ; L is in [5, 20]
        pha                     ; Save L
        
        ; Calculate TREE_Y = L * 4 + 12
        asl @                   ; L * 2
        asl @                   ; L * 4
        clc
        adc #12
        ldx $81
        sta $00,x               ; Write to TREE_Y_n
        
        ; 3. Plot tree char 'Y'
        pla                     ; Retrieve L
        tay                     ; Y = L
        pla                     ; Retrieve C
        tax                     ; X = C
        jsr plot_tree_char
        rts

; Helper to get RANDOM mod N
; Input: A = N
; Output: A = random number in [0, N-1]
get_random_mod
        sta temp_x
        lda RANDOM
@random_mod_loop
        cmp temp_x
        bcc @random_done
        sec
        sbc temp_x
        jmp @random_mod_loop
@random_done
        rts

; Helper to plot tree character 'Y' (screen code $39) at Line L (Y) and Column C (X)
plot_tree_char
        sty $80                 ; Save L in $80
        
        ; Add 40 in a loop L times to get screen_ram + L * 40
        lda #<screen_ram
        sta $80
        lda #>screen_ram
        sta $81
        
        cpy #0
        beq @add_c
@loop_mul
        lda $80
        clc
        adc #40
        sta $80
        lda $81
        adc #0
        sta $81
        dey
        bne @loop_mul
@add_c
        txa
        clc
        adc $80
        sta $80
        lda $81
        adc #0
        sta $81
        
        ; Write screen code $7B (ATASCII 123)
        lda #$7B
        ldy #0
        sta ($80),y
        rts

; Helper to plot space character ' ' (screen code $00) at Line L (Y) and Column C (X)
plot_space_char
        sty $80                 ; Save L in $80
        
        ; Add 40 in a loop L times to get screen_ram + L * 40
        lda #<screen_ram
        sta $80
        lda #>screen_ram
        sta $81
        
        cpy #0
        beq ?add_c
?loop_mul
        lda $80
        clc
        adc #40
        sta $80
        lda $81
        adc #0
        sta $81
        dey
        bne ?loop_mul
?add_c
        txa
        clc
        adc $80
        sta $80
        lda $81
        adc #0
        sta $81
        
        ; Write space character ($00)
        lda #$00
        ldy #0
        sta ($80),y
        rts


; ------------------------------------------------------------
; graphics.update_tree_spawn
; Decrements tree_spawn_timer and spawns a new tree in any empty slot
; ------------------------------------------------------------
update_tree_spawn
        lda GAME_STATE
        bne ?continue_spawn
        rts                     ; Exit early if game is not active
        
?continue_spawn
        ; Decrement spawn timer (2-byte)
        lda tree_spawn_timer
        sec
        sbc #1
        sta tree_spawn_timer
        lda tree_spawn_timer+1
        sbc #0
        sta tree_spawn_timer+1
        
        ; Check if timer reached 0
        ora tree_spawn_timer
        beq ?do_spawn
        rts                     ; Not 0, exit
        
?do_spawn
        ; Reset timer to 150 frames (3 seconds)
        mva #<150 tree_spawn_timer
        mva #>150 tree_spawn_timer+1
        
        ; 1. Count active trees (never exceed 8)
        ldy #0                  ; Y = active tree count
        ldx #0                  ; X = slot index
?count_active_loop
        txa
        pha
        asl @
        clc
        adc #$9E
        tax
        lda $01,x               ; TREE_Y_I
        beq ?inactive_tree
        iny                     ; active count++
?inactive_tree
        pla
        tax
        inx
        cpx #8
        bcc ?count_active_loop
        
        cpy #8
        bcs ?no_spawn_possible  ; If 8 or more trees active, do not spawn!
        
        ; 2. Find an empty tree slot (Y_I == 0)
        ldy #0                  ; Y = slot index (0 to 7)
?find_slot_loop
        tya
        asl @
        clc
        adc #$9E                ; ZP address for X_I
        tax
        lda $01,x               ; TREE_Y_I
        beq ?found_empty_slot
        
        iny
        cpy #8
        bcc ?find_slot_loop
?no_spawn_possible
        rts                     ; All slots full or 8 trees active
        
?found_empty_slot
        ; Slot index is in Y. Save it
        sty ones_temp           ; ones_temp = slot index
        
?generate_coords
        ; 1. Generate column C_plot in [23, 33] (size 11)
        lda #11
        jsr get_random_mod
        clc
        adc #23                 ; C_plot is in [23, 33]
        sta new_tree_c
        
        ; Calculate C_actual = C_plot - 8
        sec
        sbc #8
        
        ; Calculate new_TREE_X = C_actual * 4 + 48
        asl @                   ; C_actual * 2
        asl @                   ; C_actual * 4
        clc
        adc #48
        sta new_tree_x
        
        ; 2. Generate line L in [5, 20] (size 16)
        lda RANDOM
        and #$0F
        clc
        adc #5                  ; L is in [5, 20]
        sta new_tree_l
        
        ; Calculate new_TREE_Y = L * 4 + 12
        asl @                   ; L * 2
        asl @                   ; L * 4
        clc
        adc #12
        sta new_tree_y
        
        ; 3. Check if occupied by any other active tree J != slot_index
        ldy #0                  ; Y = other tree index (0 to 7)
?check_occupied_loop
        cpy ones_temp
        beq ?next_occupied_check ; Skip check against itself
        
        tya
        asl @
        clc
        adc #$9E
        tax                     ; X = ZP address of TREE_X_J
        
        lda $01,x               ; TREE_Y_J
        beq ?next_occupied_check ; If inactive, skip
        
        ; Compare TREE_Y_J with new_tree_y
        cmp new_tree_y
        bne ?next_occupied_check
        
        ; Compare TREE_X_J with new_tree_x
        lda $00,x
        cmp new_tree_x
        beq ?generate_coords    ; OCCUPIED! Try generating coordinates again!
        
?next_occupied_check
        iny
        cpy #8
        bcc ?check_occupied_loop
        
        ; Coordinates are unique! Set up the new tree in slot ones_temp
        ldy ones_temp           ; Y = slot index
        
        ; Set hits to 3
        mva #3 tree_hits,y
        
        ; Write ZP variables (recalculate ZP target dynamically from Y to avoid temp_x corruption)
        tya
        asl @
        clc
        adc #$9E
        tax
        mva new_tree_x $00,x
        mva new_tree_y $01,x
        
        ; Plot the new tree
        ldy new_tree_l
        ldx new_tree_c
        jsr plot_tree_char
        rts

.endp

; ============================================================
; DISPLAY LIST - ANTIC 2 (Graphics 0)
; ============================================================
display_list
        .byte $70, $70, $70         ; 24 blank lines (top border)
        .byte $42                   ; Line 1: ANTIC 2 + LMS
        .word screen_ram
        .byte $52                   ; Line 2: ANTIC 2 + LMS + HSCROL (scroller line)
        .word screen_ram+40
        .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2  ; Lines 3-24 (22 normal ANTIC 2 lines)
        .byte $41                   ; JVB (Jump and Wait for VBL)
        .word display_list
