;SET SCREEN ATTRIBUTE
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

        LD BC,#151E
        LD D,%00110100
LOOP2:  PUSH BC        
LOOP1:  PUSH BC
        CALL SET_SCREEN_ATTR
        POP BC
        DJNZ LOOP1        
        POP BC
        DEC C
        JR NZ,LOOP2
        
        ; return old registry values
        POP DE
        POP BC
        POP AF
        ; return old stack value
        LD SP,(ALASM_STACK)
        RET

;SET SCREEN ATTRIBUTE FUNCTION
;PARAMETERS:
    ; BC - Y AND X COORDINATES
    ; D  - ATTRIBUTES
    ; 0..3 - Ink
    ; 4..6 - Paper
    ; 5    - Bright
    ; 6    - Flash
SET_SCREEN_ATTR:
        PUSH AF     

        LD A,22
        RST 16
        LD A,B
        RST 16
        LD A,C
        RST 16

        ; Ink
        LD A,D
        AND %00000111
                
        PUSH AF
        LD A,16
        RST 16
        POP AF
        RST 16

        ; Paper
        LD A,D
        AND %00111000
        RRCA
        RRCA
        RRCA
              
        PUSH AF
        LD A,17
        RST 16
        POP AF
        RST 16 

        LD A," "
        RST 16

        POP AF

        RET

; GLOBAL VARIABLES AND DATA
PROGRAM_STACK   DEFW #6000
ALASM_STACK     DEFW #0000