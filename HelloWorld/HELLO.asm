;HELLO WORLD IN ZX-SPECTRUM ASSEMBLER
;
;CPU:     Zilog Z80, 3.5MHz
;RAM:     48Kb or 128Kb
;SCREEN:  265x192 pixels,
;         32x24 color attributes
;CTRL:    Keyboard and joystick
;
;AUTHOR:  Ilya Zemskov, 2021
;         pascal.ilya@gmail.com

        ORG 60000

        LD A,2
        CALL 5633

        LD A,22
        RST 16
        LD A,10
        RST 16
        LD A,8
        RST 16

        LD A,"X"
        RST 16

        RET
