# picoBoot - tiny bootloader for AVR MCUs - ATtiny85 and others
# @author: Ralph Doncaster
# @version: $Id$

# any AVR MCUs with USI should work
#DEVICE = attiny85

# Settings to build for ATMega328 
DEVICE = atmega328p
LD_FLAGS = -T avr2.xn

CC = avr-gcc
CFLAGS = -Os -mmcu=$(DEVICE)

all: boot.bin boot.hex

boot.hex: boot
	avr-objcopy -j .text -j .data -O ihex $< $@

boot: boot.o
	$(CC) $(LD_FLAGS) -o $@ $<

boot.bin: boot
	avr-objcopy -j .text -j .data -O binary $< $@

.S.o:
	$(CC) $(CFLAGS) -x assembler-with-cpp -c $< -o $@

clean:
	rm -f boot.o boot boot.bin boot.hex	