.segment "EXTRA"
.export MONRDKEY_NB, MONRDKEY, MONCOUT, INITUSBSERIAL

VIA_USB_REG_DDRB  := $7FE2
VIA_USB_REG_DDRA  := $7FE3
VIA_USB_REG_PORTB := $7FE0
VIA_USB_REG_PORTA := $7FE1
VIA_USB_NRD       := %00001000 ; make RD# high to not output data from FTDI
VIA_USB_WR        := %00000100 ; make WR  high to output data from FTDI
VIA_USB_nRXF      := %00000010
VIA_USB_DDRB_INIT := (VIA_USB_NRD+VIA_USB_WR)

; INIT: Set up outputs and block reading characters from FTDI
INITUSBSERIAL:
        lda #(VIA_USB_NRD+VIA_USB_WR) ; Make these outputs
        sta VIA_USB_REG_DDRB ; to DDRB
        lda #VIA_USB_NRD ; Block RD, no WR
        sta VIA_USB_REG_PORTB ; to REGB
        rts

MONRDKEY_NB:
READCHAR:
        lda VIA_USB_REG_PORTB
        and #VIA_USB_nRXF

        bne READCHAR_NOTHINGTOREAD ; Z=0 -> had no result

        ; Reset DDRA as input
        lda #$00   ; 0x00
        sta VIA_USB_REG_DDRA ; to Directory Data (all in)

        lda #0 ; DO RD, no WR
        sta VIA_USB_REG_PORTB ; to REGB


        lda VIA_USB_REG_PORTA

        ; Save on stack temporrily
        pha

        lda #VIA_USB_NRD ; Block RD, no WR
        sta VIA_USB_REG_PORTB ; to REGB

        ; Get character back
        pla
        sec
        rts

READCHAR_NOTHINGTOREAD:
        clc
        rts

MONRDKEY:
        php
@MONRDKEYREREAD:
        jsr MONRDKEY_NB
        bcc @MONRDKEYREREAD
        ; Enable to echo back
        ; jsr SENDCHAR
        plp
        rts

MONCOUT:
        ; TXE SHOULD be read before sending, but since the USB connection is
        ; running full speed this buffer has not been seen filling up.

        ; Save A for when returning
        pha

        ; Output character
        sta VIA_USB_REG_PORTA ; to data

        lda #VIA_USB_NRD      ; Block RD, no WR
        sta VIA_USB_REG_PORTB ; to REGB

        lda #$FF
        sta VIA_USB_REG_DDRA  ; (all out)

        ; Pulse WR
        lda #(VIA_USB_NRD+VIA_USB_WR) ; Block RD, DO WR
        sta VIA_USB_REG_PORTB         ; to REGB
        lda #VIA_USB_NRD              ; Block RD, no WR
        sta VIA_USB_REG_PORTB         ; to REGB

        ; Reset DDRA as input
        lda #$00
        sta VIA_USB_REG_DDRA ; to Directory Data (all in)

        ; Restore Accumulator
        pla
        rts

