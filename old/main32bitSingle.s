;0x00500 -- 0x07BFF freier Speicher
;   => SEED und andere Zwischenspeicher
;   0x0502 speicherort RNG
;   0x0504 Speicherort PosMask
;   0x0506 - 0x0508 Zwischenspeicher Calcraster
;   0x050C - 0x050F Zwischenspeicher Iteration Calcraster
;   0x0510 SEED
;   0x0512 S2
;   0x0514 S3
;   0x0550 - 0x0600 Graphics Info
;   0x0578 - 0x057B LSB Address
;   0x0600 - 0x0900 Programm
;0x07C00 - 0x07DFF Verweis Bootloader
;0x07E00 -- 0x9FFFF verfügbarer Speicher
;   => Golzwischenspeicher
;   => 0x00010000 -- 0x00050000 für 1600*1200/8 Einträge
;   => 0x00050000 -- 0x00090000 für calcraster Anteil
;   => 0x00090000 -- 0x0009FFFF für stack

;Breite 150 Byte
;Gesamtanzahl Benötigter Speicher 240.000 = 0x3A980

%define OLDRASTER 0x00010000
%define NEWRASTER 0x00050000
%define DIFFOLDRASTER (NEWRASTER - OLDRASTER)
%define RNGADDR 0x00000502
%define SEEDADDR 0x00000510
%define S2ADDR   0x00000512
%define S3ADDR   0x00000514
%define RMUL 39157
%define RADD 43973
%define RDIV 30539
%define ITERATIONS (1600*1200/8)

[BITS 32]
[org 0x7e00]

start:
call initraster
mainloop:
call printvbe
; call kbread
call calcraster
call cpraster
call CountDown
jmp mainloop

CountDown:
    xor al, al
    mov al, BYTE[Counter]
    dec al
    test al, al
    jz stop
    mov BYTE[Counter], al
ret

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
    ret

initraster:
    mov ecx, ITERATIONS
    forinitraster:
        push ecx
        call randint
        ;RNG in ax
        xor ecx, ecx
        pop ecx
        mov edi, ecx
        add edi, OLDRASTER
        mov [edi], al
        dec ecx
        cmp ecx, 0
        jnz forinitraster
    ret

;16 Colors
;0x00 Black
;0x01 Blue
;0x04 Red
;0x0E Yellow
;0x0F White

printvbe:
    mov ecx, ITERATIONS
    mov edx, OLDRASTER
    mov esi, edx
    mov ebx, dword [0x00000578]     ; LOAD LSB Address
    forprintvbe:
        xor edx, edx
        mov dl, [esi]
        push ecx
        xor ecx, ecx
        mov cx, 8
        forprintbit:
            dec cx
            xor dh, dh
            rol dl, 1
            mov dh, 1
            and dh, dl
            mov al, 0x0F
            mul dh
            mov [ebx], al
            inc ebx
            cmp cx, 0 
            jnz forprintbit
        xor ecx, ecx
        pop ecx
        inc esi
        dec ecx
        cmp ecx, 0
        jne forprintvbe
    ret

calcraster:
    mov ecx, ITERATIONS
    forcalcraser:
        dec ecx
        ;START XOR
        mov edi, ecx
        add edi, OLDRASTER
        xor eax, eax
        xor ebx, ebx
        xor edx, edx
        ;cmp cx, 81
        ;jl xorpunktobenmitte
        mov ax, [edi-201]  ;cx -81 = obenlinks
        ror ax, 1          ;N1 in ah
        xorpunktobenmitte:
        ;cmp cx, 80
        ;jl xorpunktlinks
        mov bl, [edi-200]  ;N2 in bl obenmitte
        xor ah, bl          ;x1 in ah
        mov bx, [edi-200]  ;obenrechts
        rol bx, 1           ;N3 in bl
        xorpunktlinks:
        ;cmp cx, 0
        ;je xorpunktmitte
        mov dx, [edi-1]   ;links
        ror dx, 1           ;N4 in dh
        xorpunktmitte:
        xor bl, dh          ;x2 in bl
        mov al, ah          ;cp x1 in al
        and ah, bl          ;xa1 in ah
        xor al, bl          ;xx1 in al
        xor ebx, ebx
        xor edx, edx
        ;cmp cx, 38399
        ;je xorpunktladenende  ;
        xorpunktrechts:
        mov bx, [edi]     ;rechts
        rol bx, 1           ;N5 in bl
        mov dx, [edi+199]  ;untenlinks
        ror dx, 1           ;N6 in dh
        xorpunktuntenlinks:
        ;cmp  cx, 38321
        xor bl, dh          ;x3 in bl
        ;cmp cx, 38320
        ;jge xorpunktletztezeile
        mov bh, [edi+200]  ;N7 in bh untenmitte
        mov dx, [edi+200]  ;untenrechts
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
        push ecx             ;PUSH 3 -> 0xEE
        xor ecx, ecx
        mov ecx, 0x00000506      ;zwischenspeicher 1
        mov edi, ecx
        mov [edi], bh     ;xxx1 -> 0x0506
        mov [edi+1], al   ;xxa1 -> 0x0507
        mov [edi+2], ah   ;xax1 -> 0x0508
        ;ENDE XOR BLOCK
        ;START AND BLOCK
        pop ecx              ;POP 3 <- SP 0xEE   
        mov edi, ecx
        add edi, OLDRASTER
        ;cmp cx, 81
        ;jl andpunktobenmitte
        mov ax, [edi-201]  ;obenlinks
        ror ax, 1           ;N1 in ah
        mov bl, [edi-200]  ;N2 in bl obenmitte
        and ah, bl          ;a1 in ah
        andpunktobenmitte:
        ;cmp cx, 80
        ;jl andpunktlinks
        mov bx, [edi-200]  ;obenrechts
        rol bx, 1           ;N3 in bl
        andpunktlinks:
        ;cmp cx, 0
        ;je andpunktrechts
        mov dx, [edi-1]   ;links
        ror dx, 1           ;N4 in dh
        and bl, dh          ;a2 in bl
        mov al, ah          ;cp a1 -> al
        and ah, bl          ;aa1 in ah
        xor al, bl          ;ax1 in al
        andpunktrechts:
        mov bx, [edi]     ;rechts
        rol bx, 1           ;N5 in bl
        mov dx, [edi+199]  ;untenlinks
        ror dx, 1           ;N6 in dh
        and bl, dh          ;a3 in bl
        mov bh, [edi+200]  ;N7 in bh untenmitte
        mov dx, [edi+200]  ;untenrechts
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
        push ecx             ;PUSH 4 -> SP 0xEE Iteration
        xor ecx, ecx
        mov ecx, 0x00000508
        mov edi, ecx
        mov bh, [edi]       ;xax1 in bh
        mov dh, bh          ;cp xax1 in dh
        xor bh, bl          ;ANDx1 in bh
        mov dl, [edi-1]     ;xxa1 in dl
        xor bh, dl          ;ANDxx1 in bh
        mov dl, [edi-2]     ;xxx1 in dl
        pop ecx             ;POP 4 <- SP 0xEE Iteration -> ecx
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
        mov edi, ecx
        mov esi, ecx
        add edi, NEWRASTER
        add esi, OLDRASTER
        mov al, [esi]       ;ALTE CELL
        and al, bh
        or al, bl           ;NEUE CELL 
        mov [edi], al       ;Speichere neue cell
        cmp ecx, 0
        jne forcalcraser
    ret

cpraster:
    mov ecx, ITERATIONS
    mov edi, ecx
    mov esi, ecx
    add edi, NEWRASTER
    add esi, OLDRASTER
    forcpraser:
        dec edi
        dec esi
        dec ecx
        mov al, [edi]     ;al <- [NEW CELL]
        mov [esi], al     ;[OLD CELL] <- al
        cmp ecx, 0
        jne forcpraser
    ret


kbread:
    mov dx, 0x0060
    xor eax, eax
    in  al, dx       ;lese Port dx nach al 
    mov ah, 1
    and al, ah
    cmp al, 0
    je  kbread
    ;Ab hier keyboard status reset
    mov dx, 0x0060
    xor ax, ax
    mov al, 0x01
    out dx, al
    ret

stop:
    hlt
    hlt
    jmp stop

Counter:
    db 0x0f