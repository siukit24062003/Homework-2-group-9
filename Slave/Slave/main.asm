.org 0

main:
call portinit
call spiinit

loop:
sbic pina, 0
rjmp loop
sbi porta, 1
call scankey
call spiin
rjmp loop

portinit:
ldi r16, 2
out ddra, r16
ldi r16, (1 << 6) | (1 << 1)
out ddrb, r16
ldi r16, 0x0f
out ddrd, r16
ldi r16, 0xf0
out portd, r16
ret

spiinit:
ldi r16, (1 << spe0)
out spcr0, r16
ret

spiin:
out spdr0, r17
cbi porta, 1
sspi_wait_receive:
in r16, spsr0
sbrs r16, spif0
rjmp sspi_wait_receive
sbi porta, 1
ret

scankey:
ldi r20, 0x0f
out portd, r20
ldi r22, 0b11110111
ldi r23, 0
ldi r24, 3

keypad_scan_loop:
out portd, r22
call delay
sbic pind, 4
rjmp keypad_scan_check_col_2
rjmp keypad_scan_found

keypad_scan_check_col_2:
sbic pind, 5
rjmp keypad_scan_check_col_3
ldi r23, 1
rjmp keypad_scan_found

keypad_scan_check_col_3:
sbic pind, 6
rjmp keypad_scan_check_col_4
ldi r23, 2
rjmp keypad_scan_found

keypad_scan_check_col_4:
sbic pind, 7
rjmp keypad_scan_next_row
ldi r23, 3
rjmp keypad_scan_found

keypad_scan_next_row:
cpi r24, 0
breq keypad_scan_not_found
ror r22
dec r24
rjmp keypad_scan_loop

keypad_scan_found:
lsl r23
lsl r23
add r23, r24 ; keypad value in r23
mov r17, r23
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
ldi r16, 0b00001010
sts tccr1b, r16
ldi r16, 0x27
sts ocr1ah, r16
ldi r16, 0x10
sts ocr1al, r16
clr r16
sts tcnt1h, r16
sts tcnt1l, r16

delayloop:
sbis tifr1, ocf1a
rjmp delayloop
sbi tifr1, ocf1a
clr r16
sts tccr1a, r16
sts tccr1b, r16
ret