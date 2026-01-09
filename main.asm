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