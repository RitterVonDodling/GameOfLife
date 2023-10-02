org 0x7C00
bits 16

start:
main:
;clear flags
cli
cld



mov ax, ds
mov es, ax

;Set video mode 1600x1200x8
mov ax, 4f02h
mov bx, 0x11c
int 10h

;Get video mode info
mov ax, 4f01h
mov cx, 105h
mov di, 256 
int 10h

;Assume first window is valid 
mov ax, 0xA000
mov es, ax

;Example of how to change the window 
mov ax, 4f05h
xor bx, bx
mov bh, 0
mov dx, 28       ;This is granularity units beeinflusst startposition zeichne pixel max 29
int 10h

draw:
;di = 0
xor di, di 
; al =Farbe
mov al, 0xC6
mov cx, 0xFFFF

;al -> es:di
rep stosb
jmp draw


hlt


; Rest mit \0 füllen
times 510-($-$$) db 0
dw 0xAA55	