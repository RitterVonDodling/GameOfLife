;0x00500 -- 0x07BFF freier Speicher
;   => SEED und andere Zwischenspeicher
;   0x0500 speicherort SEED
;   0x0502 speicherort RNG
;   0x0504 Speicherort PosMask
;   0x0506 - 0x0508 Zwischenspeicher Calcraster
;   0x050C - 0x050D Zwischenspeicher Iteration Calcraster
;   0x0600 - 0x0900 Programm
;   0x07B00 - 0x07BFF abwärts Stack
;0x07C00 - 0x07DFF Verweis Bootloader
;0x07E00 -- 0x9FFFF verfügbarer Speicher
;   => Golzwischenspeicher
;   => 0x08000 -- 0x12000 für 640*480 8bit Einträge (0x11600)
;   => 0x12000 -- 0x1B600 für calcraster
;0x07E0:0002 => 0x07E02
;0x7E00:0002 => 0x7E002

; seltsames Zeug 0x104FE

%define OFFSET 0x0800

BITS 16
;org 0x0600

jmp start

randint:
    ;((SEED x RMUL)+RADD)/RDIV
    push es
    mov ax, 0x0000          ;offset auf 0
    mov es, ax
    mov ax, 0x0500
    mov di, ax
    mov ah, [es:di]        ;Lädt SEED aus RAM
    mov al, [es:di]        ;Lädt SEED aus RAM
    mov dx, 7           ;RMUL
    mul dx
    mov dx, 831           ;RADD
    add ax, dx
    mov cx, 53           ;RDIV
    mov dx, 0x0000          
    div cx                  ;dx enthält modulus, ax dividend
    mov ax, dx
    mov bx, 0x0502
    mov di, bx
    mov [es:di], ax
    mov bx, 0x0500          ;Speichtert RNG Ergebnis im RAM
    mov di, bx
    mov ax, [es:di]         ;Lädt SEED aus RAM
    inc ax                  ;SEED++
    mov bx, 0x0500
    mov di, bx
    mov [es:di], ax        ;SEED zurückspeichern
    pop es
    ret

start:
setupstack:
    mov ax, 0x07B0
    mov ss, ax
    mov sp, 0x00FF

setvidgrp:
    mov ax, 0x0012     ;Auflösung 640x480x16
    int 0x10

gettime:
    push es
    mov ax, 0x0000
    mov es, ax                  ;erfasst aktuelle bios zeit
    mov ax, 0x0000
    int 0x1A
    mov bx, 0x0500
    mov di, bx
    mov [es:di], dl        ;MemMap erstellen und wert anpassen! DX = Sekunden
    pop es

;call kbhit

initraster:
    mov cx, 38400
    forinitraster:
        push cx
        call randint
        pop cx
        dec cx
        mov bx, cx
        mov di, cx
        push ds
        mov ax, 0x0000
        mov ds, ax
        mov dl, [0x0502] ;LOAD RANDINT
        mov ax, OFFSET
        mov es, ax
        mov [es:di], dl
        pop ds
        cmp cx, 0
        jnz forinitraster

;16 Farben
;0x00 Schwarz
;0x01 Blau
;0x04 Rot
;0x0E Gelb
;0x0F Weiß

printvv:
    mov cx, 0x9600 ;38400 in Dez
    forprintvv:
        dec cx
        mov ax, 0x0800
        mov es, ax
        mov dx, 0x0000
        mov di, cx
        mov bl, [es:di]     ;Lädt CELL
        mov ax, 0xA000      ;OFFSET GRFMEM
        mov es, ax          ;OFFSET -> ExtraSegment
        mov dx, 0x03C4      ;i/o port für VGA
        mov ax, 0x0F02      ;ah Farbe, al Kommando Bitlane (02 = write)
        out dx, ax          ;gebe ax an port dx aus       
        mov al, bl          ;bitmask CELL 
        stosb               ;sende inhalt al an es:di
        cmp cx, 0
        jne forprintvv

call kbhit

calcraster:
    mov cx, 0x9600
    forcalcraser:
        dec cx
        mov bx, 0x0000
        mov es, bx
        mov bx, 0x050C      ;SPEICHERORT iteration
        mov di, bx
        mov [es:di], cx     ;SAVE iteration
        ;START XOR
        mov bx, OFFSET      ;OFFSET CELL
        mov es, bx
        mov di, cx
        mov ax, 0x0000
        mov bx, 0x0000
        mov dx, 0x0000
        ;cmp cx, 81
        ;jl xorpunktobenmitte
        mov ax, [es:di-81]  ;cx -81 = obenlinks
        ror ax, 1          ;N1 in ah
        xorpunktobenmitte:
        ;cmp cx, 80
        ;jl xorpunktlinks
        mov bl, [es:di-80]  ;N2 in bl obenmitte
        xor ah, bl          ;x1 in ah
        mov bx, [es:di-80]  ;obenrechts
        rol bx, 1           ;N3 in bl
        xorpunktlinks:
        ;cmp cx, 0
        ;je xorpunktmitte
        mov dx, [es:di-1]   ;links
        ror dx, 1           ;N4 in dh
        xorpunktmitte:
        xor bl, dh          ;x2 in bl
        mov al, ah          ;x1 in al
        and ah, bl          ;cp xa1 in ah
        xor al, bl          ;xx1 in al
        mov bx, 0x0000
        mov dx, 0x0000
        ;cmp cx, 38399
        ;je xorpunktladenende  ;
        xorpunktrechts:
        mov bx, [es:di]   ;rechts
        rol bx, 1           ;N5 in bl
        xorpunktuntenlinks:
        ;cmp  cx, 38321kbhit
        xor bl, dh          ;x3 in bl
        ;cmp cx, 38320
        ;jge xorpunktletztezeile
        mov bh, [es:di+80]  ;N7 in bh untenmitte
        mov dx, [es:di+80]  ;untenrechts
        rol dx, 1           ;N8 in dl
        xorpunktletztezeile:
        xor bh, dl          ;x4 in bh
        mov dh, bl          ;
        and bl, bh          ;xa2 in bh
        xor dh, bh          ;xx2 in dh
        xorpunktladenende:
        xor ah, bl          ;xax1 in ah
        mov bh, al          
        and al, dh          ;xxa1 in al
        xor bh, dh          ;xxx1 in bl
        push cx             ;PUSH 3 -> 0xEE   
        mov cx, 0x0000
        mov es, cx
        mov cx, 0x0506      ;zwischenspeicher 1
        mov di, cx
        mov [es:di], bh     ;xxx1 -> 0x0506
        mov [es:di+1], al   ;xxa1 -> 0x0507
        mov [es:di+2], ah   ;xax1 -> 0x0508
        ;ENDE XOR BLOCK
        ;START AND BLOCK
        mov cx, OFFSET
        mov es, cx
        pop cx              ;POP 3 <- SP 0xEE   
        mov di, cx
        ;cmp cx, 81
        ;jl andpunktobenmitte
        mov ax, [es:di-81]  ;obenlinks
        ror ax, 1           ;N1 in ah
        mov bl, [es:di-80]  ;N2 in bl obenmitte
        and ah, bl          ;a1 in al
        andpunktobenmitte:
        ;cmp cx, 80
        ;jl andpunktlinks
        mov bx, [es:di-80]  ;obenrechts
        rol bx, 1           ;N3 in bl
        andpunktlinks:
        ;cmp cx, 0
        ;je andpunktrechts
        mov dx, [es:di-1]   ;links
        ror dx, 1           ;N4 in dh
        and bl, dh          ;a2 in bl
        mov al, ah          ;cp a1 -> al
        and ah, bl          ;aa1 in ah
        xor al, bl          ;ax1 in al
        andpunktrechts:
        mov bx, [es:di]     ;rechts
        rol bx, 1           ;N5 in bl
        mov dx, [es:di+79]  ;untenlinks
        ror dx, 1           ;N6 in dh
        and bl, dh          ;a3 in bl
        mov bh, [es:di+80]  ;N7 in bh untenmitte
        mov dx, [es:di+80]  ;untenrechts
        rol dx, 1           ;N8 in dl
        mov dh, bl          ;cp a3 -> dh
        and bh, dh          ;a4 in bl
        and bl, bh          ;aa2 in bh
        xor dh, bh          ;ax2 in dh
        xor ah, bl          ;aax1 in ah
        mov bl, al          
        and al, dh          ;axa1 in al
        xor bl, dh          ;axx1 in bl
        ;ENDE AND BLOCK
        ;START AND MASK
        push cx             ;PUSH 4 -> SP 0xEE 
        mov cx, 0x0000
        mov es, cx
        mov cx, 0x0508
        mov bh, [es:di]     ;xax1 in bh
        mov dh, bh          
        xor bh, bl          ;ANDx1 in bh
        mov dl, [es:di-1]     ;xxa1 in dl
        xor bh, dl          ;ANDxx1 in bh
        mov dl, [es:di-2]     ;xxx1 in dl
        mov cx, OFFSET
        mov es, cx
        pop cx              ;POP 4 <- SP 0xEE
        not dl              ;invert xxx1
        and bh, dl          ;ANDxxa1 in bh
        not ah              ;ANDn2 in ah
        and bh, ah          ;ANDxxaa1 in bh
        not al              ;ANDn3 in al
        and bh, al          ;ANDxxaaa1 in bh
        ;ENDE AND MASK --> BH
        ;START OR MASK
        not dl
        and dh, dl          ;ORa1 in dh
        and bl, dl          ;ORaa1 in bl
        xor bl, dh          ;ORaax1 in bl
        and bl, ah          ;ORaaxa1 in bl
        ;ENDE OR MASK --> BL
        ;alte cell -> al
        ;AND MASK
        ;OR MASK
        ;neue an anderer addresse speichern
        mov dx, 0x0000
        mov es, dx
        mov dx, 0x050C      
        mov di, dx
        mov cx, [es:di]     ;LOAD Iteration CX = +-0
        mov di, cx
        mov dx, 0x7e0
        mov es, dx
        mov al, [es:di]     ;ALTE CELL
        ;sub al, 7           ;NEUE CELL TEST
        and al, bh
        or al, bl           ;NEUE CELL
        mov dx, 0x1200
        mov es, dx
        mov [es:di], al     ;
        cmp cx, 0
        jne forcalcraser

;call kbhit
;jmp gettime

cpraster:
    mov cx, 0x9600
    forcpraser:
        dec cx
        mov dx, 0x1200
        mov es, dx
        mov di, cx
        mov al, [es:di]
        mov dx, OFFSET
        mov es, dx
        mov [es:di], al
        cmp cx, 0
        jne forcpraser

;call kbhit
jmp printvv

kbhit:
	mov ah, 0x00	; read keyboard, blocking
	int 0x16
    ret