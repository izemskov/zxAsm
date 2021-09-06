;OUT STATIC SCREEN BORDER
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
        LD D,%00000000
LOOP2:  PUSH BC        
LOOP1:  PUSH BC
        CALL SET_SCREEN_ATTR
        POP BC
        DJNZ LOOP1        
        POP BC
        DEC C
        JR NZ,LOOP2

        ; enable UDG
        LD HL,UDG
        LD (23675),HL

        ; output border
        LD DE,BORDS
        LD BC,BORDC-BORDS
        CALL 8252

        LD BC,#0004
        LD DE,#0001
LOOP3:  PUSH BC
        LD A,E
        INC A
        LD (BORDC+7),A
        INC A
        LD (BORDC+22),A
        INC A
        LD (BORDC+37),A
        INC A
        LD (BORDC+52),A
        LD E,A
        PUSH DE

        LD DE,BORDC
        LD BC,BORDE-BORDC
        CALL 8252

        POP DE
        POP BC
        
        DEC C
        JR NZ,LOOP3

        LD DE,BORDE
        LD BC,UDG-BORDE
        CALL 8252
        
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
BORDS  DEFB  22,0,0,16,5
       DEFB  144,145,154,155,155,155,155,155
       DEFB  155,155,158,154,155,155,155,155
       DEFB  155,155,155,155,158,154,155,155
       DEFB  155,155,155,155,155,158,144,145
       DEFB  146,147,16,4,156,157,157,157,157,157
       DEFB  157,157,159,156,157,157,157,157
       DEFB  157,157,157,157,159,156,157,157
       DEFB  157,157,157,157,157,159,16,5,146,147                     

BORDC  DEFB  16,5,148,16,4,149,22,2,30,16,5,148,16,4,149
       DEFB  16,5,152,16,4,153,22,3,30,16,5,152,16,4,153
       DEFB  16,5,152,16,4,153,22,4,30,16,5,152,16,4,153
       DEFB  16,5,150,16,4,151,22,5,30,16,5,150,16,4,151

BORDE  DEFB  16,5
       DEFB  144,145,154,155,155,155,155,155
       DEFB  155,155,158,154,155,155,155,155
       DEFB  155,155,155,155,158,154,155,155
       DEFB  155,155,155,155,155,158,144,145
       DEFB  146,147,16,4,156,157,157,157,157,157
       DEFB  157,157,159,156,157,157,157,157
       DEFB  157,157,157,157,159,156,157,157
       DEFB  157,157,157,157,157,159,16,5,146,147

; Use User Defined Graphics (UDG)
; memory block for store borders part
UDG    DEFB  0,63,64,95,95,95,95,95          ;A (144)
       DEFB  0,252,30,250,250,250,242,242    ;B (145)
       DEFB  95,95,127,127,124,96,63,0       ;C (146)
       DEFB  226,194,130,2,2,2,252,0         ;D (147)
       DEFB  0,63,0,95,107,95,107,95         ;E (148)
       DEFB  0,244,0,208,234,208,234,208     ;F (149)
       DEFB  107,95,107,95,107,0,63,0        ;G (150)
       DEFB  234,208,234,208,234,0,244,0     ;H (151)
       DEFB  107,95,107,95,107,95,107,95     ;I (152)
       DEFB  234,208,234,208,234,208,234,208 ;J (153)
       DEFB  0,31,85,74,95,74,95,95          ;K (154)
       DEFB  0,255,85,170,255,170,255,255    ;L (155)
       DEFB  95,95,85,74,21,64,21,0          ;M (156)
       DEFB  255,255,85,170,85,0,85,0        ;N (157)
       DEFB  0,248,82,170,250,170,250,250    ;O (158)
       DEFB  250,250,82,170,80,2,80,0        ;P (159)
