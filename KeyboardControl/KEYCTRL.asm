;KEYBOARD CONTROL
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
              
        ; start frame
        LD A,1
        ; start position
        LD HL,PLAYER_COORD
        LD (HL),#05
        INC HL
        LD (HL),#05        
        INC HL
        LD (HL),0
        INC HL
        LD (HL),#05
        INC HL
        LD (HL),#05
        
MAIN_LOOP:
        HALT
        
        ; load player coordinates
        LD HL,PLAYER_COORD
        LD B,(HL)
        INC HL
        LD C,(HL)        
        
        ; check player coordinates changes
        PUSH AF
        
        INC HL
        LD A,(HL)
        CP 1
        JR Z,CLEAR_PLAYER
        JR NOT_CLEAR_PLAYER
        
CLEAR_PLAYER:
        ; for next time
        LD (HL),0
        
        PUSH HL
        PUSH BC               
        
        ; load old coordinates        
        INC HL
        LD B,(HL)
        INC HL
        LD C,(HL)
        LD HL,EMPTY_SPRITE4
        CALL DRAW_SPRITE
        
        POP BC       
        POP HL
        
        INC HL
        LD (HL),B
        INC HL
        LD (HL),C
        
NOT_CLEAR_PLAYER:
        POP AF
                
        LD HL,SPRITE_PLAYER
        CALL DRAW_SPRITE
                       
        ;PUSH AF
        ;LD A,25
        ;CALL IM2_DELAY
        ;POP AF
        
        JR MAIN_LOOP
        
        ; return old registry values
        POP HL
        POP DE
        POP BC
        POP AF
        
        RET
    
;INTERRUPT FUNCTION CALLED EVERY 1/50 SECOND
;USING FOR CHECK KEY PRESSED
IM2:
        DI
        PUSH HL
        PUSH BC                              
        PUSH AF
        
        ; check keys
        ;;;;;;;;;;;;
        ; W - Key
        ;;;;;;;;;;;;
        LD A,251
        IN A,(254)        
        BIT 1,A
        JR Z,P_KEY_W
        JR NP_KEY_W
        
P_KEY_W:
        ; W - pressed
        LD HL,KEY_INFO_W
        LD A,(HL)
        CP 0
        JR Z,MOVE_UP
        JR CONTINUE_P_KEY_W
        
MOVE_UP:        
        PUSH HL
        PUSH AF
        LD HL,PLAYER_COORD
        LD B,(HL)
        LD A,B
        CP 0
        JR Z,BOUND_UP
        DEC B
BOUND_UP:        
        LD (HL),B
        ; set flag to need clear old sprite
        INC HL
        INC HL
        LD (HL),1
        POP AF
        POP HL
        
CONTINUE_P_KEY_W:
        INC A
        CP 10
        JR Z,DROP_KEY_W
        JR WRITE_KEY_W
        
DROP_KEY_W:
        LD A,0

WRITE_KEY_W:
        LD (HL),A
        JR AFTER_PROCESS_W
        
NP_KEY_W:
        LD HL,KEY_INFO_W
        LD (HL),0
        
AFTER_PROCESS_W:
        ;;;;;;;;;;;;
        ; S - Key
        ;;;;;;;;;;;;
        LD A,253
        IN A,(254)        
        BIT 1,A
        JR Z,P_KEY_S
        JR NP_KEY_S
        
P_KEY_S:
        ; S - pressed
        LD HL,KEY_INFO_S
        LD A,(HL)
        CP 0
        JR Z,MOVE_DOWN
        JR CONTINUE_P_KEY_S
        
MOVE_DOWN:        
        PUSH HL
        PUSH AF
        LD HL,PLAYER_COORD
        LD B,(HL)
        LD A,B
        CP 22
        JR Z,BOUND_DOWN
        INC B
BOUND_DOWN:        
        LD (HL),B
        ; set flag to need clear old sprite
        INC HL
        INC HL
        LD (HL),1
        POP AF
        POP HL
        
CONTINUE_P_KEY_S:
        INC A
        CP 10
        JR Z,DROP_KEY_S
        JR WRITE_KEY_S
        
DROP_KEY_S:
        LD A,0

WRITE_KEY_S:
        LD (HL),A
        JR AFTER_PROCESS_S
        
NP_KEY_S:
        LD HL,KEY_INFO_S
        LD (HL),0
        
AFTER_PROCESS_S:
        ;;;;;;;;;;;;
        ; A - Key
        ;;;;;;;;;;;;
        LD A,253
        IN A,(254)        
        BIT 0,A
        JR Z,P_KEY_A
        JR NP_KEY_A
        
P_KEY_A:
        ; A - pressed
        LD HL,KEY_INFO_A
        LD A,(HL)
        CP 0
        JR Z,MOVE_LEFT
        JR CONTINUE_P_KEY_A
        
MOVE_LEFT:        
        PUSH HL
        PUSH AF
        LD HL,PLAYER_COORD
        INC HL
        LD B,(HL)
        LD A,B
        CP 0
        JR Z,BOUND_LEFT
        DEC B
BOUND_LEFT:        
        LD (HL),B
        ; set flag to need clear old sprite
        INC HL        
        LD (HL),1
        POP AF
        POP HL
        
CONTINUE_P_KEY_A:
        INC A
        CP 10
        JR Z,DROP_KEY_A
        JR WRITE_KEY_A
        
DROP_KEY_A:
        LD A,0

WRITE_KEY_A:
        LD (HL),A
        JR AFTER_PROCESS_A
        
NP_KEY_A:
        LD HL,KEY_INFO_A
        LD (HL),0
        
AFTER_PROCESS_A:      
        ;;;;;;;;;;;;
        ; D - Key
        ;;;;;;;;;;;;
        LD A,253
        IN A,(254)        
        BIT 2,A
        JR Z,P_KEY_D
        JR NP_KEY_D
        
P_KEY_D:
        ; D - pressed
        LD HL,KEY_INFO_D
        LD A,(HL)
        CP 0
        JR Z,MOVE_RIGHT
        JR CONTINUE_P_KEY_D
        
MOVE_RIGHT:        
        PUSH HL
        PUSH AF
        LD HL,PLAYER_COORD
        INC HL
        LD B,(HL)
        LD A,B
        CP 30
        JR Z,BOUND_RIGHT
        INC B
BOUND_RIGHT:        
        LD (HL),B
        ; set flag to need clear old sprite
        INC HL        
        LD (HL),1
        POP AF
        POP HL
        
CONTINUE_P_KEY_D:
        INC A
        CP 10
        JR Z,DROP_KEY_D
        JR WRITE_KEY_D
        
DROP_KEY_D:
        LD A,0

WRITE_KEY_D:
        LD (HL),A
        JR AFTER_PROCESS_D
        
NP_KEY_D:
        LD HL,KEY_INFO_D
        LD (HL),0
        
AFTER_PROCESS_D:

        POP AF        
        POP BC
        POP HL
        
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
    ; D  - Mode:
    ;           0 - Simple draw
    ;           
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
        

; GLOBAL VARIABLES AND DATA
SPRITE_PLAYER   DEFB 4,1
                DEFB 0,0,69
                DEFB 0,16,56,48,120,120,103,103
                DEFB 1,0,69
                DEFB 0,8,28,12,30,30,230,230
                DEFB 0,1,69
                DEFB 62,119,71,15,24,16,0,0
                DEFB 1,1,69
                DEFB 124,238,226,240,24,8,0,0
                
EMPTY_SPRITE4   DEFB 4,1
                DEFB 0,0,69
                DEFB 0,0,0,0,0,0,0,0
                DEFB 1,0,69
                DEFB 0,0,0,0,0,0,0,0
                DEFB 0,1,69
                DEFB 0,0,0,0,0,0,0,0
                DEFB 1,1,69
                DEFB 0,0,0,0,0,0,0,0
                
                ; 0,1 - current coordinates
                ; 2   - flag changes coordinates
                ; 3,4 - old coordinates
PLAYER_COORD    DEFB 0,0,0,0,0
                
KEY_INFO_W      DEFB 0
KEY_INFO_S      DEFB 0
KEY_INFO_A      DEFB 0
KEY_INFO_D      DEFB 0

end_file:

        display "code size: ", /d, end_file - begin_file

        savehob "keyctrl.$C", "keyctrl.C", begin_file, end_file - begin_file

        savesna "keyctrl.sna", begin_file
