
.org 0x000
    ljmp start

.org 0x003          ; External Interrupt 0 P3.2
ljmp INT0_ISR
.org 0x013          ; External Interrupt 1 P3.3
ljmp INT1_ISR

.org 0x100
start:
    lcall init
    lcall print
   .db 0dh, 0ah,"Press a key to continue...", 0xD, 0xA, 0x0
    lcall getchr
    lcall init_ex
    lcall print
   .db "Starting...", 0xD, 0xA, 0x0

   jb P1.1, v1_high
   jnb P1.1, v1_low

v1_high:
    jnb P1.2, v1_high_loop       ; if V2 is LOW when V1 goes from LOW to HIGH, do nothing
    inc R0              ; otherwise going right, increase needle
    lcall print_needle
v1_high_loop:
    jnb P1.1, v1_low        ; branches if V1 is LOW
    sjmp v1_high_loop


v1_low:
    jnb P1.2, v1_low_loop       ; if V2 is LOW when V1 goes from HIGH to LOW, do nothing
    dec R0              ; otherwise going left, decrease needle
    lcall print_needle
v1_low_loop:
    jb P1.1, v1_high        ; branches if V1 is HIGH
    sjmp v1_low_loop

hang:
    sjmp hang

INT0_ISR:       ;; Left Hall Sensor
    mov R0, #1
    lcall print
   .db "Setting needle to 01", 0xD, 0xA, 0h
    reti

INT1_ISR:   ;; Right Hall Sensor
    mov R0, #200
    lcall print
   .db "Setting needle to 200.", 0xD, 0xA, 0h
    reti

init:
    mov P1, #0xFF
    mov R0, #0x00           ; hold needle number
    ;; initialize serial port
    mov tmod, #0x20		; set timer 1 for auto reload - mode 2
    mov tcon, #0x40		; run timer 1 ; set TCON.6
    mov th1,  #0xfd		; set 9600 baud with xta1=11.059mhz
    mov scon, #0x50		; set serial control reg for 8 bit data
    ret

init_ex:
    ;; initialize External Interrupt 0
    setb IT0                ; interrupt is edge triggered (high to low)
    setb EX0
    ;; initialize External Interrupt 1
    setb IT1                ; interrupt is edge triggered (high to low)
    setb EX1
    setb EA
    ret

;=============================================================
; Print needle number
;=============================================================
print_needle:
    mov A, R0
    lcall prthex
    mov A, #0xD
    lcall sndchr
    mov A, #0xA
    lcall sndchr

    ret

;=============================================================
; Reads character from serial port and stores it into ACC
;=============================================================
getchr:
    jnb ri, getchr	; receive interrupt flag
    mov a, sbuf
;    anl a, 0x7f
    clr ri
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

; ----------------------------------------------------------------------------------------------------------
; Writes string to serial port
; ----------------------------------------------------------------------------------------------------------
print:
   pop   dph              ; put return address in dptr
   pop   dpl
prtstr:
   clr  a                 ; set offset = 0
   movc a,  @a+dptr       ; get chr from code memory
   cjne a,  #0h, mchrok   ; if termination chr, then return
   sjmp prtdone
mchrok:
   lcall sndchr           ; send character
   inc   dptr             ; point at next character
   sjmp  prtstr           ; loop till end of string
prtdone:
   mov   a,  #1h          ; point to instruction after string
   jmp   @a+dptr          ; return
;=============================================================
; subroutine crlf
; crlf sends a carriage return line feed out the serial port
;=============================================================
crlf:
   mov   a,  #0ah         ; print lf
   lcall sndchr
cret:
   mov   a,  #0dh         ; print cr
   lcall sndchr
   ret

;=============================================================
; subroutine prthex
; this routine takes the contents of the acc and prints it out
; as a 2 digit ascii hex number.
;=============================================================
prthex:
   push acc
   lcall binasc           ; convert acc to ascii
   lcall sndchr           ; print first ascii hex digit
   mov   a,  b           ; get second ascii hex digit
   lcall sndchr           ; print it
   pop acc
   ret
;=============================================================
; subroutine binasc
; binasc takes the contents of the accumulator and converts it
; into two ascii hex numbers.  the result is returned in the
; accumulator and r2.
;=============================================================
binasc:
   mov   b, a            ; save in b
   anl   a,  #0fh         ; convert least sig digit.
   add   a,  #0f6h        ; adjust it
   jnc   noadj1           ; if a-f then readjust
   add   a,  #07h
noadj1:
   add   a,  #3ah         ; make ascii
   xch   a,  b           ; put result in reg 2
   swap  a                ; convert most sig digit
   anl   a,  #0fh         ; look at least sig half of acc
   add   a,  #0f6h        ; adjust it
   jnc   noadj2           ; if a-f then re-adjust
   add   a,  #07h
noadj2:
   add   a,  #3ah         ; make ascii
   ret
