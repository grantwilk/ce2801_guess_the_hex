// file: gth.s
// created by: Grant Wilk
// date created: 11.3.2019
// date modified: 11.4.2019
// description: contains operational functions for the "Guess the Hex!" game

// setup
.syntax unified
.cpu cortex-m4
.thumb

// global functions
.global gth_init
.global gth_play_round
.global gth_reset_variables
.global gth_get_score
.global gth_get_fastest_reaction
.global gth_get_play_time

// global interrupt handlers
.global TIM4_IRQHandler

// RCC constants
.equ RCC_BASE, 0x40023800 // base
.equ RCC_APB1ENR, 0x40 // offset
.equ RCC_APBIENR_TIM4EN, (1<<2) // value

// TIM4 constants
.equ TIM4_BASE, 0x40000800 // base
.equ TIMx_ARR, 0x2C // offset
.equ TIMx_CCER, 0x20 // offset
.equ TIMx_CCMR1, 0x18 // offset
.equ TIMx_CCR1, 0x34 // offset
.equ TIMx_CNT, 0x24 // offset
.equ TIMx_CR1, 0x00 // offset
.equ TIMx_DIER, 0x0C // offset
.equ TIMx_PSC, 0x28 // offset
.equ TIMx_SR, 0x10 // offset

.equ TIMx_CCER_CC1E, (0b1<<0) // value
.equ TIMx_CCMR1_OC1M, (0b011<<4) // value
.equ TIMx_CR1_CEN, (1<<0) // value
.equ TIMx_CR1_OPM, (1<<3) // value
.equ TIMx_DIER_CC1IE, (1<<1) // value
.equ TIMx_PSC_VALUE, 16000

// NVIC constants
.equ NVIC_BASE, 0xe000e100 // base
.equ NVIC_ISER0, 0x00 // offset
.equ NVIC_ICPR0, 0x180 // offset
.equ NVIC_ISER0_TIM4, (1<<30) // value
.equ NVIC_ICPR0_TIM4, (1<<30) // value

// variable defaults
.equ GTH_DEFAULT_SCORE, 0
.equ GTH_DEFAULT_PLAY_TIME, 0
.equ GTH_DEFAULT_FASTEST_REACTION, GTH_DEFAULT_GUESS_TIMER
.equ GTH_DEFAULT_GUESS_TIMER, 4000
.equ GTH_DEFAULT_TIMER_EXPIRED_FLAG, 0

// read-write data
.section .data
    score:
    	.word GTH_DEFAULT_SCORE
    play_time:
    	.word GTH_DEFAULT_PLAY_TIME
    guess_timer:
        .word GTH_DEFAULT_GUESS_TIMER
    fastest_reaction:
    	.word GTH_DEFAULT_FASTEST_REACTION
    guess_timer_expired_flag:
        .word GTH_DEFAULT_TIMER_EXPIRED_FLAG

// read-only data
.section .rodata
    result_string_correct:
        .asciz "    CORRECT!"
    result_string_incorrect:
        .asciz "   INCORRECT!"
    result_string_times_up:
        .asciz "   TIMES UP!"
    result_string_answer:
        .asciz "    ANSWER:"

// program
.section .text
    // initializes the peripherals required for the "Guess the Hex!" game
    // @ param None
    // @ return None
    gth_init:

        PUSH {LR}

        // initialize peripherals
        BL lcd_init
        BL piezo_init
        BL keyi_init
        BL random_init

		// initialize game timer
        // enable TIM4 in RCC
        LDR R1, =RCC_BASE
	    LDR R2, [R1, #RCC_APB1ENR]
	    ORR R2, R2, #RCC_APBIENR_TIM4EN
	    STR R2, [R1, #RCC_APB1ENR]

        // set prescaler
        LDR R1, =TIM4_BASE
        MOV R2, #TIMx_PSC_VALUE
        STR R2, [R1, #TIMx_PSC]

        // set reload value and output compare value
        LDR R2, =guess_timer
        LDR R2, [R2]
        STR R2, [R1, #TIMx_ARR]
        STR R2, [R1, #TIMx_CCR1]

        // set output compare to set channel 1 to active level on match with CCR1
        LDR R2, [R1, #TIMx_CCMR1]
        ORR R2, R2, #TIMx_CCMR1_OC1M
        STR R2, [R1, #TIMx_CCMR1]

        // enable output compare for channel 1
        LDR R2, [R1, #TIMx_CCER]
        ORR R2, R2, #TIMx_CCER_CC1E
        STR R2, [R1, #TIMx_CCER]

        // enable interrupts to be sent from channel 1
        LDR R2, [R1, #TIMx_DIER]
        ORR R2, R2, #TIMx_DIER_CC1IE
        STR R2, [R1, #TIMx_DIER]

        // exit subroutine
        POP {LR}
        BX LR


    // plays a round of "Guess the Hex!"
    // @ param None
    // @ return R0 - 0 if the player can continue playing, 1 if the player cannot continue playing
    gth_play_round:

        // R1 - temp
        // R2 - temp
        // R3 - the randomly generated number
        // R4 - the keypad input

        PUSH {R1-R4, LR}

        // clear the LCD
        BL lcd_clear

        // generate a random number and move it to R3
        BL random_get
        MOV R3, R0

        // move the cursor to the middle of line 1
        MOV R1, #0
        MOV R2, #6
        BL lcd_set_cursor

        // convert the number to binary and print it
        MOV R1, R3
        BL lcd_print_binary

        // play double dit tone
		BL gth_sound_double_dit_low

        // clear any pending keypresses
        BL keyi_clear

        // reset the timer
        LDR R1, =TIM4_BASE
       	MOV R2, #0
       	STR R2, [R1, #TIMx_CNT]

        // reset the guess timer expired flag
        MOV R1, #0
        BL gth_set_guess_timer_expired_flag

        // start the timer
        LDR R1, =TIM4_BASE
        LDR R2, [R1, #TIMx_CR1]
        ORR R2, R2, #TIMx_CR1_CEN
        STR R2, [R1, #TIMx_CR1]

		// delay 1ms to allow prescaler to update
        MOV R1, #1
        BL delay_ms

        // clear any remaining timer update event flags
        LDR R1, =TIM4_BASE
    	MOV R2, #0
    	STR R2, [R1, #TIMx_SR]

    	// clear any remaining pending interrupt requests
    	LDR R1, =NVIC_BASE
    	MOV R2, #NVIC_ICPR0_TIM4
    	STR R2, [R1, #NVIC_ICPR0]

        // enable interrupts to be sent from TIM4 in NVIC
        LDR R1, =NVIC_BASE
        MOV R2, #NVIC_ISER0_TIM4
        STR R2, [R1, #NVIC_ISER0]

        // wait for keypad input or guess timer expiration
        1:
        BL gth_get_guess_timer_expired_flag
        CMP R0, #0
        BNE 2f

        BL keyi_get_char
        CMP R0, #0
        BNE 2f

        B 1b

        // store the keypress in R4
        2:
        MOV R4, R0

        // stop the timer
        LDR R1, =TIM4_BASE
        LDR R2, [R1, #TIMx_CR1]
        BIC R2, R2, #TIMx_CR1_CEN
        STR R2, [R1, #TIMx_CR1]

        // convert the randomly generated number to an ascii character and store back in R3
        ADD R1, R3, #1
        BL keyi_key_to_char
        MOV R3, R0

        // if the timer expired, handle things as a times up response
        BL gth_get_guess_timer_expired_flag
        CMP R0, #0
        BNE gth_times_up_response

        // if the character of the randomly generated number is equal to the character from the keypress, handle things as a correct response
        CMP R3, R4
        BEQ gth_correct_response

        // in all other cases, handle things as an incorrect response
        BL gth_incorrect_response

        // correct handler
        gth_correct_response:
            // move the cursor to line 2
            MOV R1, #1
            MOV R2, #0
            BL lcd_set_cursor

            // print correct string
            LDR R1, =result_string_correct
            BL lcd_print_string

            // increment score
            BL gth_increment_score

            // get elapsed time
            LDR R1, =TIM4_BASE
            LDR R1, [R1, #TIMx_CNT]

            // update fastest reaction
            LDR R2, =fastest_reaction
            LDR R2, [R2]
            CMP R1, R2
            BGT 3f
            BL gth_set_fastest_reaction

            // add elapsed time to total time
            3:
            BL gth_increment_play_time

            // play correct tone
            BL gth_sound_correct

            // delay for 200 ms
            MOV R1, #200
            BL delay_ms

            // check for 15 streak and decrement timer if so
            LDR R1, =score
            LDR R1, [R1]
            MOV R2, #10
            BL math_modulo

            CMP R0, #0
            BNE 3f

            BL gth_decrement_guess_timer
            BL gth_display_speed_up_screen

            // set return value
            3:
            MOV R0, #0

            B 4f

        // incorrect handler
        gth_incorrect_response:
           // move the cursor to line 2
            MOV R1, #1
            MOV R2, #0
            BL lcd_set_cursor

            // print incorrect string
            LDR R1, =result_string_incorrect
            BL lcd_print_string

			// play incorrect tone
            BL gth_sound_incorrect

            // delay 1400ms (2000ms total, including the incorrect sound)
            MOV R1, #1400
            BL delay_ms

            // clear the LCD
            BL lcd_clear

            // print the answer string
            LDR R1, =result_string_answer
            BL lcd_print_string

            // move the cursor to the center of line 2
            MOV R1, #1
            MOV R2, #7
            BL lcd_set_cursor

            // print the correct answer
            MOV R1, R3
            BL lcd_print_char

            // delay 2000ms
            MOV R1, #2000
            BL delay_ms

            // set return value
            MOV R0, #1

            B 4f

        // times up handler
        gth_times_up_response:
            // move the cursor to line 2
            MOV R1, #1
            MOV R2, #0
            BL lcd_set_cursor

            // print times up string
            LDR R1, =result_string_times_up
            BL lcd_print_string

            // play times up tone
            BL gth_sound_times_up

            // delay 1500ms (3000ms total, including times up sound)
            MOV R1, #1500
            BL delay_ms

            // clear the LCD
            BL lcd_clear

            // print the answer string
            LDR R1, =result_string_answer
            BL lcd_print_string

            // move the cursor to the center of line 2
            MOV R1, #1
            MOV R2, #7
            BL lcd_set_cursor

            // print the correct answer
            MOV R1, R3
            BL lcd_print_char

            // delay 2000ms
            MOV R1, #2000
            BL delay_ms

            // set return value
            MOV R0, #1

            B 4f

        4:
        // exit subroutine
        POP {R1-R4, LR}
        BX LR

    // resets all of the game variables for a new game to be played
    // @ param None
    // @ return None
    gth_reset_variables:

        PUSH {R1, LR}

        // reset score
        LDR R1, =GTH_DEFAULT_SCORE
        BL gth_set_score

        // reset play time
        LDR R1, =GTH_DEFAULT_PLAY_TIME
        BL gth_set_play_time

        // reset fastest_reaction
        LDR R1, =GTH_DEFAULT_FASTEST_REACTION
        BL gth_set_fastest_reaction

        // reset guess timer
        LDR R1, =GTH_DEFAULT_GUESS_TIMER
        BL gth_set_guess_timer

        // reset timer expired flag
        LDR R1, =GTH_DEFAULT_TIMER_EXPIRED_FLAG
        BL gth_set_guess_timer_expired_flag

        // exit subroutine
        POP {R1, LR}
        BX LR


    // gets the score of the current game
    // @ param None
    // @ return R0 - the score of the current game
    gth_get_score:

        PUSH {R1}

        // get the score and store it in R0
        LDR R1, =score
        LDR R0, [R1]

        // exit subroutine
        POP {R1}
        BX LR


    // sets the score
    // @ param R1 - the value to set the score to
    // @ return None
    gth_set_score:

        PUSH {R1, R2}

        // set the score to the value in R1
        LDR R2, =score
        STR R1, [R2]

        // exit subroutine
        POP {R1, R2}
        BX LR


    // increments the score by one point
    // @ param None
    // @ return None
    gth_increment_score:

        PUSH {R1, R2}

        // increment score
        LDR R1, =score
        LDR R2, [R1]
        ADD R2, R2, #1
        STR R2, [R1]

        // exit subroutine
        POP {R1, R2}
        BX LR


    // gets the fastest reaction
    // @ param None
    // @ return R0 - the fastest reaction in milliseconds
    gth_get_fastest_reaction:

        PUSH {R1}

        // get the fastest reaction and store it in R0
        LDR R1, =fastest_reaction
        LDR R0, [R1]

        // exit subroutine
        POP {R1}
        BX LR


    // sets the fastest reaction
    // @ param R1 - the value to set the fastest reaction to in milliseconds
    // @ return None
    gth_set_fastest_reaction:

        PUSH {R1, R2}

        // set the fastest reaction to the value stored in R1
        LDR R2, =fastest_reaction
        STR R1, [R2]

        // exit subroutine
        POP {R1, R2}
        BX LR


    // gets the total amount of play time in the current game
    // @ param None
    // @ return R0 - the total amount of play time in the current game in milliseconds
    gth_get_play_time:

        PUSH {R1}

        // get the total time and store it in R0
        LDR R1, =play_time
        LDR R0, [R1]

        // exit subroutine
        POP {R1}
        BX LR


    // sets the total amount of play time in the current game
    // @ param R1 - the total amount of play time in the current game in milliseconds
    // @ return None
    gth_set_play_time:

        PUSH {R1, R2}

        // set the total time to the value stored in R1
        LDR R2, =play_time
        STR R1, [R2]

        // exit subroutine
        POP {R1, R2}
        BX LR


    // increments the total time by some value
    // @ param R1 - the value to increment the total time by in milliseconds
    // @ return None
    gth_increment_play_time:

        PUSH {R1-R3}

        // increment the total time
        LDR R2, =play_time
        LDR R3, [R2]
        ADD R3, R3, R1
        STR R3, [R2]

        // exit subroutine
        POP {R1-R3}
        BX LR


    // sets the guess timer
    // @ param R1 - the amount of time to be loaded into the guess timer in milliseconds
    // @ return None
    gth_set_guess_timer:

        PUSH {R1, R2}

        // set the guess timer to the value stored in R1
        LDR R2, =guess_timer
        STR R1, [R2]

        // store into TIM4_CCR1
        LDR R2, =TIM4_BASE
        STR R1, [R2, #TIMx_CCR1]

        // exit subroutine
        POP {R1, R2}
        BX LR


    // decrements the guess timer by 20 percent
    // @ param None
    // @ return None
    gth_decrement_guess_timer:

        PUSH {R1-R3}

        // load guess timer
        LDR R1, =guess_timer
        LDR R2, [R1]

        // guess_timer = 0.8 * guess_timer
        MOV R3, #10
        UDIV R2, R2, R3

        MOV R3, #8
        MUL R2, R2, R3

        // store back to guess timer
        STR R2, [R1]

        // store into TIM4_CCR1
        LDR R1, =TIM4_BASE
        STR R2, [R1, #TIMx_CCR1]

        // exit subroutine
        POP {R1-R3}
        BX LR


    // gets the value of the guess timer expired flag
    // @ param None
    // @ return R0 - the value of the guess timer expired flag
    gth_get_guess_timer_expired_flag:

        PUSH {R1}

        // load the flag value and store in R0
        LDR R1, =guess_timer_expired_flag
        LDR R0, [R1]

        // exit subroutine
        POP {R1}
        BX LR


    // sets the value of the guess timer expired flag
    // @ param R1 - the value to set the guess timer expired flag to
    // @ return None
    gth_set_guess_timer_expired_flag:

        PUSH {R1, R2}

        // store R1 as the guess timer expired flag
        LDR R2, =guess_timer_expired_flag
        STR R1, [R2]

        // exit subroutine
        POP {R1, R2}
        BX LR


    // TIM4 interrupt request handler
    // @ param None
    // @ return None
	.thumb_func
    TIM4_IRQHandler:
    	PUSH {R1, LR}

    	// clear timer flags
    	LDR R1, =TIM4_BASE
    	MOV R2, #0
    	STR R2, [R1, #TIMx_SR]

    	// clear pending interrupt
    	LDR R1, =NVIC_BASE
    	MOV R2, #NVIC_ICPR0_TIM4
    	STR R2, [R1, #NVIC_ICPR0]

        // set guess timer expired flag
        MOV R2, #1
        LDR R1, =guess_timer_expired_flag
        STR R2, [R1]

        // exit handler
        POP {R1, LR}
        BX LR
