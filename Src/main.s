// file: main.s
// created by: Grant Wilk
// date created: 11.1.2019
// last modified: 11.4.2019
// description: runs the "Guess the Hex!" game

// setup
.syntax unified
.cpu cortex-m4
.thumb

// global functions
.global main

// program
.section .text

main:

	// initialize "Guess the Hex!" game
	BL gth_init

	1:
	// print the title screen
	BL gth_display_title_screen

	// print the start screen until a key is pressed
	BL gth_display_start_screen
	BL keyi_wait

	// clear the display and play the start sound
	BL lcd_clear
	BL gth_sound_start

	// delay before the countdown
	MOV R1, #800
	BL delay_ms

	// print the countdown
	BL gth_display_countdown

	// play rounds until something happens
	2:
	BL gth_play_round
	CMP R0, #0
	BEQ 2b

	// show score stat, play game over sound, and game over screen
	BL gth_display_game_over_screen
	BL gth_display_stat_score
	BL gth_sound_game_over
	BL keyi_wait

	// show fastest reaction stat and game over screen
	BL gth_display_game_over_screen
	BL gth_display_stat_fastest_reaction
	BL gth_sound_double_dit_low
	BL keyi_wait

	// show average reaction stat and game over screen
	BL gth_display_game_over_screen
	BL gth_display_stat_average_reaction
	BL gth_sound_double_dit_low
	BL keyi_wait

	// show play again screen
	BL gth_display_play_again_screen
	BL gth_sound_double_dit_low
	BL keyi_wait

	// reset game variables
	BL gth_reset_variables

	// clear the lcd and play the speed up sound
	BL lcd_clear
	BL gth_sound_speed_up

	B 1b
