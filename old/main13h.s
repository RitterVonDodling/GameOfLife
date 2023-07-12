;0x00500 -- 0x07BFF freier Speicher
;   => SEED und andere Zwischenspeicher
;   0x0500 speicherort SEED
;   0x0502 speicherort RNG
;   0x0504 Speicherort PosMask
;   0x05FF abwärts Stack
;0x07E00 -- 0x9FFFF verfügbarer Speicher
;   => Golzwischenspeicher
;   => 0x07E00 -- 0x08DA0 für numpix Bit Einträge
;   => 0x07E00 -- 0x17800 für numpix Byte Einträge
;0x07E0:0002 => 0x07E02
;0x7E00:0002 => 0x7E002
;noch grafikfehler durch stack
;zurzeit noch je speicherslot 1Bit ändern auf 8


%define zeilen 200
%define spalten 320
%define numpix (zeilen*spalten)
%define letztezeile (zeilen - 1)
%define letztespalte (spalten -1)
%define spaltep1 (spalten + 1)
%define spaltem2 (spalten -2)

BITS 16
org 0x0100

mov ax, 0x0500
mov ss, ax
mov sp, 0x00FF

call gettime
initraster:
    mov cx, numpix
    forinitraster:
        push cx
        call randint
        pop cx
        dec cx
        mov bx, cx
        push ds
        mov ax, 0x0000
        mov ds, ax
        mov dx, [0x0502]
        mov ax, 0x07E0
        mov ds, ax
        dec cx
        mov [ds:bx], dl
        pop ds
        cmp cx, 0
        jnz forinitraster

setvidgrp:
    mov ax, 0x0013     ;Auflösung 320x200
    int 0x10

;16 Farben
;0x00 Schwarz
;0x01 Blau
;0x04 Rot
;0x0E Gelb
;0x0F Weiß

printv:
    mov cx, numpix
    push ds         ;DS in Stack
        forprintv:
        dec cx
        mov bx, cx      ;position aus for schleife an bx (offset)
        mov ax, 0x07E0         ;
        mov ds, ax      
        mov dx, 0x0000
        mov dl, [ds:bx]
        and dl, 00000001b
        mov ax, 0xA000  ;Speicherbereich für VGA
        mov ds, ax      ;Speicherbereich VGA in DS 
        mov al, 0xF    ;Farbe weiß 
        mul dl         ; ax x dl zahl aufrufen ->  wenn dl 1, dann weiß
        mov [ds:bx], al ;wert dl in a000:speicherpos speichern
        cmp cx, 0
        jne forprintv
    pop ds          ;DS aus Stack

;call kbhit

; Reg   |   H   |   L
;-----------------------
; AX    | PosMsk| SUM
; BX    |     OFFSet
; CX    | Position/Inc
; DX    |saveRAM| LoadRAM

calcraster:
    mov cx, numpix
    push ds
    forcalcraser:
        dec cx
        push cx
        call posmask
        mov ax, 0x0000
        mov ds, ax
        mov bx, 0x0504
        mov ah, [ds:bx]     ;Lade PosMask
        mov bx, 0x07E0
        mov ds, bx
        mov bx, cx
        mov dl, [ds:bx]     ;Lade Cell
        mov al, 0x00        ; SUM to 0
        mov cx, spaltep1      ;obenlinks -321
        sub bx, cx
        call calcsum
        inc bx              ;obenmitte -320
        call calcsum
        inc bx              ;obenmitte -letztespalte
        call calcsum
        add bx, spaltem2      ;links -1
        call calcsum
        add bx, 0x0002      ;rechts +1
        call calcsum
        add bx, spaltem2      ;untenlinks +letztespalte
        call calcsum
        inc bx              ;untenmitte +320
        call calcsum
        inc bx              ;untenrechts +321
        call calcsum
        cmp dl, 0           ;Tile Dead
        je dead                 
        cmp al, 2           ;Cell Alive , stay alive
        je born
        cmp al, 3           ;Cell Alive, stay alive
        je born
        and dl, 0x01        ;LSB bleibt 1, Rest 0             
        jmp fertig          
        dead:               
        cmp al, 3           ;cell dead, born
        je born
        and dl, 0x00        ;MSB und LSB 0
        jmp fertig          
        born:               ;Born => MSB + 1
        add dl, 128
        fertig:                 
        pop cx
        mov bx, cx
        mov [ds:bx], dl 
        cmp cx, 0
        jne forcalcraser
    pop ds
jmp cpraster

calcsum:
    mov dh, [ds:bx]     ;Lade Wert Nachbar aus OFFSET 
    and dh, 0x01        ;Nur letztes BIT
    and dh, ah          ;Nur letztes BIT PosMask
    shr ah, 1           ;SHR PosMask für nächsten Nachbar
    add al, dh          ;add Nachbar to SUM
    ret

cpraster:
    mov cx, numpix
    push ds
    forcpraser:
        dec cx
        mov bx, cx
        mov ax, 0x07E0
        mov ds, ax
        mov ax, 0x0000
        mov al, [ds:bx]     ;lädt CELL aus RAM
        shr al, 7           ;MSB wird LSB => Alter Wert durch neuen überschrieben
        mov [ds:bx], al     ;speichert LSB in RAM
        cmp cx, 0
        jnz forcpraser
    pop ds
jmp printv

kbhit:
	mov ah, 0x00	; read keyboard, blocking
	int 0x16
    ret

gettime:
    push ds
    push cx
    mov ax, 0x0000
    mov ds, ax                  ;erfasst aktuelle bios zeit
    mov ax, 0x0000
    int 0x1A
    mov [0x0500], dx        ;MemMap erstellen und wert anpassen! DX = Sekunden
    pop cx
    pop ds                         
    ret

posmask:                        ;Speicherort 0x0504, berechnet ob bit aus Speicheroffset gültig
;Position des Bits um das aktuelle Tile
;   1 # 2 # 3
; #############
;   4 #CX # 5
; #############
;   6 # 7 # 8
; 0x0504: 87654321b
;Div => AL Dividend, DX Modulus

push cx
push dx
mov ax, 0x0000
mov ax, cx
mov dx, 0x0000
mov cx, 0x00FF
mov bx, 320
div bx
cmp ax, 0
je div0
cmp ax, letztezeile
je divletztezeile
modres:
cmp dx, 0
je mod0
cmp dx, letztespalte
je modletztespalte
saveposmask:
push ds
mov ax, 0x0000
mov ds, ax
mov bx, 0x0504
mov [ds:bx], cl ;Speichere PosMask in 0x0504
pop ds
pop dx
pop cx
ret
;Position 87654321b
div0:                   ;Zeile 0
and cl, 11111000b
jmp modres
divletztezeile:                 ;Zeile letztezeile
and cl, 00011111b
jmp modres
mod0:                   ;Spalte 0
and cl, 11010110b
jmp saveposmask
modletztespalte:                 ;Spalte letztespalte
and cl, 01101011b
jmp saveposmask


randint:
    ;((SEED x RMUL)+RADD)/RDIV
    push ds
    mov ax, 0x0000          ;offset auf 0
    mov ds, ax
    mov ax, [0x0500]        ;Lädt SEED aus RAM
    mov dx, 60259           ;RMUL
    mul dx
    mov dx, 53419           ;RADD
    add ax, dx
    mov cx, 43237           ;RDIV
    mov dx, 0x0000          
    div cx                  ;dx enthält modulus, ax dividend
    mov ax, dx
    and ax, 000100000000000b
    shr ax, 11
    mov [0x0502], al        ;Speichtert RNG Ergebnis im RAM
    mov ax, [0x0500]        ;Lädt SEED aus RAM
    inc ax                  ;SEED++
    mov [0x0500], ax        ;SEED zurückspeichern
    pop ds
    ret