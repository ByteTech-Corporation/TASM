; SETUP COLORS AND FONT
LDA #$00     ; Black Background
STA $D020

LDX #<green_text_colors  ; Green Text
LDY #>green_text_colors
STY $DD00
STX $DD01

; SWITCH TO LOWERCASE FONT
LDA #<lowercase_chars
STA $FC
LDA #>lowercase_chars
STA $FD

; FILL THE SCREEN WITH RANDOM LETTERS
ldx #0       ; Initialize row counter
loop_row:    stx zp_row          ; Store row number
             ldy #0             ; Reset column counter
loop_col:   jsr rand_char
             sta (zp_ptr), y    ; Place character on screen
             iny                ; Move to next column
             cpy #40            ; Check if reached edge of screen
             bne loop_col       ; If not, continue

             inc zp_row         ; Otherwise move to next row
             ldx zp_row
             cpx #25           ; Stop once bottom row is filled
             bne loop_row

; Clean exit
jmp $EA31    ; Warm reset

; DATA AREA
green_text_colors:
.word $000D

lowercase_chars:
.byte %01000000, $97 ; Character set definition follows...

; ZERO PAGE VARIABLES
zp_row = $fb
zp_ptr = $f9
zp_hi = $f7
zp_lo = $f6

; SUBROUTINES
rand_char:
; Generate a random character (uppercase or lowercase)

; Randomize high byte
lda $dd01      ; Get lo part of green_text_colors address
sta zp_lo      ; Copy to temp storage

lda $dd00      ; Get hi part of green_text_colors address
and #%00000111 ; Mask bits to ensure valid bank selection
ora #%11100000 ; Apply bank selector bits
sta zp_hi      ; Store new hi part to temporary storage

; Choose either lowercase or uppercase
lda $fd      ; Get lo part of lowercase font address
bit zp_row   ; Test bitwise against row number
beq choose_lowercase ; Branch if odd
lda $fc      ; Even -> select uppercase
choose_lowercase:
ldy #0       ; Prepare to read character data
lda (zp_hi), y ; Retrieve character data
sta zp_ptr   ; Keep track of selected char

; Loop to sum high and low parts of character data
lda zp_ptr
ror          ; Rotate lowest bit into carry flag
rol zp_ptr+1 ; Roll highest bit leftwards
ror          ; Restore initial state
clc
adc zp_ptr   ; Sum shifted data with unchanged copy
sta zp_ptr   ; Overwrite old value

; Compensate for rounding error caused by rotation
inc zp_ptr+1 ; Increase higher byte
bne skip_carry_compensation ; Skip if overflow didn't occur
dec zp_ptr   ; Decrease lower byte instead
skip_carry_compensation:
rts
