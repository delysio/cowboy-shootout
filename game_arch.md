# Atari 8-bit Modular Game Architecture
## Cowboy Shootout Technical Specification

This document details the modular architecture of the Cowboy Shootout game for the Atari 8-bit XL/XE. The monolithic original has been refactored into a highly structured, maintainable, and modern 6502 assembly codebase using the MADS assembler features (such as `.proc` blocks, `mva`/`mwa` macros, and file inclusion).

---

## 1. Architectural Goals
- **Modularity**: Separate independent concerns (constants, variables, screen scrolling, player-missile graphics, audio synthesis, and AI/actors logic) into dedicated modules.
- **Scope Safety**: Wrap functional subroutines and update steps inside MADS `.proc` blocks to isolate labels and variables, preventing namespace collisions.
- **Readability & Optimization**: Leverage MADS built-in macro commands (e.g., `mva`, `mwa`) to eliminate redundant load/store sequences, making the assembly clean and concise.
- **Build Cleanliness**: Maintain a clean workspace root. All code modules reside in a dedicated `src/` directory, while `shootout.asm` remains the central coordinator and build entry point.

---

## 2. Directory & Module Structure

The project structure is organized as follows:

```text
test_gemini/
│
├── game_arch.md              # This architecture specification
├── implementation_plan.md    # The step-by-step refactoring plan
├── make.bat                  # Standard build script compiling shootout.asm
├── shootout.asm              # Main orchestrator & compiler entry point
│
└── src/                      # Source modules folder
    ├── constants.asm         # Hardware registers, OS shadows, & ZP constants
    ├── variables.asm         # RAM allocations, text strings, and hit arrays
    ├── graphics.asm          # Display list, screen setup, scroller, & tree spawner
    ├── pmg.asm               # PMG init, actor/missile drawing, & collision handlers
    ├── sound.asm             # POKEY audio synthesis for shots/explosions
    └── cowboys.asm           # Cowboy state, bird hazard flight math, & AI loops
```

---

## 3. Module Specifications

### A. Core Coordinator (`shootout.asm`)
* **Purpose**: Includes all modules in the correct sequence, defines the program origin (`org $2000`), handles hardware initialization, and orchestrates the synchronized main game loop.
* **Attract Mode Input**: Checks the hardware `CONSOL` register (`$D01F`) exclusively for the **START switch (Bit 2)** to begin a game. All other keyboard, joystick, and Option/Select bypasses are removed.
* **Game State Machine**:
  * **Attract Mode (`GAME_STATE = 0`)**: Loops `graphics.update_scroller`, `cowboys.update` (running random automated title movements), `pmg.draw_actors`, and `sound.play`.
  * **Playing Mode (`GAME_STATE = 1`)**: Loops:
     * `graphics.update_scroller`
     * `cowboys.update` (manual player joysticks vs smart shooting AI)
     * `cowboys.shoot` (AI prediction line scans)
     * `pmg.update_missiles`
     * `cowboys.update_bird` (precision yellow bird swoop handler)
     * `graphics.update_tree_spawn` (dynamic shrub spawner running every 3 seconds)
     * `pmg.check_collisions` (hardware collision latches processing)
     * `cowboys.flash_colors`
     * `sound.play`
     * `pmg.draw_actors`

---

### B. Hardware & Constants (`src/constants.asm`)
* **Purpose**: Declarations of zero-page pointers, GTIA registers, POKEY registers, ANTIC registers, and OS shadow registers.
* **Key Zero-Page Layout ($82-$BC)**:
  * `$82-$9D`: Cowboy states, coordinates, scores, shot timers, and scroller coordinates.
  * `$9E-$AD`: Contiguous 8-Tree coordinate array (`TREE_X_0` to `TREE_Y_7` for up to 8 trees).
  * `$AE-$BA`: Bird Hazard registers (active state, fraction/integer coordinates, frame ticks, and 8.8 sub-pixel speeds).
  * `$BB-$BC`: Global scratchpads `ones_temp` and `temp_x` relocated to the end of the ZP block to prevent indexing collisions.

---

### C. Variables & Buffers (`src/variables.asm`)
* **Purpose**: Holds all variable tables, dynamically initialized buffers, and text assets.
* **Key Data Structures**:
  * `scroll_buf`: Padded buffer of size `SCROLL_BUF_LEN` containing the scrolling text.
  * `tree_hits`: 8-byte health counter array for the 8 active tree slots.
  * `tree_spawn_timer`: 2-byte countdown timer (150 frames = 3 seconds) for shrub regeneration.
  * `new_tree_x`/`y`/`l`/`c`: Temporary variables for the tree coordinate generator.
  * `title_text`, `play_messages`, `game_over_text`: Static ATASCII strings.

---

### D. Graphics & Scrolling (`src/graphics.asm`)
* **Purpose**: Configures the ANTIC display list, manages scroller text, and handles tree generation/spawning.
* **Procedures**:
  * `graphics.init_screen`: Clears screen memory ($3000) and initializes `scroll_buf` with padded text.
  * `graphics.update_scroller`: Performs fine scroll calculation, shifts characters, and updates hardware `HSCROL`.
  * `graphics.generate_trees`: Initializes all 8 hit counters to 3, clears slots 5-7 to 0, and plots the initial 5 trees.
  * `graphics.plot_tree_char` / `plot_space_char`: Plots character code `$7B` (ATASCII 123 - pixel art shrub) or `$00` (space) at screen coordinates.
  * `graphics.update_tree_spawn`: Count active trees on screen. If 8 trees are on screen, it aborts. Otherwise, it generates unique columns `[23, 33]` (visual `[15, 25]` at center) and lines `[5, 20]`, verifies no other tree overlaps, maps the ZP coordinates directly from the saved slot index to prevent divisor register corruption, and resets the 3-second (150 frames) timer.

---

### E. Player-Missile Graphics (`src/pmg.asm`)
* **Purpose**: Configures PMG memory maps, draws vertical player/missile slices, and handles collision math.
* **Procedures**:
  * `pmg.init`: Configures base pointer at `$4000`, priorities, double-line resolution, and clears buffers.
  * `pmg.update_missiles`: Updates horizontal positions, check limits, and draws vertical projectile pixels in PMG RAM.
  * `pmg.check_collisions`:
    * Intercepts `M0PF` and `M1PF` hardware Missile-to-Playfield collisions to trigger tree damage.
    * Intercepts `M0PL` and `M1PL` to trigger cowboy hits.
    * Intercepts `P2PL` (Player 2 to Player 0) hardware collision for bird contact, terminating the active game instantly, triggering the Game Over scroller, and launching a hit noise.
  * `pmg.damage_tree_at_coords`: Scans all 8 active trees. Compares horizontal (`|M_X - TREE_X_I| <= 10`) and vertical (`|M_Y - TREE_Y_I| <= 12`) distances. The 12 PMG byte vertical box compensates for character heights and offsets, ensuring that any playfield hit accurately damages the tree. Decrements health and triggers erasing when health reaches 0.
  * `pmg.erase_tree`: Cleans screen RAM with a space and zeros out the ZP coordinate registers.

---

### F. Cowboys AI & Logic (`src/cowboys.asm`)
* **Purpose**: Manages cowboy movement controls, AI predictions, and bird hazards.
* **Procedures**:
  * `cowboys.init`: Initializes starting slots, fractional registers, and timers.
  * `cowboys.update`: Standard player controls vs random AI movements.
  * `cowboys.shoot`: Smart AI barrel height checks and shooting intervals.
  * `cowboys.check_trajectory_blocked`: Compact, highly optimized 8-tree loop that checks if the AI's firing trajectory is blocked by any active shrub.
  * `cowboys.update_bird`:
    * Spawns a flapping yellow bird hazard from the top of the screen (`BIRD_ACTIVE = 1`).
    * **Precision Flight**: Swoops using 8.8 fixed-point precision with a constant descent of `1.25` pixels/frame. Calculates horizontal speed step dynamically as `BIRD_DX_16 = (BIRD_X - 60) * 4`, guaranteeing the bird always swoops across the player's track (`X = 60`) in exactly 64 frames (crossing at `Y = 92`).
    * **Flapping Cycle**: Cycles the animation index sequentially from 0 to 2 (`0 -> 1 -> 2 -> 0`) every 6 frames, driving a realistic three-frame wings-up, transitional, wings-down visual loop.

---

### G. Audio Engine (`src/sound.asm`)
* **Purpose**: Audio sweep and noise synthesis on POKEY.
* **Procedures**:
  * `sound.play`: Manages active audio effect duration timers.
    * *Shot Sound*: Generates a clean ascending sweep on POKEY Channel 1.
    * *Explosion/Hit Sound*: Generates a random noise burst on POKEY Channel 2 using the hardware `RANDOM` register.

---

## 4. Modern MADS Idioms Employed
- **`.proc` Scope Isolation**: Standard subroutines are wrapped inside `.proc / .endp` blocks, allowing local labels like `@loop` and `@exit` to be reused cleanly.
- **Built-in Macros**: Substitute verbose load/store sequences with `mva` (move byte) and `mwa` (move word) pseudo-commands for higher readability.
- **Inclusion Directive**: Modules are integrated in `shootout.asm` using MADS standard `icl 'src/filename.asm'`.
