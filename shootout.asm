; ============================================================
; Kompilacja: MADS (make.bat)
; Main Orchestrator & Coordinator
; ============================================================

        org $2000

; --- Include modular specifications ---
        icl 'src/constants.asm'
        icl 'src/variables.asm'
        icl 'src/graphics.asm'
        icl 'src/pmg.asm'
        icl 'src/cowboys.asm'
        icl 'src/sound.asm'

; ============================================================
; PROGRAM INITIALIZATION
; ============================================================
start
        sei                     ; Disable interrupts during setup

        ; --- Initialize game state ---
        mva #0 GAME_STATE
        mva #0 ATTRACT_TIMER
        mva #$FF CH             ; Clear keyboard shadow register on boot

        ; --- Initialize functional modules ---
        jsr pmg.init
        jsr sound.init
        jsr graphics.init_screen
        jsr cowboys.init

        ; --- Initialize OS Colors ---
        mva #$2A PCOLR0         ; Normal color of Cowboy 0 (gold/brown)
        mva #$86 PCOLR1         ; Normal color of Cowboy 1 (blue)
        mva #$1E PCOLR2         ; Yellow color for the Bird (Player 2)
        mva #$00 COLOR4         ; Black border (COLBK shadow)
        mva #$C4 COLOR2         ; Green playfield background (COLPF2 shadow)
        mva #$0F COLOR1         ; White letters (COLPF1 shadow)

        ; --- Use Standard Font from ROM ---
        mva #$E0 CHBAS
        sta CHBASE

        cli                     ; Re-enable interrupts

; ============================================================
; MAIN GAME LOOP
; ============================================================
main_loop
        ; --- Synchronize with VBLANK ---
        lda RTCLOK
wait_vbl
        cmp RTCLOK
        beq wait_vbl

        ; --- Check current game state ---
        lda GAME_STATE
        bne @playing_state

        ; === ATTRACT MODE INPUT CHECKS ===

        ; Increment frame counter every frame
        inc ATTRACT_TIMER

        ; Skip ALL input checks during first ~1 second (debounce)
        ; This prevents false triggers from boot-time register states
        lda ATTRACT_TIMER
        cmp #50
        bcc @attract_update     ; First 50 frames: skip input, just animate

        ; 1. Check START console key (Bit 2 of CONSOL register, active low)
        lda CONSOL
        and #$04                ; Mask for START key (Bit 2)
        beq @do_start           ; If START key pressed (0), start game!
        
        jmp @attract_update     ; START not pressed, continue attract mode

@do_start
        mva #$FF CH             ; Clear keyboard buffer to prevent stale key states
        ; --- Transition to playing mode ---
        mva #1 GAME_STATE
        jsr graphics.init_screen   ; Clear screen RAM completely to erase past trees/residue
        jsr cowboys.init        ; Reset cowboy positions and timers
        jsr pmg.init            ; Clean PMG memory area completely
        jsr graphics.generate_trees ; Generate dynamic tree obstacles plotted in screen RAM
        jsr graphics.init_score ; Display score header on line 1
        jsr graphics.update_score_display ; Update score numbers to 00
        
        ; Reset the 30-second scroller timer
        mva #0 SCROLLER_TIMER_LO
        sta SCROLLER_TIMER_HI
        
        jsr graphics.set_play_text ; Dynamically change scroller text to FIGHT!
        mva #12 SND_SHOT        ; Play a startup shot sound effect
        ; Border remains black always, no change to COLOR4

@attract_update
        ; In Attract Mode, only scroller, actors, and sounds are updated
        jsr graphics.update_scroller
        jsr cowboys.update
        jsr pmg.draw_actors
        jsr sound.play
        jmp main_loop

@playing_state
        ; --- Active Gameplay Mode ---
        jsr graphics.update_scroller
        jsr cowboys.update
        jsr cowboys.shoot
        jsr pmg.update_missiles
        jsr cowboys.update_bird   ; Handle bird spawning, movement, and animation states
        jsr graphics.update_tree_spawn ; Process dynamic tree regeneration every 10 seconds
        jsr pmg.check_collisions
        jsr cowboys.flash_colors
        jsr sound.play
        jsr pmg.draw_actors

        ; --- Update Scroller timer (every 30 seconds = 1500 frames at 50Hz) ---
        inc SCROLLER_TIMER_LO
        bne @no_timer_hi
        inc SCROLLER_TIMER_HI
@no_timer_hi
        lda SCROLLER_TIMER_LO
        cmp #<1500
        bne @timer_not_done
        lda SCROLLER_TIMER_HI
        cmp #>1500
        bne @timer_not_done
        
        ; Reset timer
        mva #0 SCROLLER_TIMER_LO
        sta SCROLLER_TIMER_HI
        
        ; Pick and swap dynamic motivational message
        jsr graphics.pick_random_message

@timer_not_done
        jmp main_loop

; ============================================================
; XEX LAUNCH SEGMENT
; ============================================================
        org $02E0
        .word start
