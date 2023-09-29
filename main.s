;0x00500 -- 0x07BFF freier Speicher
;   => SEED und andere Zwischenspeicher
;   
;   0x0502 speicherort RNG
;   0x0504 Speicherort PosMask
;   0x0506 - 0x0508 Zwischenspeicher Calcraster
;   0x050C - 0x050D Zwischenspeicher Iteration Calcraster
;   0x050E SEED
;   0x0510 S2
;   0x0512 S3
;   0x0600 - 0x0900 Programm
;0x07C00 - 0x07DFF Verweis Bootloader
;0x07E00 -- 0x9FFFF verfügbarer Speicher
;   => Golzwischenspeicher
;   => 0x08000 -- 0x12000 für 640*480 8bit Einträge (0x11600)
;   => 0x12000 -- 0x1B600 für calcraster
;   => 0x90000 -- 0x9FFFF für stack
;0x07E0:0002 => 0x07E02
;0x7E00:0002 => 0x7E002

; seltsames Zeug 0x104FE

%define OFFSET 0x0800
%define RNGADDR 0x0502
%define SEEDADDR 0x050E
%define S2ADDR 0x0510
%define S3ADDR 0x0512
%define RMUL 39157
%define RADD 43973
%define RDIV 30539

BITS 16

jmp start

randint:
; Wichmann–Hill PRNG
;   [r, s1, s2, s3] = function(s1, s2, s3) is
;     // s1, s2, s3 should be random from 1 to 30,000. Use clock if available.
;     s1 := 171 × mod(s1, 177) − 2 × floor(s1 / 177)
;     s2 := 172 × mod(s2, 176) − 35 × floor(s2 / 176)
;     s3 := 170 × mod(s3, 178) − 63 × floor(s3 / 178)

;     r := mod(s1/30269 + s2/30307 + s3/30323, 1)

;       s1 = SEED
;       s2 = SEED*SEED[8-24]
;       s3 = S2*S2[8-24]

    push es
    mov ax, 0x0000                  ;offset auf 0
    mov es, ax
    ; AB HIER S1 S2 und S3 bestimmen
    xor ax, ax
    mov ax, [SEEDADDR]              ;Lädt SEED aus RAM
    push ax
    xor dx, dx
    mov bx, RMUL
    mul bx                          ;DX:AX = AX * BX
    mov al, ah
    mov ah, dl
    mov [S2ADDR], ax
    mul ax 
    mov al, ah
    mov ah, dl
    mov [S3ADDR], ax
    ;AB HIER S1 BERECHNEN
    xor ax, ax
    mov ax, [SEEDADDR]
    mov bx, 177
    xor dx, dx
    div bx
    mov cx, 2
    mul cx
    push ax ; ERGEBNIS FLOOR TEIL           PUSH 1
    mov ax, [SEEDADDR]
    xor dx, dx
    div bx
    mov ax, dx
    mov cx, 171
    mul cx
    pop bx                      ;POP 1
    sub ax, bx
    mov [SEEDADDR], ax
    ; AB HIER S2 Berechnen  s2 := 172 × mod(s2, 176) − 35 × floor(s2 / 176)
    xor ax, ax
    mov ax, [S2ADDR]
    mov bx, 176
    xor dx, dx
    div bx
    mov cx, 35
    mul cx
    push ax             ;PUSH 2
    mov ax, [S2ADDR]
    xor dx, dx
    div bx
    mov ax, dx
    mov cx, 172
    mul cx
    pop bx              ;POP 2
    sub ax, bx
    mov [S2ADDR], ax
    ; AB HIER S3 BERECHNEN   s3 := 170 × mod(s3, 178) − 63 × floor(s3 / 178)
    xor ax, ax
    mov ax, [S3ADDR]
    mov bx, 178
    xor dx, dx
    div bx
    mov cx, 63
    mul cx
    push ax                 ;PUSH 3
    mov ax, [S3ADDR]
    xor dx, dx
    div bx
    mov ax, dx
    mov cx, 170
    mul cx
    pop bx              ;POP 3
    sub ax, bx
    mov [S3ADDR], ax
    ;AB HIER R BESTIMMEN    r := mod(s1/30269 + s2/30307 + s3/30323, 1)
    mov bx, 30323
    xor dx, dx
    div bx
    mov [S3ADDR], dx
    mov ax, [S2ADDR]
    mov bx, 30307
    xor dx, dx
    div bx
    mov [S2ADDR], dx
    mov ax, [SEEDADDR]
    mov bx, 30269
    xor dx, dx
    div bx
    mov [SEEDADDR], dx
    mov ax, dx
    mov bx, [S2ADDR]
    add ax, bx
    mov bx, [S3ADDR]
    add ax, bx
    ; ERGEBNIS SPEICHERN


    pop bx
    inc bx
    mov [SEEDADDR], bx
    ; mov ax, 0x0808
    mov [RNGADDR], ax               ;Speicher RNG
    pop es
    ret


start:
setupstack:
    mov ax, 0x9000
    mov ss, ax
    mov sp, 0x00

setvidgrp:
    mov ax, 0x0012     ;Auflösung 640x480x16
    int 0x10

gettime:
    push es
    mov ax, 0x0000
    mov es, ax                  ;erfasst aktuelle bios zeit
    mov ax, 0x0000
    int 0x1A
    mov [SEEDADDR], dx        ;MemMap erstellen und wert anpassen! DX = Sekunden
    pop es

initraster:
    mov cx, 0x9600
    forinitraster:
        push cx
        call randint
        pop cx
        dec cx
        dec cx
        mov bx, cx
        mov di, cx
        push ds
        mov ax, 0x0000
        mov ds, ax
        mov dx, [RNGADDR]    ;LOAD RANDINT
        mov ax, OFFSET
        mov es, ax
        mov [es:di], dx
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
    mov cx, 0x9600      ;38400 in Dez       
    mov bx, 0xA000      ;SEGMENT GRFMEM
    mov es, bx          ;
    mov bx, OFFSET      ;
    push ds
    push si
    mov ds, bx
    xor bx, bx
    mov di, cx
    mov si, cx
    mov dx, 0x03C4      ;i/o port für VGA
    mov ax, 0x0F02      ;ah Farbe, al Kommando Bitlane (02 = write)
    out dx, ax          ;gebe ax an port dx aus
    forprintvv:
        sub di, 2
        sub si, 2
        mov bx, [ds:si]     ;bx <- [CELL]
        mov [es:di], bx     ;[GRF] <- bx
        cmp di, 0
        jne forprintvv
    pop si
    pop ds

    ; call kbhit

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
        mov al, ah          ;cp x1 in al
        and ah, bl          ;xa1 in ah
        xor al, bl          ;xx1 in al
        mov bx, 0x0000
        mov dx, 0x0000
        ;cmp cx, 38399
        ;je xorpunktladenende  ;
        xorpunktrechts:
        mov bx, [es:di]     ;rechts
        rol bx, 1           ;N5 in bl
        mov dx, [es:di+79]  ;untenlinks
        ror dx, 1           ;N6 in dh
        xorpunktuntenlinks:
        ;cmp  cx, 38321
        xor bl, dh          ;x3 in bl
        ;cmp cx, 38320
        ;jge xorpunktletztezeile
        mov bh, [es:di+80]  ;N7 in bh untenmitte
        mov dx, [es:di+80]  ;untenrechts
        rol dx, 1           ;N8 in dl
        xorpunktletztezeile:
        xor bh, dl          ;x4 in bh
        mov dh, bl          ;cp x3 in dh
        and bl, bh          ;xa2 in bl
        xor dh, bh          ;xx2 in dh
        xorpunktladenende:
        xor ah, bl          ;xax1 in ah
        mov bh, al          ;cp xx1 in bh
        and al, dh          ;xxa1 in al
        xor bh, dh          ;xxx1 in bh
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
        and ah, bl          ;a1 in ah
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
        and bh, dl          ;a4 in bh
        and bl, bh          ;aa2 in bl
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
        mov di, cx
        mov bh, [es:di]     ;xax1 in bh
        mov dh, bh          ;cp xax1 in dh
        xor bh, bl          ;ANDx1 in bh
        mov dl, [es:di-1]   ;xxa1 in dl
        xor bh, dl          ;ANDxx1 in bh
        mov dl, [es:di-2]   ;xxx1 in dl
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
        not dl              ;NOT ANDn1 -->	xxx1
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
        mov dx, OFFSET
        mov es, dx
        mov al, [es:di]     ;ALTE CELL
        and al, bh
        or al, bl           ;NEUE CELL
        mov dx, 0x1200
        mov es, dx
        mov [es:di], al     ;Speichere neue cell
        cmp cx, 0
        jne forcalcraser

cpraster:
    push ds
    push si
    mov cx, 0x9600
    mov di, cx
    mov si, cx
    mov dx, 0x1200
    mov es, dx
    mov dx, OFFSET
    mov ds, dx
    forcpraser:
        sub si, 2
        sub di, 2
        mov ax, [es:di]     ;ax <- [NEW CELL]
        mov [ds:si], ax     ;[CELL] <- ax
        cmp di, 0
        jne forcpraser
    pop si
    pop ds

jmp printvv

kbhit:
	mov ah, 0x00	; read keyboard, blocking
	int 0x16
	ret
