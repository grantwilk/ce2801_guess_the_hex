// file: gth_sound.s
// created by: Grant Wilk
// date created: 11.4.2019
// date modified: 11.4.2019
// description: contains functions that play sounds for the "Guess the Hex!" game

// setup
.syntax unified
.cpu cortex-m4
.thumb

// global functions
.global gth_sound_dit_low
.global gth_sound_dit_high
.global gth_sound_double_dit_low
.global gth_sound_start
.global gth_sound_correct
.global gth_sound_incorrect
.global gth_sound_times_up
.global gth_sound_speed_up
.global gth_sound_game_over

// program
.section .text
    // plays the dit low sound (lasts 200ms)
    // @ param None
    // @ return None
    gth_sound_dit_low:

        PUSH {R1, R2, LR}

        // C#6 Quarter
        MOV R1, #1109
        MOV R2, #200
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // plays the dit high sound (lasts 500ms)
    // @ param None
    // @ return None
    gth_sound_dit_high:

        PUSH {R1, R2, LR}

        // A6 Half
        MOV R1, #1760
        MOV R2, #500
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // plays the double dit low sound (lasts 200ms)
    // @ param None
    // @ return None
    gth_sound_double_dit_low:

        PUSH {R1, R2, LR}

        // C#6 Eigth
        MOV R1, #1109
        MOV R2, #75
        BL piezo_play_tone

        // mid-press rest
        MOV R1, #50
        BL delay_ms

        // C#6 Eigth
        MOV R1, #1109
        MOV R2, #75
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // plays the start sound (lasts 800ms)
    // @ param None
    // @ return None
    gth_sound_start:

        PUSH {R1, R2, LR}

        // C#6 Quarter
        MOV R1, #1109
        MOV R2, #150
        BL piezo_play_tone

        // E6 Quarter
        MOV R1, #1319
        MOV R2, #150
        BL piezo_play_tone

        // A7 Quarter
        MOV R1, #1760
        MOV R2, #300
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // plays the correct answer sound (lasts 300ms)
    // @ param None
    // @ return None
    gth_sound_correct:

        PUSH {R1, R2, LR}

        // C#6 Quarter
        MOV R1, #1109
        MOV R2, #100
        BL piezo_play_tone

        // A6 Quarter
        MOV R1, #1760
        MOV R2, #200
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // plays the incorrect answer sound (lasts 600ms)
    // @ param None
    // @ return None
    gth_sound_incorrect:

        PUSH {R1, R2, LR}

        // C#5 Eigth
        MOV R1, #554
        MOV R2, #75
        BL piezo_play_tone

        // mid-press rest
        MOV R1, #50
        BL delay_ms

        // A4 Half (slow)
        MOV R1, #440
        MOV R2, #475
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // plays the times up sound (lasts 1500ms)
    // @ param None
    // @ return None
    gth_sound_times_up:

        PUSH {R1, R2, LR}

        // C#5 (long)
        MOV R1, #554
        MOV R2, #1500
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // plays the speed up sound (lasts 1800ms)
    // @ param None
    // @ return None
    gth_sound_speed_up:

        PUSH {R1, R2, LR}

        // F#5 Quarter (slow)
        MOV R1, #740
        MOV R2, #225
        BL piezo_play_tone

        // G#5 Quarter (slow)
        MOV R1, #831
        MOV R2, #225
        BL piezo_play_tone

        // A5 Half (slow)
        MOV R1, #880
        MOV R2, #450
        BL piezo_play_tone

        // G#5 Full (slow)
        MOV R1, #831
        MOV R2, #900
        BL piezo_play_tone

        POP {R1, R2, LR}
        BX LR


    // plays the game over sound (lasts 2100ms)
    // @ param None
    // @ return None
    gth_sound_game_over:

        PUSH {R1, R2, LR}

        // G#5 Quarter (slow)
        MOV R1, #830
        MOV R2, #225
        BL piezo_play_tone

        // A5 Quarter (slow)
        MOV R1, #880
        MOV R2, #225
        BL piezo_play_tone

        // G#5 Quarter (slow)
        MOV R1, #830
        MOV R2, #225
        BL piezo_play_tone

        // F#5 Quarter (slow)
        MOV R1, #740
        MOV R2, #225
        BL piezo_play_tone

        // G#5 Quarter (slow)
        MOV R1, #830
        MOV R2, #225
        BL piezo_play_tone

        // F#5 Quarter (slow)
        MOV R1, #740
        MOV R2, #225
        BL piezo_play_tone

        // E5 Half (slow)
        MOV R1, #660
        MOV R2, #450
        BL piezo_play_tone

        // C#6 Eigth
        MOV R1, #1108
        MOV R2, #75
        BL piezo_play_tone

        // D#6 Eigth
        MOV R1, #1245
        MOV R2, #75
        BL piezo_play_tone

        // E6 Eigth
        MOV R1, #1318
        MOV R2, #150
        BL piezo_play_tone

        // exit subroutine
        POP {R1, R2, LR}
        BX LR
