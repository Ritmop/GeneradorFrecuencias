# 1 "macros.s"
# 1 "<built-in>" 1
# 1 "macros.s" 2
bin_to_dec macro binary,decimal_digit
    ;Long division altorithm - https:
    ;Initialize values
    movf binary, W
    movwf count_val
    clrf mod10
    movlw 8
    movwf rotations
    bcf STATUS, 0 ;Clear carry bit

    ;long div
    ;rotate count_val into mod10
    rlf count_val, F
    rlf mod10, F
    ;mod10 - 10
    movlw 10
    subwf mod10, W
    ;Check ~borrow flag
    btfss STATUS, 0
    goto $+2 ;if borrow, goto skip result
    movwf mod10
    ;skip result
    decfsz rotations, F;Decrement rotations left
    goto $-8 ;If rotations left, goto long div (loop)
    ;Store decimal digit
    movf mod10, W
    movwf decimal_digit
    ;Final rotate to prepare next digit
    rlf count_val, F
endm

display7_decode macro binary, decode
   movf binary, W
   call display7_table ;Returns binary code for 7 segment display
   movwf decode
endm

portC_mutiplex macro enPrev, output, enNext
    bcf PORTD, enPrev ;Disable previous device
    movf output, W ;Load output value
    movwf PORTC ;to PortC
    bsf PORTD, enNext ;Enable next device
endm

get_nibbles macro hexa, high_nibble, low_nibble
  movf hexa, W
  andlw 0x0F
  movwf low_nibble
  swapf hexa, W
  andlw 0x0F
  movwf high_nibble
endm
