;SCORE WORKER
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

        ORG #6000   ; start address
        ; save old stack value
begin_file:        
        ; save old registry values
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        
        ; enable im2 interrupt
        PUSH AF
        PUSH DE
        PUSH HL
        
        DI
        
        ; HL - IM2 addr
        LD H,IM2_I_REG
        LD L,IM2_B_DATA
        LD A,H
        LD I,A
        
        ; load callback to addres in HL
        ; in reverse order
        ; (in registry big endian in memory little endian)
        LD DE,IM2
        LD (HL),E
        INC HL
        LD (HL),D

        ; enable IM2 interrupt
        IM 2
        
        EI
        
        POP HL
        POP DE
        POP AF

        ; set output stream to screen
        LD A,2      
        CALL SCREEN_STREAM
        
        LD A,%01000101
        CALL FILL_BACKGROUND
        
        CALL PREPARE_EMPTY_SCREEN
        
        CALL DRAW_SCORE
        
        ; return old registry values
        POP HL
        POP DE
        POP BC
        POP AF
        
        RET
        
;;;;;;;;;;;;;;
; DRAW SCORE ;
;;;;;;;;;;;;;;
DRAW_SCORE:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        
        CALL CLEAR_SHADOW_SCREEN
        
        ; loop counter
        LD B,4
        ; x position
        LD D,5
        LD HL,SCORES
SCORE_LOOP:
        LD A,(HL)
        INC A
        INC HL
        
        PUSH HL
        PUSH BC
        
        ; coords
        LD B,#05
        LD C,D
        INC D
        
        LD HL,NUMBER
        CALL DRAW_SPRITE
        
        POP BC
        POP HL                            

        DJNZ SCORE_LOOP
                                
        HALT
        CALL COPY_SHADOW_SCREEN
        
        POP HL
        POP DE
        POP BC
        POP AF

        RET
        
        INCLUDE "COMMON.asm"

; GLOBAL VARIABLES AND DATA
NUMBER  DEFB 1,10
        DEFB 0,0,69
        DEFB 0,60,102,110,118,102,60,0   ; 0
        DEFB 0,24,56,24,24,24,60,0       ; 1
        DEFB 0,60,102,6,60,96,126,0      ; 2
        DEFB 0,60,102,12,6,102,60,0      ; 3
        DEFB 0,12,28,44,76,126,12,0      ; 4
        DEFB 0,124,96,124,6,70,60,0      ; 5
        DEFB 0,60,96,124,102,102,60,0    ; 6
        DEFB 0,126,6,12,24,48,48,0       ; 7
        DEFB 0,60,102,60,102,102,60,0    ; 8
        DEFB 0,60,102,102,62,6,60,0      ; 9
        
SCORES  DEFB 5,3,6,4

end_file:

        display "code size: ", /d, end_file - begin_file

        savehob "score.$C", "score.C", begin_file, end_file - begin_file

        savesna "score.sna", begin_file
