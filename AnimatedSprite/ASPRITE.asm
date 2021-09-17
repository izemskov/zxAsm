;ANIMATED SPRITE
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
        
        LD HL,SPRITE_ALIEN
        CALL DRAW_SPRITE
        
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
    ; HL - Adress in memory
DRAW_SPRITE:
        PUSH HL
        PUSH DE                                   
                
START_ANIMATION:
        PUSH HL
        
        ; get block counts
        LD D,(HL)        
        INC HL
        ; get frame counts
        LD E,(HL)
        INC HL
        
SPRINT_LOOP:
        ; read coordinates
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        ; read attributes
        LD A,(HL)
        INC HL

FRAME_LOOP:        
        CALL SET_SCREEN_ATTR
        CALL SET_SCREEN_DATA
        
        PUSH BC
        LD BC,8
        ADD HL,BC
        POP BC
        
        PUSH AF
        LD A,15
        CALL IM2_DELAY
        POP AF
        
        DEC E               
        
        JR NZ,FRAME_LOOP
        
        DEC D
        
        JR NZ,SPRINT_LOOP               
        
        POP HL
        
        JR START_ANIMATION
                
        POP DE
        POP HL
        
        RET        

; GLOBAL VARIABLES AND DATA
SPRITE_ALIEN    DEFB 1,2
                DEFB 5,5,69
                DEFB 24,60,126,219,255,36,90,165                
                DEFB 24,60,126,219,255,90,129,66

end_file:

        display "code size: ", /d, end_file - begin_file

        savehob "asprite.$C", "asprite.C", begin_file, end_file - begin_file

        savesna "asprite.sna", begin_file
