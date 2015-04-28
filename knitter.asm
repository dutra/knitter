
.org 0x0
    ljmp start


.org 0x100
start:
    mov P1, #0x00
    lcall init
    mov A, #'A'
    lcall sndchr
hang:
    sjmp hang



init:
    mov tmod, #0x20		; set timer 1 for auto reload - mode 2
    mov tcon, #0x40		; run timer 1 ; set TCON.6
    mov th1,  #0xfd		; set 9600 baud with xta1=11.059mhz
    mov scon, #0x50		; set serial control reg for 8 bit data
    ret


; ----------------------------------------------------------------------------------------------------------
; Writes character from ACC into Serial Port
; ----------------------------------------------------------------------------------------------------------
sndchr:
	clr ti		; sent interrupt flag
	mov sbuf, a
txloop:
	jnb ti, txloop
	ret
