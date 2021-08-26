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

        ORG #6000   ; start address
        ; save old stack value
        LD (ALASM_STACK),SP
        LD SP,(PROGRAM_STACK)
        ;save old registry values
        PUSH AF
        PUSH BC
        PUSH DE
        
        ; set output stream to screen
        LD A,2      
        CALL 5633

        ; output Hello world string
        LD DE,HELLO_STR
        LD BC,12
        CALL 8252

        ; return old registry values
        POP DE
        POP BC
        POP AF
        ; return old stack value
        LD SP,(ALASM_STACK)
        RET

; GLOBAL VARIABLES AND DATA
PROGRAM_STACK   DEFW #6000
ALASM_STACK     DEFW #0000
HELLO_STR       DEFB "Hello World!",0