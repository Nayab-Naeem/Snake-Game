; UI/ Display Screen Logic Functions

;Function to clear the screen 
ClearScreen PROC
    MOV AX,0600h      ; AH = 06h (scroll up), AL = 00 (clear entire window)
    MOV BH,07h        ; light gray on black
    MOV CX,0000h      ; Top-left corner (row 0, col 0)
    MOV DX,184Fh      ; Bottom-right corner (row 24, col 79)
    INT 10h
    RET
ClearScreen ENDP


;Function for drawing Walls
DrawWalls PROC
        ; ---------------- TOP WALL ---------------- 
        ;#########################################

    MOV CX,0
TopWall:
    MOV AH,02h
    MOV BH,0
    MOV DH,0          ; Row 0
    MOV DL,CL         ; Column
    INT 10h

    MOV AH,09h
    MOV AL,'#'
    MOV BL,0Ah        ; Green color display logic
    MOV CX,1
    INT 10h

    INC CL
    CMP CL,79
    JLE TopWall

        ; ---------------- BOTTOM WALL ----------------
        ;#########################################
    MOV CX,0
BottomWall:
    MOV AH,02h
    MOV BH,0
    MOV DH,24         ; last row of screen
    MOV DL,CL
    INT 10h

    MOV AH,09h
    MOV AL,'#'
    MOV BL,0Ah
    MOV CX,1
    INT 10h

    INC CL
    CMP CL,79
    JLE BottomWall

        ; ---------------- LEFT WALL ----------------
        ;#########################################
    MOV CX,1
LeftWall:
    MOV AH,02h
    MOV BH,0
    MOV DH,CL
    MOV DL,0          ; Column 0
    INT 10h

    MOV AH,09h
    MOV AL,'#'
    MOV BL,0Ah
    MOV CX,1
    INT 10h

    INC CL
    CMP CL,23
    JLE LeftWall

        ; ---------------- RIGHT WALL ----------------
        ;#########################################
    MOV CX,1
RightWall:
    MOV AH,02h
    MOV BH,0
    MOV DH,CL
    MOV DL,79         ; Column 79
    INT 10h

    MOV AH,09h
    MOV AL,'#'
    MOV BL,0Ah
    MOV CX,1
    INT 10h

    INC CL
    CMP CL,23
    JLE RightWall

    RET
DrawWalls ENDP

;--------------------------------------------
;Function for making snake 

DrawSnake PROC
    MOV CL,0          ; segment counter
    MOV SI,0          ; index for SnakeX/Y arrays

DrawSnakeLoop:
    CMP CL, SnakeLen
    JGE DoneSnake

    ; Move cursor to segment position
    MOV AH,02h
    MOV BH,0
    MOV DH, SnakeY[SI] ; Row
    MOV DL, SnakeX[SI] ; Column
    INT 10h

    ; Determine character to draw
    CMP CL,0           ; Is this the head?
    JE DrawHead
    MOV AL,219         ; Body = full block █
    MOV BL,0Bh         ; Body color = cyan
    JMP PrintChar

DrawHead:
    ; Set head character based on direction of the movement
    MOV AL,'^'         ; default Up
    MOV BL,0Ch         ; Head color = red
    MOV AL, SnakeDir
    CMP AL,0           ; Up
    JE HeadUp
    CMP AL,1           ; Down
    JE HeadDown
    CMP AL,2           ; Left
    JE HeadLeft
    CMP AL,3           ; Right
    JE HeadRight
    JMP HeadUp        ; fallback

HeadUp:
    MOV AL,'^'
    JMP PrintChar
HeadDown:
    MOV AL,'v'
    JMP PrintChar
HeadLeft:
    MOV AL,'<'
    JMP PrintChar
HeadRight:
    MOV AL,'>'
    JMP PrintChar

    ;Display the character
PrintChar:
    MOV AH,09h
    MOV CX,1
    INT 10h

    ; Next segment
    INC SI
    INC CL
    JMP DrawSnakeLoop

DoneSnake:
    RET
DrawSnake ENDP