
# Snake Game in Assembly Language

A classic Snake Game implemented in **Assembly Language** 

## 🕹️ Game Description

This is a console-based Snake Game where the player controls the snake to eat food and grow longer. The game ends if the snake collides with the wall or itself.  

## 🎮 Features

- Classic snake gameplay  
- Console-based graphics  
- Score tracking  
- Easy to run on DOSBox and VSCode

## Project Information:

- Classic Snake game implemented in 8086 Assembly.
- Platform: DOS / DOSBox , VS Code
- Assembler: TASM or MASM
- Controls: Arrow Keys or W / A / S / D
- Game Objective: Eat food (@) to grow and increase score.
- Game Over: Snake hits wall.

## REQUIRED ENVIRONMENT

1. Operating System: Windows / DOSBox
2. Assembler: TASM (Turbo Assembler) or MASM (Microsoft Assembler)
3. Emulator: DOSBox (for running 8086 programs on modern systems)
4. Screen: 80x25 text mode

## FILES REQUIRED

- snake.asm       → Main assembly code
- (Optional) snake.obj / snake.exe if precompiled

# STEP-BY-STEP GUIDE TO RUN THE GAME

Step 1: Open DOSBox and mount your project folder
-------------------------------------------------
C:\> mount c c:\path\to\your\project
C:\> c:

Step 2: Assemble the code
--------------------------
- Using TASM:
    tasm snake.asm
- Using MASM:
    masm snake.asm;

Step 3: Link the object file
----------------------------
- Using LINK:
    link snake.obj
- This generates the executable file: snake.exe

Step 4: Run the game
---------------------
C:\> snake.exe
- Start screen appears → Press any key to begin
- Use **Arrow Keys** or **W / A / S / D** to control the snake
- Eat food (@) to grow and increase your score
- Game ends on collision with wall

## NOTES & TIPS

- Make sure DOSBox is set to **80x25 text mode**
- The snake tail grows only when food is eaten
- Game speed is controlled by the built-in delay routine
- Press any key to exit after “Game Over” screen


# ENJOY THE GAME!
------------------------------------------------------------