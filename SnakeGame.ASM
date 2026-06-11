; =====================================================
; COAL PROJECT: SNAKE GAME (8086 ASSEMBLY)
; Platform  : DOS / DOSBox
; Assembler : TASM / MASM
; Description:
;   Classic Snake game implemented in 8086 assembly.
;   Uses BIOS and DOS interrupts for input and display.
; =====================================================

.MODEL SMALL
.STACK 100h

.DATA

; ---------------- CONSTANTS ---------------------------
MAXLEN      EQU 100        ; Maximum possible snake length
SCREEN_W    EQU 80         ; Screen width in text mode
SCREEN_H    EQU 25         ; Screen height in text mode

; ---------------- SNAKE STATE -------------------------
SnakeX      DB MAXLEN DUP(0)   ; X coordinates of snake segments
SnakeY      DB MAXLEN DUP(0)   ; Y coordinates of snake segments
SnakeLen    DB 5               ; Initial snake length
AteFood     DB 0               ; Flag set when food is eaten
PrevTailX   DB 0               ; Stores previous tail X for erasing
PrevTailY   DB 0               ; Stores previous tail Y for erasing
Dir         DB 0               ; Direction:
                               ; 0 = Right, 1 = Left
                               ; 2 = Up,    3 = Down

; ---------------- FOOD POSITION -----------------------
FoodX       DB 0               ; X coordinate of food
FoodY       DB 0               ; Y coordinate of food

; ---------------- SCORE -------------------------------
Score       DW 0               ; Player score

; ---------------- TEXT MESSAGES -----------------------
StartMsg1   DB "SNAKE GAME (COAL PROJECT)$"
StartMsg2   DB "Use Arrow Keys or W A S D$"
StartMsg3   DB "Press any key to start...$"
GameOverMsg DB "GAME OVER!$"
ScoreMsg    DB "Score: $"
ExitMsg     DB "Press any key to exit...$"

.CODE

; =====================================================
; PROGRAM ENTRY POINT
; Initializes data segment and starts the game loop
; =====================================================
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

    CALL StartScreen     ; Display start screen and wait for key
    CALL InitGame        ; Reset game state and draw initial frame

MainLoop:
    CALL ReadInput       ; Read keyboard input (non-blocking)
    CALL MoveSnake       ; Update snake position
    CALL CheckCollision  ; Detect wall or food collision
    CALL DrawSnakeFrame  ; Draw snake and food
    CALL Delay           ; Control game speed
    JMP MainLoop         ; Repeat game loop

GameEnd:
    CALL ShowGameOver    ; Display Game Over screen
    MOV AH,4Ch
    INT 21h              ; Exit to DOS
MAIN ENDP

; =====================================================
; INITGAME
; Purpose:
;   Fully resets the game state before starting.
;   Explicitly initializes snake coordinates to prevent
;   uninitialized memory from causing display bugs.
; =====================================================
InitGame PROC

    ; Reset game variables
    MOV SnakeLen,5
    MOV Score,0
    MOV Dir,0
    MOV AteFood,0

    ; Clear entire snake coordinate arrays
    ; This avoids leftover values from memory
    MOV CX,MAXLEN
    XOR SI,SI
ClearArrays:
    MOV SnakeX[SI],0
    MOV SnakeY[SI],0
    INC SI
    LOOP ClearArrays

    ; Reset screen using 80x25 text mode
    MOV AX,0003h
    INT 10h

    CALL DrawWalls       ; Draw game boundaries

    ; Initialize snake at screen center
    ; Explicit coordinates prevent "ghost O" at (0,0)
    MOV SnakeX[0], 40    ; Head
    MOV SnakeY[0], 12

    MOV SnakeX[1], 39    ; Body segment 1
    MOV SnakeY[1], 12

    MOV SnakeX[2], 38    ; Body segment 2
    MOV SnakeY[2], 12

    MOV SnakeX[3], 37    ; Body segment 3
    MOV SnakeY[3], 12

    MOV SnakeX[4], 36    ; Tail
    MOV SnakeY[4], 12

    CALL CreateFood      ; Generate initial food position
    CALL DrawSnakeFrame  ; Draw initial snake and food
    RET
InitGame ENDP

; =====================================================
; DRAW WALLS
; Draws a rectangular boundary around the screen
; using '#' characters.
; =====================================================
DrawWalls PROC

    ; ---------- Draw Top Wall (Row 0) ----------
    MOV DH,0            ; Row = 0 (top of screen)
    MOV DL,0            ; Column = 0 (start from left)

TopWall:
    MOV BH,0            ; Video page 0
    MOV AH,02h          ; Set cursor position
    INT 10h

    PUSH CX             ; Preserve CX (used by caller)
    MOV AL,'#'          ; Character to draw
    MOV BL,07h          ; Attribute: light gray on black
    MOV BH,0
    MOV CX,1            ; Print one character
    MOV AH,09h          ; Write character & attribute
    INT 10h
    POP CX              ; Restore CX

    INC DL              ; Move to next column
    CMP DL,79           ; Until right edge of screen
    JNE TopWall


    ; ---------- Draw Bottom Wall (Row 24) ----------
    MOV DH,24           ; Bottom row
    MOV DL,0            ; Start from left column

BottomWall:
    MOV BH,0
    MOV AH,02h          ; Set cursor position
    INT 10h

    PUSH CX
    MOV AL,'#'
    MOV BL,07h
    MOV BH,0
    MOV CX,1
    MOV AH,09h
    INT 10h
    POP CX

    INC DL
    CMP DL,79
    JNE BottomWall


    ; ---------- Draw Side Walls (Left & Right) ----------
    MOV DH,1            ; Start below top wall

SideWalls:
    ; ----- Left wall -----
    MOV DL,0            ; Leftmost column
    MOV BH,0
    MOV AH,02h
    INT 10h

    PUSH CX
    MOV AL,'#'
    MOV BL,07h
    MOV BH,0
    MOV CX,1
    MOV AH,09h
    INT 10h
    POP CX

    ; ----- Right wall -----
    MOV DL,79           ; Rightmost column
    MOV BH,0
    MOV AH,02h
    INT 10h

    PUSH CX
    MOV AL,'#'
    MOV BL,07h
    MOV BH,0
    MOV CX,1
    MOV AH,09h
    INT 10h
    POP CX

    INC DH              ; Move down one row
    CMP DH,24           ; Stop before bottom wall
    JNE SideWalls

    RET
DrawWalls ENDP


; =====================================================
; CREATE FOOD
; Generates random food coordinates inside the walls
; Uses system clock ticks and modulo arithmetic
; to avoid infinite loops or invalid positions.
; =====================================================
CreateFood PROC
    PUSH AX             ; Save registers
    PUSH BX
    PUSH CX
    PUSH DX

    ; ---------- Get system time ----------
    MOV AH,00h
    INT 1Ah             ; CX:DX = clock ticks since midnight


    ; ---------- Generate Food X position ----------
    ; X = (DX % 75) + 2
    ; Range ensured: 2 to 76 (inside vertical walls)
    MOV AX, DX          ; Use lower word of time
    XOR DX, DX          ; Clear DX for DIV
    MOV BX, 75          ; Screen width minus walls
    DIV BX              ; DX = remainder
    ADD DL, 2           ; Offset from left wall
    MOV FoodX, DL       ; Store X coordinate


    ; ---------- Generate Food Y position ----------
    ; Y = (CX % 21) + 2
    ; Range ensured: 2 to 22 (inside horizontal walls)
    MOV AX, CX          ; Use higher word of time
    ADD AX, DX          ; Mix entropy slightly
    XOR DX, DX
    MOV BX, 21          ; Screen height minus walls
    DIV BX              ; DX = remainder
    ADD DL, 2           ; Offset from top wall
    MOV FoodY, DL       ; Store Y coordinate


    POP DX              ; Restore registers
    POP CX
    POP BX
    POP AX
    RET
CreateFood ENDP

; =====================================================
; READ INPUT
; Reads keyboard input using BIOS interrupt INT 16h
; Supports arrow keys and W/A/S/D controls
; Updates direction variable (Dir)
; =====================================================
ReadInput PROC
    MOV AH,01h          ; Check if a key is available
    INT 16h
    JZ NoKey            ; If no key pressed, return

    MOV AH,00h          ; Read the key
    INT 16h             ; AH = scan code, AL = ASCII

    ; ---- Arrow keys (scan codes) ----
    CMP AH,48h          ; Up arrow
    JE Up
    CMP AH,50h          ; Down arrow
    JE Down
    CMP AH,4Bh          ; Left arrow
    JE Left
    CMP AH,4Dh          ; Right arrow
    JE Right

    ; ---- WASD keys (ASCII) ----
    CMP AL,'w'
    JE Up
    CMP AL,'s'
    JE Down
    CMP AL,'a'
    JE Left
    CMP AL,'d'
    JE Right

    JMP NoKey           ; Ignore any other key

Up:    MOV Dir,2        ; Direction = Up
       JMP NoKey
Down:  MOV Dir,3        ; Direction = Down
       JMP NoKey
Left:  MOV Dir,1        ; Direction = Left
       JMP NoKey
Right: MOV Dir,0        ; Direction = Right

NoKey:
    RET
ReadInput ENDP

; =====================================================
; MOVE SNAKE
; Moves the snake one step in the current direction
; Shifts body segments and updates the head
; Clears the tail unless food was eaten
; =====================================================
MoveSnake PROC

    ; ---------- Save tail position ----------
    ; Needed to erase the tail if snake does not grow
    MOV CL,SnakeLen
    DEC CL
    XOR CH,CH
    MOV SI,CX
    MOV AL,SnakeX[SI]
    MOV PrevTailX,AL
    MOV AL,SnakeY[SI]
    MOV PrevTailY,AL

    ; ---------- Shift body segments ----------
    ; Each segment copies the position of the previous one
    MOV CL,SnakeLen
    DEC CL
    XOR CH,CH
MoveBody:
    MOV SI,CX
    DEC SI
    MOV AL,SnakeX[SI]
    MOV SnakeX[SI+1],AL
    MOV AL,SnakeY[SI]
    MOV SnakeY[SI+1],AL
    LOOP MoveBody

    ; ---------- Move the head ----------
    MOV AL,SnakeX[0]
    MOV AH,SnakeY[0]

    CMP Dir,0
    JE GoRight
    CMP Dir,1
    JE GoLeft
    CMP Dir,2
    JE GoUp
    CMP Dir,3
    JE GoDown

GoRight: INC AL         ; Move right
    JMP DoneMove
GoLeft:  DEC AL         ; Move left
    JMP DoneMove
GoUp:    DEC AH         ; Move up
    JMP DoneMove
GoDown:  INC AH         ; Move down

DoneMove:
    MOV SnakeX[0],AL    ; Update head X
    MOV SnakeY[0],AH    ; Update head Y

    ; ---------- Check if food was eaten ----------
    CMP AteFood,1
    JE KeepTail         ; Do not erase tail if snake grew

    ; ---------- Erase tail from screen ----------
    MOV DL,PrevTailX
    MOV DH,PrevTailY
    MOV BH,0
    MOV AH,02h          ; Set cursor position
    INT 10h

    PUSH CX
    MOV AL,' '          ; Overwrite with space
    MOV BL,07h
    MOV BH,0
    MOV CX,1
    MOV AH,09h
    INT 10h
    POP CX
    RET

KeepTail:
    MOV AteFood,0       ; Reset growth flag
    RET
MoveSnake ENDP

; =====================================================
; CHECK COLLISION
; Detects collision with walls or food
; Ends game on wall collision
; Increases score and length on food collision
; =====================================================
CheckCollision PROC

    ; ---------- Wall collision (X-axis) ----------
    MOV AL,SnakeX[0]
    CMP AL,1
    JBE Hit             ; Hit left wall
    CMP AL,78
    JAE Hit             ; Hit right wall

    ; ---------- Wall collision (Y-axis) ----------
    MOV AL,SnakeY[0]
    CMP AL,1
    JBE Hit             ; Hit top wall
    CMP AL,23
    JAE Hit             ; Hit bottom wall

    ; ---------- Food collision ----------
    MOV AL,SnakeX[0]
    CMP AL,FoodX
    JNE NoFood
    MOV AL,SnakeY[0]
    CMP AL,FoodY
    JNE NoFood

    ; Prevent overflow of snake arrays
    CMP SnakeLen,MAXLEN
    JAE NoFood

    INC SnakeLen        ; Increase snake length
    INC Score           ; Increase score
    MOV AteFood,1       ; Mark growth
    CALL CreateFood     ; Spawn new food

NoFood:
    RET

Hit:
    JMP GameEnd         ; End the game
CheckCollision ENDP

; =====================================================
; DRAW SNAKE FRAME
; Draws the food and the entire snake on screen
; =====================================================
DrawSnakeFrame PROC

    ; ---------- Draw food ----------
    MOV DL,FoodX
    MOV DH,FoodY
    MOV BH,0
    MOV AH,02h
    INT 10h

    PUSH CX
    MOV AL,'@'          ; Food character
    MOV BL,0Ch          ; Light red color
    MOV BH,0
    MOV CX,1
    MOV AH,09h
    INT 10h
    POP CX

    ; ---------- Draw snake ----------
    MOV CL,SnakeLen
    XOR CH,CH
DrawSnakeLoop:
    MOV SI,CX
    DEC SI
    MOV DL,SnakeX[SI]
    MOV DH,SnakeY[SI]
    MOV BH,0
    MOV AH,02h
    INT 10h

    PUSH CX
    MOV AL,'O'          ; Snake body character
    MOV BL,02h          ; Green color
    MOV BH,0
    MOV CX,1
    MOV AH,09h
    INT 10h
    POP CX
    LOOP DrawSnakeLoop

    RET
DrawSnakeFrame ENDP

; =====================================================
; DELAY
; Creates a visible delay to control snake speed
; =====================================================
Delay PROC
    MOV BX,5
OuterDelay:
    MOV CX,0FFFFh
InnerDelay:
    LOOP InnerDelay
    DEC BX
    JNZ OuterDelay
    RET
Delay ENDP

; =====================================================
; START SCREEN
; Displays game title and instructions
; =====================================================
StartScreen PROC
    MOV AX, 0003h       ; Clear screen
    INT 10h

    MOV DH, 10          ; Row for title
    MOV DL, 27
    MOV SI, OFFSET StartMsg1
    CALL PrintYellow

    MOV DH, 11          ; Row for controls
    MOV DL, 27
    MOV SI, OFFSET StartMsg2
    CALL PrintYellow

    MOV DH, 12          ; Row for start prompt
    MOV DL, 27
    MOV SI, OFFSET StartMsg3
    CALL PrintYellow

    MOV AH, 00h         ; Wait for key
    INT 16h
    RET
StartScreen ENDP


; =====================================================
; PRINT YELLOW
; Prints a '$'-terminated string in yellow color
; =====================================================
PrintYellow PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

NextChar:
    MOV AL, [SI]
    CMP AL, '$'
    JE Done

    MOV AH, 02h         ; Set cursor
    MOV BH, 00h
    INT 10h

    MOV AH, 09h         ; Print character
    MOV BH, 00h
    MOV BL, 0Eh         ; Yellow color
    MOV CX, 1
    INT 10h

    INC SI
    INC DL
    JMP NextChar

Done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintYellow ENDP


; =====================================================
; GAME OVER SCREEN
; Displays final screen, score, and waits for key
; =====================================================
ShowGameOver PROC
    ; Switch to text mode and clear screen
    MOV AX, 0003h
    INT 10h
    
    ; ----- "GAME OVER!" -----
    MOV DH, 10              ; Row
    MOV DL, 35              ; Column
    MOV SI, OFFSET GameOverMsg
    CALL PrintRed

    ; ----- "Score:" -----
    MOV DH, 11
    MOV DL, 35
    MOV SI, OFFSET ScoreMsg
    CALL PrintRed

    ; Print numeric score value
    MOV AX, Score
    CALL PrintNum 

    ; ----- Exit message -----
    MOV DH, 13
    MOV DL, 28
    MOV SI, OFFSET ExitMsg
    CALL PrintRed

    ; Wait for key before exiting
    MOV AH, 00h
    INT 16h
    RET
ShowGameOver ENDP

; =====================================================
; PRINT RED TEXT
; Prints $-terminated string at current cursor in red
; =====================================================
PrintRed PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

NextCharRed:
    MOV AL, [SI]        ; Get next character
    CMP AL, '$'         ; End of string?
    JE DoneRed
    
    ; Set cursor position
    MOV AH, 02h
    MOV BH, 00h
    INT 10h

    ; Print character in red
    MOV AH, 09h
    MOV BH, 00h
    MOV BL, 0Ch         ; Bright red color
    MOV CX, 1
    INT 10h

    INC SI              ; Next character
    INC DL              ; Move cursor right
    JMP NextCharRed

DoneRed:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintRed ENDP

; =====================================================
; PRINT NUMBER
; Prints value in AX as decimal
; =====================================================
PrintNum PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX,10           ; Base 10 divisor
    XOR CX,CX           ; Digit counter

PN1:
    XOR DX,DX
    DIV BX              ; AX / 10 → quotient in AX, remainder in DX
    PUSH DX             ; Save digit
    INC CX
    CMP AX,0
    JNE PN1

PN2:
    POP DX
    ADD DL,'0'          ; Convert digit to ASCII
    MOV BH,0
    MOV AH,02h
    INT 21h             ; DOS output character
    LOOP PN2

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintNum ENDP

END MAIN