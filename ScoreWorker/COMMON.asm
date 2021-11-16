;COMMON FUNCTIONS
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

SCREEN_ATTRIB_H   EQU #58

SCREEN_DATA       EQU #4000
SCREEN_DATA_1_H   EQU #40
SCREEN_DATA_2_H   EQU #48
SCREEN_DATA_3_H   EQU #50

SCREEN_DATA_SIZE  EQU #1800

SHADOW_SCREEN     EQU #8000
SHADOW_SCREEN_1_H EQU #80
SHADOW_SCREEN_2_H EQU #88
SHADOW_SCREEN_3_H EQU #90

EMPTY_SCREEN      EQU #9800

IM2_I_REG        EQU #5B
IM2_B_DATA       EQU #FF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; SCREEN WORKING ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SET SCREEN ATTRIBUTE FUNCTION ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SET SCREEN DATA FUNCTION ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
        LD D,SHADOW_SCREEN_1_H        
        JR SCREEN_DATA_SADDR
        
SCREEN_DATA_PART2:
        LD D,SHADOW_SCREEN_2_H        
        SUB 8
        LD B,A
        JR SCREEN_DATA_SADDR

SCREEN_DATA_PART3:
        LD D,SHADOW_SCREEN_3_H
        SUB 16
        LD B,A
        JR SCREEN_DATA_SADDR        
        
SCREEN_DATA_END:

        POP DE
        POP HL
        POP AF
        POP BC

        RET
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FILL BACKGROUND FUNCTION ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; SPRITE WORKING ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;
; DRAW SPRITE FUNCTION ;
;;;;;;;;;;;;;;;;;;;;;;;;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; SHADOW SCREEN WORKING ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               
;;;;;;;;;;;;;;;;;;;;;;;        
; COPY SHADOW SCREEN  ;
;;;;;;;;;;;;;;;;;;;;;;;
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

;;;;;;;;;;;;;;;;;;;;;;;;
; PREPARE_EMPTY_SCREEN ;
;;;;;;;;;;;;;;;;;;;;;;;;
PREPARE_EMPTY_SCREEN:
        PUSH BC
        PUSH HL
        PUSH AF
        
        LD BC,SCREEN_DATA_SIZE
        LD HL,EMPTY_SCREEN
FILL_EMPTY_SCREEN_LOOP:        
        LD (HL),%00000000
        INC HL  
        DEC BC
        LD A,B
        OR C
        JR NZ,FILL_EMPTY_SCREEN_LOOP        
        
        POP AF
        POP HL
        POP BC

        RET

;;;;;;;;;;;;;;;;;;;;;;;
; CLEAR_SHADOW_SCREEN ;
;;;;;;;;;;;;;;;;;;;;;;;
CLEAR_SHADOW_SCREEN:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        
        LD BC,SCREEN_DATA_SIZE
        LD HL,EMPTY_SCREEN
        LD DE,SHADOW_SCREEN
        LDIR
        
        POP HL
        POP DE
        POP BC
        POP AF

        RET
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; INTERRUPTION WORKING ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INTERRUPT FUNCTION CALLED EVERY 1/50 SECOND ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IM2:
        DI
        EI
        RET
        
;;;;;;;;;;;;;;;;;;
; DELAY FUNCTION ;
;;;;;;;;;;;;;;;;;;
;PARAMETERS:
    ; A - Delay in 1/50 seconds
IM2_DELAY:
        PUSH AF
        
DLOOP:  HALT
        DEC A
        JR NZ,DLOOP
        
        POP AF
        
        RET        
        