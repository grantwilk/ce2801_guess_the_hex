// file: random.s
// created by: Grant Wilk
// date created: 11.2.2019
// last modified: 11.2.2019
// description: contains functions for generating random numbers

// setup
.syntax unified
.cpu cortex-m4
.thumb

// global functions
.global random_init
.global random_get

// RCC constants
.equ RCC_BASE, 0x40023800 // base
.equ RCC_APB1ENR, 0x40 // offset
.equ RCC_APBIENR_TIM2EN, (1<<0) // value

// timer constants
.equ TIM2_BASE, 0x40000000 // base
.equ TIMx_CR1, 0x00 // offset
.equ TIMx_ARR, 0x2C // offset
.equ TIMx_CNT, 0x24 // offset
.equ TIMx_CR1_CEN, (1<<0) // value
.equ TIMx_ARR_RELOAD, 0xF // value

// program
.section .text

// initializes the perpipherals required to generate random numbers
// @ param None
// @ return None
random_init:

    PUSH {R1, R2}

    // enable TIM2 in RCC
    LDR R1, =RCC_BASE
    LDR R2, [R1, #RCC_APB1ENR]
    ORR R2, R2, #RCC_APBIENR_TIM2EN
    STR R2, [R1, #RCC_APB1ENR]

    // set timer reload value
    LDR R1, =TIM2_BASE
    MOV R2, #TIMx_ARR_RELOAD
    STR R2, [R1, #TIMx_ARR]

    // enable the timer
    LDR R2, [R1, #TIMx_CR1]
    ORR R2, R2, #TIMx_CR1_CEN
    STR R2, [R1, #TIMx_CR1]

    // exit subroutine
    POP {R1, R2}
    BX LR


// generates a random number between 0 and 15
// @ param None
// @ return R0 - a random number between 0 and 15
random_get:

    PUSH {R1}

    // load timer count into R0
    LDR R1, =TIM2_BASE
    LDR R0, [R1, #TIMx_CNT]

    // MOV R0, #0

    // exit subroutine
    POP {R1}
    BX LR
