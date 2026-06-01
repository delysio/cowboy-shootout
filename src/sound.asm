; ============================================================
; src/sound.asm - POKEY audio synthesis for shots/explosions
; ============================================================

.proc sound

; ------------------------------------------------------------
; sound.init
; Resets POKEY audio channels
; ------------------------------------------------------------
init
        mva #$00 AUDCTL
        sta AUDC1
        sta AUDC2
        rts


; ------------------------------------------------------------
; sound.play
; Processes active sound timers and updates POKEY registers
; ------------------------------------------------------------
play
        ; --- Process Shoot Sound ---
        lda SND_SHOT
        beq @silence_shot
        dec SND_SHOT
        lda SND_SHOT
        beq @silence_shot

        ; Calculate frequency sweep (shifting frequency)
        asl
        asl
        sta AUDF1
        lda SND_SHOT
        ora #$A0                ; Pure tone (distortion A) + dynamic volume
        sta AUDC1
        jmp @play_hit_sound

@silence_shot
        mva #0 AUDC1

@play_hit_sound
        ; --- Process Hit (Explosion) Sound ---
        lda SND_HIT
        beq @silence_hit
        dec SND_HIT
        lda SND_HIT
        beq @silence_hit

        lda RANDOM              ; Random frequency for noise explosion
        sta AUDF2
        lda SND_HIT
        ora #$20                ; Noise distortion + dynamic volume
        sta AUDC2
        rts

@silence_hit
        mva #0 AUDC2
        rts

.endp
