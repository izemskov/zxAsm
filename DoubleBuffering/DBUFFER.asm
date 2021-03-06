;DOUBLE BUFFERING
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

        CALL SPRITE_ANIMATION
        
        ; return old registry values
        POP HL
        POP DE
        POP BC
        POP AF
        
        RET
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SPRITE ANIMATION FUNCTION ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPRITE_ANIMATION:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        
        ; start position
        LD BC,#0505
        ; start frame
        LD A,1
ANIMATION_LOOP:
        CALL CLEAR_SHADOW_SCREEN

        LD HL,SPRITE_ALIEN
        CALL DRAW_SPRITE
        
        HALT
        CALL COPY_SHADOW_SCREEN
        
        PUSH AF
        LD A,25
        CALL IM2_DELAY
        POP AF               
        
        INC A
        
        CP 3
        JR Z,RESET_FRAME_COUNTER
        JR CONTINUE_ANIMATION
        
RESET_FRAME_COUNTER:
        LD A,1
        
CONTINUE_ANIMATION:
        INC B               
        
        PUSH AF
        LD A,B
        CP 19                
        JR Z,END_ANIMATION                
        POP AF
        
        JR ANIMATION_LOOP
        
END_ANIMATION:
        POP AF
        
        POP HL
        POP DE
        POP BC
        POP AF
        
        RET                
        
        INCLUDE "COMMON.asm"

; GLOBAL VARIABLES AND DATA
SPRITE_ALIEN    DEFB 2,2                
                DEFB 0,0,69
                ; frame 1
                DEFB 24,60,126,219,255,36,90,165
                ; frame 2
                DEFB 24,60,126,219,255,90,129,66
                DEFB 1,0,69                
                ; frame 1
                DEFB 24,60,126,219,255,90,129,66
                ; frame 2
                DEFB 24,60,126,219,255,36,90,165

end_file:

        display "code size: ", /d, end_file - begin_file

        savehob "dbuffer.$C", "dbuffer.C", begin_file, end_file - begin_file

        savesna "dbuffer.sna", begin_file
