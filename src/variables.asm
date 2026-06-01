; ============================================================
; src/variables.asm - RAM variables and buffers
; ============================================================

title_text
        dta d'   PRESS START TO PLAY - COWBOY SHOOTOUT   '

play_text
play_messages
        dta d'   * FIGHT! *  AVOID THE DEADLY BULLETS!   '
        dta d'   * KEEP GOING! *  YOU ARE DOING GREAT!   '
        dta d'   * DRAW FAST! *  THE AI IS GETTING MAD   '
        dta d'   * SHOW NO MERCY! *  DUEL TO THE DEATH   '
        dta d'   * DODGE THOSE SHOTS! *  STAY IN GAME!   '
        dta d'   * AWESOME PLAY! *  KEEP PUSHING HARD!   '
        dta d'   * VICTORY AWAITS! *  BECOME THE HERO!   '
        dta d'   * DUST AND BULLETS! *  WHO WILL WIN??   '
        dta d'   * UNSTOPPABLE! *  UNLEASH THE FURY!     '
        dta d'   * FOCUS! *  THE FINAL STAND IS HERE!    '

game_over_text
        dta d'   GAME OVER - PRESS START TO TRY AGAIN   '

scroll_buf
        .ds SCROLL_BUF_LEN

tree_hits
        .ds 8
tree_spawn_timer
        .ds 2
new_tree_x
        .ds 1
new_tree_y
        .ds 1
new_tree_l
        .ds 1
new_tree_c
        .ds 1

