################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_SRCS += \
../Src/delay.s \
../Src/gth.s \
../Src/gth_display.s \
../Src/gth_sound.s \
../Src/keypad_interrupt.s \
../Src/lcd.s \
../Src/main.s \
../Src/math.s \
../Src/piezo.s \
../Src/random.s 

OBJS += \
./Src/delay.o \
./Src/gth.o \
./Src/gth_display.o \
./Src/gth_sound.o \
./Src/keypad_interrupt.o \
./Src/lcd.o \
./Src/main.o \
./Src/math.o \
./Src/piezo.o \
./Src/random.o 


# Each subdirectory must supply rules for building sources it contributes
Src/%.o: ../Src/%.s
	arm-none-eabi-gcc -mcpu=cortex-m4 -g3 -c -x assembler-with-cpp --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@" "$<"

