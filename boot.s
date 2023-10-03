org 0x7C00
bits 16

jmp main

ErrMsg: db "Fehler!, Konnte File nicht laden"
EndMsg:

main:
;clear flags
cld

LoadErrMsg:
mov ax, 0x0000
int 0x10

PrintStr:  
    mov bx, 0x000F
    mov cx, 1       
    xor dx, dx      
    mov ds, dx      
    cld   

GetPointer:  
    mov si, ErrMsg     
 
PrintChar:   
    mov ah, 2       
    int 0x10
    lodsb           
    mov ah, 9       
    int 0x10
    inc dl         
    cmp dl, 80      
    jne EndOfString
    xor dl, dl
    inc dh
    cmp dh, 25      
    jne EndOfString
    xor dh, dh
 
EndOfString:   
    cmp si, EndMsg
    jne PrintChar


;ab hier tatsächliches Laden der Datei
;set es & ds to 0x00600
mov ax, 0x0060
mov bx, 0x0000
mov di, bx
mov si, bx
mov es, ax

;read from floppy
call ReadFloppy
call ReadFloppy
call ReadFloppy

mov ax, 0x0060
mov bx, 0x0600

JumpToProgram:
push bx
ret

ReadFloppy:
mov ah, 0x02
mov al, 0x02            ;Anzahl zu lesender Sektoren
mov cl, 0x02            ;Sektor Nummer
mov ch, 0x00            
mov dl, 0x00            ;drive number 
mov dh, 0x00
int 0x13
mov bx, 0x0000
ret

; Rest mit \0 füllen
times 510-($-$$) db 0
dw 0xAA55	
