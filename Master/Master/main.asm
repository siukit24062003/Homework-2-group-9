.org 0
rjmp main			; Jump to the main routine

.org $0002
rjmp exint0			; Jump to the exint0 routine

main:	
sbi portb, 1		; Set bit 1 of port B
call init_port
call init_lcd
call spiinit
call uartinit
call init_int0

loop:	
cbi portb, 1		; Clear bit 1 of port B
rjmp loop

init_port:
ldi r16, 0b11110111
out ddra, r16
call delay_20ms
ret

init_lcd:
ldi r16, 0x02		; Load 0x02 for LCD initialization
call lcd_command
ldi r16, 0x28		; Load 0x28 for LCD initialization
call lcd_command
ldi r16, 0x0e		; Load 0x0e for LCD initialization
call lcd_command
ldi r16, 0x01		; Load 0x01 for LCD initialization
call lcd_command
ldi r16, 0x80		; Load 0x80 for LCD initialization
call lcd_command
ret

spiinit:
ldi r16, (1 << 5) | (1 << 7) | (1 << 4) | (1 << 1)
out ddrb, r16
ldi r16, (1 << spe0) | (1 << mstr0) | (1 << spr00)
out spcr0, r16
sbi portb, 4
ret

spiout:
cbi portb, 4		; Clear PB4 
out spdr0, r17		; Load data to SPI data register

wait_transmit:
in r16, spsr0
sbrs r16, spif0
rjmp wait_transmit
sbi portb, 1
in r17, spdr0
ret

uartinit:
ldi r16, 12			; load 12 for UART baud rate setting
sts ubrr0l, r16
ldi r16, (1 << u2x0)
sts ucsr0a, r16
ldi r16, (1 << rxen0) | (1 << txen0) ; load the value that is shift 1 bit to the left of receive Enable and rransmit Enable bits to r16 
sts ucsr0b, r16
ldi r16, (1 << ucsz01) | (1 << ucsz00)
sts ucsr0c, r16
ret

uartout:
lds r16, ucsr0a		; load UART control and status register A
sbrs r16, udre0
rjmp uartout		
sts udr0, r17		; coad data to UART data register
ret

data_receive:
lds r16, ucsr0a
sbrs r16, rxc0
rjmp data_receive	; continue waiting for data reception
lds r17, udr0
ret

init_int0:
sei
ldi r16, (1 << isc01)	
sts eicra, r16
ldi r16, (1 << int0)
out eimsk, r16		; set external interrupt mask register
ret

lcd_command:
rcall delay_20ms
mov r18, r16
andi r18, 0xf0
out porta, r18
sbi porta, 2
rcall sdelay
cbi porta, 2
rcall delay_100us

swap r16			; swap the nibbles of the register
andi r16, 0xf0
out porta, r16
sbi porta, 2
rcall sdelay
cbi porta, 2		; clear PA2
rcall delay_100us
ret

lcd_data:
rcall delay_20ms
mov r18, r16
andi r18, 0xf0	
out porta, r18
sbi porta, 0
sbi porta, 2
rcall sdelay
cbi porta, 2
rcall delay_100us

swap r16
andi r16, 0xf0
out porta, r16
sbi porta, 0
sbi porta, 2
rcall sdelay
cbi porta, 2
rcall delay_100us
ret

sdelay:
nop
nop
ret

delay_100us:
push r17			; save r17 on the stack
ldi r17,100			; load 100 for the delay counter
dl1:
call sdelay
dec r17
brne dl1			
pop r17
ret

delay_2ms:
push r17			; save r17 on the stack
ldi r17,20			; load 20 for the delay counter
ldr0:
call delay_100us
dec r17
brne ldr0
pop r17
ret

delay_20ms:
push r17
ldi r17, 10
powerup:
call delay_2ms
dec r17
brne powerup		;if r17 not equal to 0, jump to powerup
pop r17
ret

exint0:
ldi r17, 0
call spiout
sbi portb, 1
cpi r17, 0xff		; compare (CPI) instruction compares register r17 with the immediate value 0xFF.
breq clear
mov r16, r17		; move r17 into r16.
call lcd_data
ldi r16, 0x80
call lcd_command
rjmp next			; rejump to the next subroutine

clear:
ldi r16, 0x01
rcall lcd_command
ldi r16, 0x80
rcall lcd_command
reti

next:
call uartout
reti