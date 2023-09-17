org 0x7C00
bits 16
start:
jmp main

main:
cli
cld


mov ax, 0x0060
mov bx, 0x0000
mov di, bx
mov si, bx
mov ds,ax
mov es, ax

mov ah, 0x02
mov al, 0x02
mov cl, 0x02
mov ch, 0x00
mov dl, 0x00    ;drive number 
mov dh, 0x00
int 0x13

;test,ob Grafik funktioniert
mov ax, 0x0000
int 0x10

mov dx,0x0000
mov es,dx
mov dx, 0x0601
mov di,dx

mov ah, 0x0A
mov al, [es:di]
mov bh, 0x00
mov cx, 0x0001
int 0x10

mov ax, 0x0060
mov bx, 0x0600

push bx
ret

; Rest mit \0 füllen
times 510-($-$$) db 0
dw 0xAA55	