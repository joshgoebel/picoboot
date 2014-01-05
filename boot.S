/* picoBoot - tiny bootloader for AVR MCUs - ATtiny85 and others
 * @author: Ralph Doncaster
 * @version: $Id$
 * code ideas from:
 * http://jtxp.org/tech/tinysafeboot_en.htm
 * http://symlink.dk/electro/m163boot/
 * http://github.com/baerwolf/USBaspLoader
 */

/* needed for <avr/io.h> to give io constant addresses */
#define __SFR_OFFSET 0 

/* AVR CPU definitions based on -mmcu flag */
#include <avr/io.h>

#define BOOTPIN	PINB0
#define tmp1	r16
#define dataOut	r17

#define LOWBYTE(word) (word & 0xff)

#ifdef _AVR_IOM328P_H_
#else
#endif

.text
.org 0x0000
IntVectors:
  #ifdef _AVR_IOM328P_H_
  jmp BootStart
  #else 
  rjmp BootStart
  #endif

; .org _VECTORS_SIZE
.org (FLASHEND - SPM_PAGESIZE - 1)
# .org 0x7000
# .org (FLASHEND - 3024)
# .org 5000
# .org 0x7000
AppStart:
  # rjmp 0              ; dummy vector to be overwritten
  nop
; .org (FLASHEND - SPM_PAGESIZE + 1)
; beginning of last page of memory
BootStart:
	sbis PINB, BOOTPIN 				; run bootloader if BOOTPIN high
	rjmp AppStart					; jump to application code
; set SPI slave
  #ifdef _AVR_IOM328P_H_
    ; Enable SPI
    ldi tmp1, (1<<SPE)
    out SPCR, tmp1
    ; Set MISO output to PB4 (pin 13), all others input 
    sbi DDRB, DDB4
  # else
    ldi tmp1,(1<<USIWM0)|(1<<USICS1)
    out USICR, tmp1
    sbi DDRB, DDB1					; set BP1 to output
  #endif
; USIDR wrapps - bytes will echo back to programmer

; Z pointer starts at program address 0
CommandLoop:
  rcall SPIxfer					; read low byte
  mov r0, tmp1
  rcall SPIxfer					; read high byte
	mov r1, tmp1
  rcall DoSPM
  
	sbrc tmp1, 6					; command bit 6 = increment
    adiw ZL, 2						; inc Z pointer by one word
	sbrc tmp1, 7					; command bit 7 = set Z 
	movw ZL, r0						; set Z pointer
	tst tmp1
    brne CommandLoop				; not done
	; done programming - bootloader falls into SPIxfer forever loop

; SPIxfer subroutine for slave
; stores received data in r1
SPIxfer:
    #ifdef _AVR_IOM328P_H_
    in tmp1, SPCR ; sbis SPCR, SPIF
    sbrs tmp1, SPIF
    rjmp SPIxfer
    # clear SPIF flag (this is auotmatic on 328 when in is called)
    out SPCR, dataOut
    in tmp1, SPDR
    # else
    sbis USISR, USIOIF
    rjmp SPIxfer
    sbi USISR, USIOIF               ; clear USIOIF 
    out USIDR, dataOut				; data out
    in  tmp1, USIBR
    #endif
    ret

; execute program memory command stored in register tmp1
DoSPM:
	lpm dataOut, Z					; lpm even when we don't need to
	rcall SPIxfer 
    out SPMCSR, tmp1
    spm
    ret
