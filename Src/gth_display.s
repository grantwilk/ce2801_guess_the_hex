// file: gth_display.s
// created by: Grant Wilk
// date created: 11.4.2019
// date modified: 11.4.2019
// description: contains patterns and messages to write to the display for the "Guess the Hex!" game

// setup
.syntax unified
.cpu cortex-m4
.thumb

// global functions
.global gth_display_title_screen
.global gth_display_start_screen
.global gth_display_countdown
.global gth_display_speed_up_screen
.global gth_display_game_over_screen

.global gth_display_stat_score
.global gth_display_stat_play_time
.global gth_display_stat_fastest_reaction
.global gth_display_stat_average_reaction
.global gth_display_play_again_screen

// read-only data
.section .rodata
    title_string:
    	.asciz " GUESS THE HEX!"

    start_string_top:
    	.asciz " PRESS ANY KEY"
    start_string_bottom:
    	.asciz "   TO BEGIN"

    countdown_string_3:
        .asciz "      3 ..."
    countdown_string_2:
        .asciz "      2 ..."
    countdown_string_1:
        .asciz "      1 ..."
    countdown_string_go:
        .asciz "      GO!"

    streak_string:
        .asciz " STREAK"
    streak_spacer:
    	.asciz "   "
    speed_up_string:
        .asciz "  SPEEDING UP!"

    game_over_string:
        .asciz "GAME OVER!"
    stat_score_string:
        .asciz "SCORE: "
    stat_fastest_reaction_string:
        .asciz "FASTEST: "
    stat_average_reaction_string:
        .asciz "AVERAGE: "
    stat_millisecond_suffix:
        .asciz "ms"

    play_again_string_top:
        .asciz " PRESS ANY KEY"
    play_again_string_bottom:
        .asciz " TO PLAY AGAIN"

// program
.section .text
    // displays the title screen for 2 seconds
    // @ param None
    // @ return None
    gth_display_title_screen:

        PUSH {R1, LR}

        // clear the lcd
        BL lcd_clear

        // hide the cursor
        BL lcd_hide_cursor

        // print the title screen
        LDR R1, =title_string
        BL lcd_print_string

        // wait for 2 seconds
        MOV R1, #2000
        BL delay_ms

        // exit subroutine
        POP {R1, LR}
        BX LR


    // displays the start screen until the player presses a key
    // @ param
    // @ return None
    gth_display_start_screen:

        PUSH {R1, R2, LR}

        // clear the lcd
        BL lcd_clear

        // hide the cursor
        BL lcd_hide_cursor

        // print the top half of the start string
        LDR R1, =start_string_top
        BL lcd_print_string

        // move to line two
        MOV R1, #1
        MOV R2, #0
        BL lcd_set_cursor

        // print the bottom half of the start string
        LDR R1, =start_string_bottom
        BL lcd_print_string

        // play double dit sound
        BL gth_sound_double_dit_low

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // displays the start countdown
    // @ param None
    // @ return None
    gth_display_countdown:

        PUSH {R1, LR}

        BL lcd_clear

        // print countdown "3..." and play dit
        LDR R1, =countdown_string_3
        BL lcd_print_string
        BL gth_sound_dit_low
        MOV R1, #800
        BL delay_ms
        BL lcd_clear

        // print countdown "2..."
        LDR R1, =countdown_string_2
        BL lcd_print_string
        BL gth_sound_dit_low
        MOV R1, #800
        BL delay_ms
        BL lcd_clear

        // print countdown "1..."
        LDR R1, =countdown_string_1
        BL lcd_print_string
        BL gth_sound_dit_low
        MOV R1, #800
        BL delay_ms
        BL lcd_clear

        // print countdown "GO!"
        LDR R1, =countdown_string_go
        BL lcd_print_string
        BL gth_sound_dit_high
        MOV R1, #500
        BL delay_ms

        // exit subroutine
        POP {R1, LR}
        BX LR


    // displays the start countdown
    // @ param None
    // @ return None
    gth_display_speed_up_screen:

        PUSH {R1, LR}

        // clear the lcd
        BL lcd_clear

        // hide the cursor
        BL lcd_hide_cursor

        // move the cursor to row 0 col 3
        MOV R1, #0
        MOV R2, #3
        BL lcd_set_cursor

        // print the current score
        BL gth_get_score
        MOV R1, R0
        BL lcd_print_num

        // print the streak string
        LDR R1, =streak_string
        BL lcd_print_string

        // move the cursor to line 2
        MOV R1, #1
        MOV R2, #0
        BL lcd_set_cursor

        // print the speeding up screen
        LDR R1, =speed_up_string
        BL lcd_print_string

        // play the speed up sound
        BL gth_sound_speed_up

        // wait so that the total delay is 2500 milliseconds
        MOV R1, #700
        BL delay_ms

        // countdown
        BL gth_display_countdown

        // exit subroutine
        POP {R1, LR}
        BX LR


    // displays the game over screen
    // @ param None
    // @ return None
    gth_display_game_over_screen:

        PUSH {R1, LR}

        // clear the lcd
        BL lcd_clear

        // hide the cursor
        BL lcd_hide_cursor

        // print the title screen
        LDR R1, =game_over_string
        BL lcd_print_string

        // exit subroutine
        POP {R1, LR}
        BX LR


    // displays the score statistic
    // @ param None
    // @ return None
    gth_display_stat_score:

        PUSH {R1, R2, LR}

        // display game over screen
        BL gth_display_game_over_screen

        // move cursor to line 2
        MOV R1, #1
        MOV R2, #0
        BL lcd_set_cursor

        // print score string
        LDR R1, =stat_score_string
        BL lcd_print_string

        // print the score
        BL gth_get_score
        MOV R1, R0
        BL lcd_print_num

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // displays the fastest reaction statistic
    // @ param None
    // @ return None
    gth_display_stat_fastest_reaction:

        PUSH {R1, R2, LR}

        // display game over screen
        BL gth_display_game_over_screen

        // move cursor to line 2
        MOV R1, #1
        MOV R2, #0
        BL lcd_set_cursor

        // print fastest reaction string
        LDR R1, =stat_fastest_reaction_string
        BL lcd_print_string

        // print the fastest reaction or 0 if the score is 0
        BL gth_get_fastest_reaction
        MOV R1, R0

        BL gth_get_score
        CMP R0, #0
        BNE 1f
        MOV R1, R0

        1:
        BL lcd_print_num

        // print the milliseconds suffix
        LDR R1, =stat_millisecond_suffix
        BL lcd_print_string

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // displays the average reaction statistic
    // @ param None
    // @ return None
    gth_display_stat_average_reaction:

        PUSH {R1, R2, LR}

        // display game over screen
        BL gth_display_game_over_screen

        // move cursor to line 2
        MOV R1, #1
        MOV R2, #0
        BL lcd_set_cursor

        // print average reaction string
        LDR R1, =stat_average_reaction_string
        BL lcd_print_string

        // print the average reaction
        BL gth_get_play_time
        MOV R1, R0
        BL gth_get_score
        UDIV R1, R1, R0
        BL lcd_print_num

        // print the milliseconds suffix
        LDR R1, =stat_millisecond_suffix
        BL lcd_print_string

        // exit subroutine
        POP {R1, R2, LR}
        BX LR


    // displays the play again screen
    // @ param None
    // @ return None
    gth_display_play_again_screen:

        PUSH {R1, R2, LR}

        // clear the lcd
        BL lcd_clear

        // hide the cursor
        BL lcd_hide_cursor

        // print the top half of the play again string
        LDR R1, =play_again_string_top
        BL lcd_print_string

        // move to line two
        MOV R1, #1
        MOV R2, #0
        BL lcd_set_cursor

        // print the bottom half of the play again string
        LDR R1, =play_again_string_bottom
        BL lcd_print_string

        // exit subroutine
        POP {R1, R2, LR}
        BX LR
