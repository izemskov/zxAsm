;TELETYPE EFFECT
;
;ASM:     SJASMPLUS v1.18.3
;CPU:     Zilog Z80, 3.5MHz
;RAM:     48Kb or 128Kb
;SCREEN:  265x192 pixels,
;         32x24 color attributes
;CTRL:    Keyboard and joystick
;
;AUTHOR:  Ilya Zemskov, 2021
;         pascal.ilya@gmail.com

        device zxspectrum128

SCREEN_STREAM    EQU 5633
PRINT_STRING     EQU 8252
SCREEN_ATTRIB    EQU #5800
SCREEN_ATTRIB_H  EQU #58

        ORG #6000   ; start address
        ; save old stack value
begin_file:        
        ;save old registry values
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL

        ; set output stream to screen
        LD A,2      
        CALL SCREEN_STREAM
        
        ; wait 5/50 sec        
        ;LD BC,1
        ;CALL #1F3D

        LD A,%00000000
        CALL FILL_BACKGROUND
        
        ; wait 5/50 sec        
        ;LD BC,1
        ;CALL #1F3D
        
        ;LD BC,#0505
        ;LD A,%00101101
        ;CALL SET_SCREEN_ATTR
        
        LD DE,#0505
        LD HL,TTYPE_STR
        CALL TELETYPE_PRINT

        ; return old registry values
        POP HL
        POP DE
        POP BC
        POP AF
        
        RET

;SET SCREEN ATTRIBUTE FUNCTION
;PARAMETERS:    
    ; BC - Y [0..23] AND
    ;      X [0..31]
    ; A  - ATTRIBUTES
    ; 0..3 - Ink
    ; 4..6 - Paper
    ; 5    - Bright
    ; 6    - Flash
; Working with video memory directly.
; For this I need to calculate the 
; offset from start address of video
; memory attributes #5800
; Offset calculate by formula:
;
; OFFSET = Y * 32 + X
;
; But the max Y is 23 and when I
; mult 32 * 23 I will have 8-bit registry
; overflow. For avoid this situation I
; divide Y to two parts:
;
; 00|010|111
;
; and mult it separately
SET_SCREEN_ATTR:        
        PUSH BC
        ; save attribute param (A)
        PUSH AF
        
        ; process low part of Y
        LD A,B
        AND %00000111
        ; for mult on 32 I
        ; can use left shift 5 times
        RLCA
        RLCA
        RLCA
        RLCA
        RLCA
        ; add X to low part of Y
        OR C
        ; all right, just now I have
        ; low part Y + all X in
        ; C registry
        LD C,A
        
        ; process high part of Y
        LD A,B
        AND %00111000
        RLCA
        RLCA
        RLCA
        RLCA
        RLCA
        ; just now I have high part of Y
        ; in accumulator registry
        ;
        ; for get right address in video
        ; memory just add high part
        ; attributes address (#58)
        ; to high part of Y
        OR SCREEN_ATTRIB_H
        ; I have right address in BC
        LD B,A
        ; restore attribute param (A)        
        POP AF
        
        ; write attribute param to
        ; address which stored in BC
        LD (BC),A

        POP BC

        RET

;FILL BACKGROUND FUNCTION
;PARAMETERS:    
    ; A  - ATTRIBUTES
    ; 0..3 - Ink
    ; 4..6 - Paper
    ; 5    - Bright
    ; 6    - Flash
FILL_BACKGROUND:
        PUSH BC
        PUSH DE

        ; count of iterations
        LD BC,#2018
        ; current coordinates
        LD DE,#0000
LOOP2:  PUSH BC
        PUSH DE

LOOP1:  PUSH BC
        LD B,D
        LD C,E
        CALL SET_SCREEN_ATTR
        INC E
        POP BC
        DJNZ LOOP1

        POP DE
        INC D

        POP BC
        DEC C
        JR NZ,LOOP2        

        POP DE
        POP BC

        RET
        
;TELE TYPE OUT STRING FUNCTION
;PARAMETERS:    
    ; HL - Address of string
    ; DE - Y and X  start coordinates
TELETYPE_PRINT:
        PUSH AF
        PUSH BC
        PUSH DE               
        PUSH HL
        
TLOOP:  
        ; set cursor position
        LD A,22
        RST 16
        LD A,D
        RST 16
        LD A,E
        RST 16
        
        ; set cursor attributes
        PUSH DE
        PUSH BC
        
        LD DE,CURSOR_ATTR
        LD BC,4
        CALL PRINT_STRING
        
        POP BC
        POP DE
        
        ; output cursor
        LD A," "
        RST 16
        
        ; wait 5/50 sec        
        ;LD BC,#0000
        ;CALL 7997
        
        ; set symbol position
        LD A,22
        RST 16
        LD A,D
        RST 16
        LD A,E
        RST 16
    
        ; set symbol attributes
        PUSH DE
        PUSH BC
        
        LD DE,SYMBOL_ATTR
        LD BC,4
        CALL PRINT_STRING
        
        POP BC
        POP DE       
        
        ; output symbol
        ; load current symbol from memory
        LD A,(HL)
        ; if 0 then string ended
        CP 0
        JR Z,ENDTLOOP
        RST 16
        INC HL
        INC E
        JP TLOOP
    
ENDTLOOP:    
        POP HL
        POP DE
        POP BC
        POP AF
    
        RET

; GLOBAL VARIABLES AND DATA
TTYPE_STR       DEFB "Tele type string!",0
SYMBOL_ATTR     DEFB 16,4,17,0
CURSOR_ATTR     DEFB 16,0,17,4

end_file:

        display "code size: ", /d, end_file - begin_file

        savehob "ttype.$C", "ttype.C", begin_file, end_file - begin_file

        savesna "ttype.sna", begin_file
