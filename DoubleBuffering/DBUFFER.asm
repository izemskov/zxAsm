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
PRINT_STRING     EQU 8252
SCREEN_ATTRIB    EQU #5800
SCREEN_ATTRIB_H  EQU #58
SCREEN_DATA      EQU #4000
SCREEN_DATA_1_H  EQU #40
SCREEN_DATA_2_H  EQU #48
SCREEN_DATA_3_H  EQU #50
SCREEN_DATA_SIZE EQU #1800
IM2_I_REG        EQU #5B
IM2_B_DATA       EQU #FF
SHADOW_SCREEN    EQU #8000


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
        
;;;;;;;;;;;;;;;;; SIMPLE SCREEN FILL ;;;;;;;;;;;;;;;;;        
        
        LD BC,SCREEN_DATA_SIZE
        LD HL,SCREEN_DATA
TEST_SCREEN_LOOP:        
        LD (HL),%10101010
        INC HL  
        LD A,2
        CALL IM2_DELAY
        DEC BC
        LD A,B
        OR C
        JR NZ,TEST_SCREEN_LOOP
        
;;;;;;;;;;;;;;;;; SIMPLE SCREEN FILL ;;;;;;;;;;;;;;;;;                

;;;;;;;;;;;;;;;;; DOUBLE BUFFERING SCREEN FILL ;;;;;;;;;;;;;;;;;
        
        ;LD BC,SCREEN_DATA_SIZE
        ;LD HL,SHADOW_SCREEN
;TEST_SCREEN_LOOP:        
        ;LD (HL),%10101010
        ;INC HL  
        ;LD A,2
        ;CALL IM2_DELAY
        
        ;CALL COPY_SHADOW_SCREEN
        
        ;DEC BC
        ;LD A,B
        ;OR C
        ;JR NZ,TEST_SCREEN_LOOP               
        
;;;;;;;;;;;;;;;;; DOUBLE BUFFERING SCREEN FILL ;;;;;;;;;;;;;;;;;

        ;CALL SPRITE_ANIMATION
        
        ; return old registry values
        POP HL
        POP DE
        POP BC
        POP AF
        
        RET
    
;INTERRUPT FUNCTION CALLED EVERY 1/50 SECOND    
IM2:
        DI
        EI
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
        
;DELAY FUNCTION
;PARAMETERS:
    ; A - Delay in 1/50 seconds
IM2_DELAY:
        PUSH AF
        
DLOOP:  HALT
        DEC A
        JR NZ,DLOOP
        
        POP AF
        
        RET
        
;SET SCREEN DATA FUNCTION
;PARAMETERS:    
    ; BC - Y [0..23] AND
    ;      X [0..31]
    ; HL - Adress in memory
SET_SCREEN_DATA:        
        PUSH BC        
        PUSH AF
        PUSH HL
        PUSH DE
        
        ; calc right addree in video memory
        ; from row 8 spectrum memory have jump
        ; to 256 bytes        
        LD A,B
        CP 8
        JR C,SCREEN_DATA_PART1
        CP 16
        JR C,SCREEN_DATA_PART2
        JR SCREEN_DATA_PART3
        
SCREEN_DATA_SADDR:
        ; in D I have correct video memory addr
        
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
                       
        OR D
        ; I have right address in BC
        LD B,A
        
        ; write data to address which stored in BC
        LD D,8
SCREEN_DATA_LOOP:        
        LD A,(HL)
        LD (BC),A
        
        PUSH HL
        LD HL,BC
        LD BC,256
        ADD HL,BC
        LD BC,HL
        POP HL
        
        INC HL

        DEC D
        
        JR NZ,SCREEN_DATA_LOOP
        
        JR SCREEN_DATA_END
        
SCREEN_DATA_PART1:
        LD D,SCREEN_DATA_1_H        
        JR SCREEN_DATA_SADDR
        
SCREEN_DATA_PART2:
        LD D,SCREEN_DATA_2_H        
        SUB 8
        LD B,A
        JR SCREEN_DATA_SADDR

SCREEN_DATA_PART3:
        LD D,SCREEN_DATA_3_H
        SUB 16
        LD B,A
        JR SCREEN_DATA_SADDR        
        
SCREEN_DATA_END:

        POP DE
        POP HL
        POP AF
        POP BC

        RET        

;DRAW SPRITE FUNCTION
;PARAMETERS:
    ; A  - Current frame
    ; BC - Y and X coordinates
    ; HL - Sprite address
DRAW_SPRITE:
        PUSH AF
        PUSH BC
        PUSH HL
        PUSH DE
        
        ; get block counts
        LD D,(HL)
        INC HL
        
        ; frame counts
        LD E,(HL)
        INC HL

START_DRAW_SP_FRAME:
        ; save sprite coordinates
        PUSH BC
        ; save current frame
        PUSH AF        
        
        ; read coordinates
        LD A,(HL)
        ADD A,C
        LD C,A
        INC HL
        
        LD A,(HL)
        ADD A,B
        LD B,A
        INC HL
        
        ; restore current frame
        POP AF
        
        ; save current frame
        PUSH AF
        
        ; save current coordinates
        PUSH BC
        
        ; read attributes
        LD B,(HL)
        INC HL
                
        ; skip frames to current       
        ; just now in A registry I have current frame
        PUSH DE
        LD E,1
START_SKIP_FRAME:
        CP E
        JR NZ,SKIP_FRAME
        JR END_SKIP_FRAME
        
SKIP_FRAME:
        PUSH BC
        LD BC,8
        ADD HL,BC
        POP BC
        INC E
        JR START_SKIP_FRAME
        
END_SKIP_FRAME:
        POP DE
        
        ; write attributes
        LD A,B

        ; restore cordinates
        POP BC
        
        CALL SET_SCREEN_ATTR
        CALL SET_SCREEN_DATA
        
        ; shift outed frame
        LD BC,8
        ADD HL,BC
        
        ; restore current frame
        POP AF
        
        ; save current frame
        PUSH AF        
        
        ; skip other frames
START_SKIP_FRAME2:        
        CP E
        JR NZ,SKIP_FRAME2
        JR END_SKIP_FRAME2
        
SKIP_FRAME2:        
        LD BC,8
        ADD HL,BC
        INC A
        JR START_SKIP_FRAME2
        
END_SKIP_FRAME2:               
        ; restore current frame
        POP AF

        ; restore sprite coordinates
        POP BC
        
        DEC D
        JR NZ,START_DRAW_SP_FRAME        

        POP DE
        POP HL
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
        LD HL,SPRITE_ALIEN
        CALL DRAW_SPRITE
        
        PUSH AF
        LD A,25
        CALL IM2_DELAY
        POP AF
        
        PUSH HL
        PUSH AF
        PUSH BC
        LD A,1
        LD HL,EMPTY_SPRITE
        CALL DRAW_SPRITE
        INC C
        CALL DRAW_SPRITE
        POP BC
        POP AF
        POP HL
        
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
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
; COPY SHADOW SCREEN TO MAIN SCREEN FUNCTION ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COPY_SHADOW_SCREEN:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        
        LD BC,SCREEN_DATA_SIZE
        LD HL,SHADOW_SCREEN
        LD DE,SCREEN_DATA
        LDIR
        
        POP HL
        POP DE
        POP BC
        POP AF
        
        RET

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

EMPTY_SPRITE    DEFB 1,1
                DEFB 0,0,69                
                DEFB 0,0,0,0,0,0,0,0

end_file:

        display "code size: ", /d, end_file - begin_file

        savehob "dbuffer.$C", "dbuffer.C", begin_file, end_file - begin_file

        savesna "dbuffer.sna", begin_file
