;PASS PARAMETER TO FUNCTION THROUGH STACK
;
;ASM:     ALASM v5.07
;CPU:     Zilog Z80, 3.5MHz
;RAM:     48Kb or 128Kb
;SCREEN:  265x192 pixels,
;         32x24 color attributes
;CTRL:    Keyboard and joystick
;
;AUTHOR:  Ilya Zemskov, 2021
;         pascal.ilya@gmail.com

SCREEN_STREAM    EQU 5633
PRINT_STRING     EQU 8252

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
        CALL SCREEN_STREAM
        
        ; call print text
        LD BC,HELLO_STR
        PUSH BC
        LD BC,12
        PUSH BC
        CALL PRINT_TEXT
        LD BC,HELLO_STR
        PUSH BC
        LD BC,12
        PUSH BC
        CALL PRINT_TEXT

        ; return old registry values
        POP DE
        POP BC
        POP AF
        ; return old stack value
        LD SP,(ALASM_STACK)
        RET

;PRINT TEXT FUNCTION
;ATTRIBUTES:
;   1 - address of string
;   2 - count string symbols
PRINT_TEXT:
        POP AF      ; get ret address
        POP BC
        POP DE
        ; return ret address to stack head
        PUSH AF

        CALL PRINT_STRING
       
        RET

; GLOBAL VARIABLES AND DATA
PROGRAM_STACK   DEFW #6000
ALASM_STACK     DEFW #0000
HELLO_STR       DEFB "Hello World!",0