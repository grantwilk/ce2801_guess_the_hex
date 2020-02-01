// file: math.s
// created by: Grant Wilk
// date created: 11.4.2019
// date modified: 11.4.2019
// description: contains math functions that are not available in the ARM Thumb-2 instruction set

// setup
.syntax unified
.cpu cortex-m4
.thumb

// global functions
.global math_modulo

// program
.section .text
    // returns the remainder of R1 divided by R2
    // @ param R1 - the dividend
    // @ param R2 - the divisor
    // @ return R0 - the remainder of the division
    math_modulo:

        PUSH {R1, R2}

        // subtract the divisor from the dividend until the dividend is negative
        1:
        SUBS R1, R1, R2
        BGE 1b

        // twos complement
        // flip the dividend and add one to make it positive
        EOR R1, #-1
        ADD R1, R1, #1

        // subtract the positive dividend from the divisor and store in R0
        SUB R0, R2, R1

        // exit subroutine
        POP {R1, R2}
        BX LR
