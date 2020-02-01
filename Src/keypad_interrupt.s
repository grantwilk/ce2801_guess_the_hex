// file: keypad_interrupt.s
// created by: Grant Wilk
// date created: 11.1.2019
// last modified: 11.4.2019
// description: contains functions for interacting with the onboard keypad based on interrupts

// setup
.syntax unified
.cpu cortex-m4
.thumb

// global functions
.global keyi_init
.global keyi_get
.global keyi_get_char
.global keyi_clear
.global keyi_wait
.global keyi_key_to_char

// global handlers
.global EXTI0_IRQHandler
.global EXTI1_IRQHandler
.global EXTI2_IRQHandler
.global EXTI3_IRQHandler

// RCC constants
.equ RCC_BASE, 0x40023800 // base
.equ RCC_AHB1ENR, 0x30 // offset
.equ RCC_GPIOCEN, 1<<2 // value
.equ RCC_APB2ENR, 0x44 // offset
.equ RCC_SYSCFGEN, 1<<14 // value

// GPIO constants
.equ GPIOC_BASE, 0x40020800 // base
.equ GPIO_MODER, 0x00 // offset
.equ GPIO_PUPDR, 0x0C // offset
.equ GPIO_IDR, 0x10 // offset
.equ GPIO_ODR, 0x14 // offset

.equ CONFIG_KEYPAD_KEYS_PULLDOWN, 0xAAAA // value
.equ KEYPAD_COLS_MASK, 0x00FF // value
.equ CONFIG_KEYPAD_COLS_OUTPUTS, 0x0055 // value
.equ KEYPAD_ROWS_MASK, 0xFF00 // value
.equ CONFIG_KEYPAD_ROWS_OUTPUTS, 0x5500 // value
.equ KEYPAD_OUTPUT_VALUES, 0xFF // value

// SYSCFG constrants
.equ SYSCFG_BASE, 0x40013800 // base
.equ SYSCFG_EXTICR1, 0x08 // offset
.equ SET_EXTIX_TO_PIN_C, 1<<1 // value

// EXTI constants
.equ EXTI_BASE, 0x40013c00 // base
.equ EXTI_IMR, 0x00 // offset
.equ EXTI_MR0_THRU_MR4, 0xF // value
.equ EXTI_RTSR, 0x08 // offset
.equ EXTI_TR0_THRU_TR4, 0xF // value
.equ EXTI_PR, 0x14 // offset

// NVIC constants
.equ NVIC_BASE, 0xe000e100 // base
.equ NVIC_ISER0, 0x00 // offset
.equ NVIC_ICER0, 0x80 // offset
.equ NVIC_POS6_THRU_POS9, (0b1111<<6) // value

// read-write data
.section .data
	// the index of the last key pressed
	last_key:
		.byte 0

// read-only data
.section .rodata
	keypad_characters:
		.ascii "0123456789ABCDEF"

// program
.section .text

// initailizes the interrupt driven keypad
// @ param None
// @ return None
keyi_init:

    PUSH {R1-R3, LR}

    // enable clock to SYSCFG
    LDR R1, =RCC_BASE
    LDR R2, [R1, #RCC_APB2ENR]
    ORR R2, R2, #RCC_SYSCFGEN
    STR R2, [R1, #RCC_APB2ENR]

    // enable clock for GPIOC
    LDR R2, [R1, #RCC_AHB1ENR]
    ORR R2, R2, #RCC_GPIOCEN
    STR R2, [R1, #RCC_AHB1ENR]

    // confgure keypad column pins as inputs
    // configure keypad row pins as outputs
    LDR R1, =GPIOC_BASE
    LDR R2, [R1, #GPIO_MODER]
    BIC R2, R2, #KEYPAD_COLS_MASK
    BIC R2, R2, #KEYPAD_ROWS_MASK
    ORR R2, R2, #CONFIG_KEYPAD_ROWS_OUTPUTS
    STR R2, [R1, #GPIO_MODER]

    // confgure keypad column pins as pull-down
    LDR R2, [R1, #GPIO_PUPDR]
    MOV R3, #CONFIG_KEYPAD_KEYS_PULLDOWN
    ORR R2, R2, R3
    STR R2, [R1, #GPIO_PUPDR]

    // set keypad output values
    LDR R2, [R1, #GPIO_ODR]
    ORR R2, R2, #KEYPAD_OUTPUT_VALUES
    STR R2, [R1, #GPIO_ODR]

    // connect keypad columns to interrupts
    LDR R1, =SYSCFG_BASE
    LDR R2, [R1, #SYSCFG_EXTICR1]
    ORR R2, R2, #SET_EXTIX_TO_PIN_C
    ORR R2, R2, #(SET_EXTIX_TO_PIN_C<<4)
    ORR R2, R2, #(SET_EXTIX_TO_PIN_C<<8)
    ORR R2, R2, #(SET_EXTIX_TO_PIN_C<<12)
    STR R2, [R1, #SYSCFG_EXTICR1]

    // unmask EXTI0 - EXTI3 in EXTI_IMR
    LDR R1, =EXTI_BASE
    LDR R2, [R1, #EXTI_IMR]
    ORR R2, R2, #EXTI_MR0_THRU_MR4
    STR R2, [R1, #EXTI_IMR]

    // set interrupts on rising edge
    LDR R2, [R1, #EXTI_RTSR]
    ORR R2, R2, #EXTI_TR0_THRU_TR4
    STR R2, [R1, #EXTI_RTSR]

    // enable interrupt in NVIC
    MOV R2, #NVIC_POS6_THRU_POS9
    LDR R1, =NVIC_BASE
    STR R2, [R1, #NVIC_ISER0]

	// clear the last key byte from memory
	BL keyi_clear

    // exit subroutine
    POP {R1-R3, LR}
    BX LR


// gets the index (1-16) of the last key pressed
// @ param None
// @ return R0 - the index (1-16) of the last key pressed. if no key was pressed, return 0.
keyi_get:

    PUSH {R1, LR}

	// disable keypad interrupts while getting key
    MOV R2, #NVIC_POS6_THRU_POS9
    LDR R1, =NVIC_BASE
    STR R2, [R1, #NVIC_ICER0]

    // loads the last key and stores in in R0
    LDR R1, =last_key
    LDRB R0, [R1]

	// clear the key from memory
	BL keyi_clear

	// re-enable keypad interrupts
	MOV R2, #NVIC_POS6_THRU_POS9
    LDR R1, =NVIC_BASE
    STR R2, [R1, #NVIC_ISER0]

    // exit subroutine
    POP {R1, LR}
    BX LR


// gets the ascii character of the last keypress
// @ param None
// @ return R0 - the ascii character of the last keypress. if no key is pressed, return 0.
keyi_get_char:

	PUSH {R1, LR}

	// get the index of the last keypress
	BL keyi_get

	// if no key is pressed, return 0
	CMP R0, #0
	BEQ 1f

	// subtract one to account for the "return 0" offset of the keyi_get function
	SUB R0, R0, #1

	// load the character at the offset and store it in R0
	LDR R1, =keypad_characters
	LDRB R0, [R1, R0]

	// exit subroutine
	1:
	POP {R1, LR}
	BX LR


// clears the last key from memory
// @ param None
// @ return None
keyi_clear:

	PUSH {R1, R2}

	// clear the byte
	MOV R2, #0
	LDR R1, =last_key
	STRB R2, [R1]

	// exit subroutine
	POP {R1, R2}
	BX LR


// waits until a keypress occurs, then returns
// @ param None
// @ return None
keyi_wait:

	PUSH {LR}

	// clear and pending keypresses
	BL keyi_clear

	// loop until a key is pressed
	1:
	BL keyi_get
	CMP R0, #0
	BEQ 1b

	// exit subroutine
	POP {LR}
	BX LR


// converts the keypress index to a character
// @ param R1 - the index of the keypress (1-16)
// @ return R0 - the ascii character of the input keypress. if invalid, return 0.
keyi_key_to_char:

	PUSH {R1}

	// if input keypress index outside of range 1-16, return 0
	CMP R1, #1
	BLT 1f

	CMP R1, #16
	BGT 1f

	// get the character at the keypress index and store it in R0
	LDR R0, =keypad_characters
	SUB R1, R1, #1
	LDRB R0, [R0, R1]
	B 2f

	// move 0 into R0
	1:
	MOV R0, #0

	// exit subroutine
	2:
	POP {R1}
	BX LR


// validates a keypad interrupt to ensure it is not a bounce or other fluke
// @ param R1 - the index of the triggered interrupt (e.g. EXTI4 would have an index of 4)
// @ return 1 if the interrupt is valid, 0 if the interrupt is invalid
keyi_validate_interrupt:

    // R0 - return register
    // R1 - first parameter / temp
    // R2 - the index of the interrupt
    // R3 - temp register
    // R4 - temp register

    PUSH {R1-R4, LR}

    // move the interrupt index to a safe register
    MOV R2, R1

    // generate pending interrupt disable mask
    MOV R4, #1
    LSL R4, R4, R2

    // clear pending interrupt
    LDR R3, =EXTI_BASE
    STR R4, [R3, #EXTI_PR]

    // delay 50 ms to wait for bounce
    MOV R1, #50
    BL delay_ms

    // read the value from the current pin with respect to the interrupt triggered and store it in the return register
    LDR R3, =GPIOC_BASE
    LDR R4, [R3, #GPIO_IDR]
    LSR R4, R4, R2
    UBFX R0, R4, #0, #1

    // exit subroutine
    POP {R1-R4, LR}
    BX LR


// handles keypad interrupts
// @ param R1 - the index of the triggered interrupt (e.g. EXTI4 would have an index of 4)
// @ return None
keyi_interrupt_handler:

    // R1 - temp
    // R2 - interrupt index (or column number)
    // R3 - input value from rows (or row number)
    // R4 - temp
    // R5 - temp

    PUSH {R0-R5, LR}

    // validate interrupt and break from handler if invalid
    BL keyi_validate_interrupt
    CMP R0, #0
    BEQ 1f

    // move interrupt index to a safe register
    MOV R2, R1

	// mask EXTI0 - EXTI3 in EXTI_IMR
    LDR R5, =EXTI_BASE
    LDR R4, [R5, #EXTI_IMR]
    BIC R4, R4, #EXTI_MR0_THRU_MR4
    STR R4, [R5, #EXTI_IMR]

    // configure the columns to be outputs
    // configure the rows to be inputs
    LDR R4, =GPIOC_BASE
    LDR R5, [R4, #GPIO_MODER]
    BIC R5, R5, #KEYPAD_COLS_MASK
    BIC R5, R5, #KEYPAD_ROWS_MASK
    ORR R5, R5, #CONFIG_KEYPAD_COLS_OUTPUTS
    STR R5, [R4, #GPIO_MODER]

    // delay 10 microseconds to give the pins time to switch between inputs and outputs
    MOV R1, #10
    BL delay_us

    // read the row input values, convert them to binary, then store them in R3
    LDR R5, [R4, #GPIO_IDR]
    UBFX R1, R5, #4, #4
    BL keyi_onehot_to_binary
    MOV R3, R0

    // configure the columns to be inputs again
    // configure the rows to be outputs again
    LDR R5, [R4, #GPIO_MODER]
    BIC R5, R5, #KEYPAD_COLS_MASK
    BIC R5, R5, #KEYPAD_ROWS_MASK
    ORR R5, R5, #CONFIG_KEYPAD_ROWS_OUTPUTS
    STR R5, [R4, #GPIO_MODER]

	// unmask EXTI0 - EXTI3 in EXTI_IMR
    LDR R5, =EXTI_BASE
    LDR R4, [R5, #EXTI_IMR]
    ORR R4, R4, #EXTI_MR0_THRU_MR4
    STR R4, [R5, #EXTI_IMR]

    // determine which key was pressed from the row and columns
    MOV R4, #4
    MUL R3, R3, R4
    ADD R1, R3, R2
	ADD R1, R1, #1

    // store the keypress in memory
	LDR R4, =last_key
	STRB R1, [R4]

	// exit subroutine
    1:
    POP {R0-R5, LR}
    BX LR


// encodes a one-hot number in binary
// @ param R1 - a one-hot number
// @ return R0 - the number encoded in binary
keyi_onehot_to_binary:

    PUSH {R1}

    // binary equivalent = word length - leading zeros
    CLZ R1, R1
    RSB R0, R1, #31

    // exit subroutine
    POP {R1}
    BX LR


// EXRI0 interrupt request handler
// @ param None
// @ return None
.thumb_func
EXTI0_IRQHandler:

	PUSH {R1, LR}

    // pass things off to the keyi_interrupt_handler
    MOV R1, #0
    BL keyi_interrupt_handler

    // exit subroutine
	POP {R1, LR}
    BX LR


// EXRI1 interrupt request handler
// @ param None
// @ return None
.thumb_func
EXTI1_IRQHandler:

    PUSH {R1, LR}

    // pass things off to the keyi_interrupt_handler
    MOV R1, #1
    BL keyi_interrupt_handler

    // exit subroutine
    POP {R1, LR}
    BX LR


// EXRI2 interrupt request handler
// @ param None
// @ return None
.thumb_func
EXTI2_IRQHandler:

    PUSH {R1, LR}

    // pass things off to the keyi_interrupt_handler
    MOV R1, #2
    BL keyi_interrupt_handler

    // exit subroutine
    POP {R1, LR}
    BX LR


// EXRI3 interrupt request handler
// @ param None
// @ return None
.thumb_func
EXTI3_IRQHandler:

    PUSH {R1, LR}

    // pass things off to the keyi_interrupt_handler
    MOV R1, #3
    BL keyi_interrupt_handler

    // exit subroutine
    POP {R1, LR}
    BX LR
