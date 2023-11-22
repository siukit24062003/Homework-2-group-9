.org 0

main:
call portinit		; call portinit subroutine
call spiinit

loop:
sbic pina, 0		; skip if bit 0 is pina is clear
rjmp loop			; rejump to loop subroutine
sbi porta, 1
call scankey
call spiin
rjmp loop

portinit:
ldi r16, 2			; load 2 to r16
out ddra, r16
ldi r16, (1 << 6) | (1 << 1)	; load binary value 01000010 into register r16
out ddrb, r16
ldi r16, 0x0f
out ddrd, r16		; set data direction register D to configure pins 7-4 as outputs
ldi r16, 0xf0		; load 0xf0 to r16
out portd, r16
ret

spiinit:
ldi r16, (1 << spe0)	; load the value that shift left 1 bit of spe0 to r16
out spcr0, r16			
ret

spiin:
out spdr0, r17
cbi porta, 1
sspi_wait_receive:
in r16, spsr0
sbrs r16, spif0
rjmp sspi_wait_receive	; rejump to sspi_wait_receive subroutine
sbi porta, 1
ret

scankey:
ldi r20, 0x0f
out portd, r20
ldi r22, 0b11110111		; load  247 to r22
ldi r23, 0				; load 0 to r23
ldi r24, 3

keypad_scan_loop:
out portd, r22
call delay
sbic pind, 4					; skip if bit 4 of pind is clear
rjmp keypad_scan_check_col_2	; rejump to keypad_scan_check_col_2 subroutine
rjmp keypad_scan_found

keypad_scan_check_col_2:
sbic pind, 5					; skip if bit 5 of pind is clear
rjmp keypad_scan_check_col_3
ldi r23, 1
rjmp keypad_scan_found

keypad_scan_check_col_3:
sbic pind, 6					; skip if bit 6 of pind is clear
rjmp keypad_scan_check_col_4
ldi r23, 2
rjmp keypad_scan_found

keypad_scan_check_col_4:
sbic pind, 7					; skip if bit 7 of pind is clear
rjmp keypad_scan_next_row
ldi r23, 3
rjmp keypad_scan_found

keypad_scan_next_row:
cpi r24, 0
breq keypad_scan_not_found
ror r22							; rotate right rhrough rarry on register r22
dec r24
rjmp keypad_scan_loop

keypad_scan_found:
; left shift the contents of register r23 twice to position the keypad value
lsl r23
lsl r23
add r23, r24 ; keypad value in r23
mov r17, r23 ; move r23 to r17 
cpi r17, 10
brlo digit
subi r17, -87
ret
digit:
subi r17, -48
ret

keypad_scan_not_found:
ldi r17, 0xff
ret

delay:
ldi r16, 0b00001010			 ; load the binary value 00001010 into register r16
sts tccr1b, r16					
ldi r16, 0x27				 ; load 0x27 to r16
sts ocr1ah, r16					
ldi r16, 0x10
sts ocr1al, r16
clr r16
sts tcnt1h, r16
sts tcnt1l, r16

delayloop:
sbis tifr1, ocf1a			; skip if bit 1 of timer/counter interrupt flag register 1 is set
rjmp delayloop
sbi tifr1, ocf1a
clr r16
sts tccr1a, r16
sts tccr1b, r16
ret