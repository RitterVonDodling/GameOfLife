;0x00500 -- 0x07BFF freier Speicher
;   => SEED und andere Zwischenspeicher
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
;   => 0x10000 -- 0x50000 für 1600*1200/8 Einträge
;   => 0x50000 -- 0x60000 für calcraster Anteil
;   => 0x90000 -- 0x9FFFF für stack

;Breite 200 Byte
;Gesamtanzahl Benötigter Speicher 240.000 = 0x3A980

%define OFFSET 0x00000800
%define RNGADDR 0x00000502
%define SEEDADDR 0x0000050E
%define S2ADDR 0x00000510
%define S3ADDR 0x00000512
%define RMUL 39157
%define RADD 43973
%define RDIV 30539

[BITS 32]

jmp start

randint:
; ; Wichmann–Hill PRNG
; ;   [r, s1, s2, s3] = function(s1, s2, s3) is
; ;     // s1, s2, s3 should be random from 1 to 30,000. Use clock if available.
; ;     s1 := 171 × mod(s1, 177) − 2 × floor(s1 / 177)
; ;     s2 := 172 × mod(s2, 176) − 35 × floor(s2 / 176)
; ;     s3 := 170 × mod(s3, 178) − 63 × floor(s3 / 178)

; ;     r := mod(s1/30269 + s2/30307 + s3/30323, 1)

; ;       s1 = SEED
; ;       s2 = SEED*SEED[8-24]
; ;       s3 = S2*S2[8-24]

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
    ; mov ax, 0x9000
    ; mov ss, ax
    ; mov esp, 0x90000000

initraster:
    mov cx, 0x9600
    forinitraster:
        push cx
        call randint
        pop cx
        dec cx
        ; mov bx, cx
        ; mov di, cx
        ; push ds
        ; mov ax, 0x0000
        ; mov ds, ax
        ; mov dx, [RNGADDR]    ;LOAD RANDINT
        ; mov ax, OFFSET
        ; mov es, ax
        ; mov [di], dx
        ; pop ds
        ; cmp cx, 0
        jnz forinitraster


printvbe:
    mov ecx, 0x1D4C00
    mov al, 0x12
    mov ebx, dword [0x00000578]
    forprintvbe:
        mov [ebx], al
        inc ebx
        dec ecx
        cmp ecx, 0
        jne forprintvbe
jmp printvbe

;16 Farben
;0x00 Schwarz
;0x01 Blau
;0x04 Rot
;0x0E Gelb
;0x0F Weiß






printvv:
    mov cx, 0x9600      ;38400 in Dez       
    mov ebx, 0xA0000      ;SEGMENT GRFMEM
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
        mov bx, [si]     ;bx <- [CELL]
        mov [0x00000578], bx     ;[GRF] <- bx
        cmp di, 0
        jne forprintvv
    pop si
    pop ds

; hlt
    ; call kbhit

calcraster:
    mov cx, 0x9600
    forcalcraser:
        dec cx
        mov bx, 0x0000
        mov es, bx
        mov bx, 0x050C      ;SPEICHERORT iteration
        mov di, bx
        mov [di], cx     ;SAVE iteration
        ;START XOR
        mov bx, OFFSET      ;OFFSET CELL
        mov es, bx
        mov di, cx
        mov ax, 0x0000
        mov bx, 0x0000
        mov dx, 0x0000
        ;cmp cx, 81
        ;jl xorpunktobenmitte
        mov ax, [di-81]  ;cx -81 = obenlinks
        ror ax, 1          ;N1 in ah
        xorpunktobenmitte:
        ;cmp cx, 80
        ;jl xorpunktlinks
        mov bl, [di-80]  ;N2 in bl obenmitte
        xor ah, bl          ;x1 in ah
        mov bx, [di-80]  ;obenrechts
        rol bx, 1           ;N3 in bl
        xorpunktlinks:
        ;cmp cx, 0
        ;je xorpunktmitte
        mov dx, [di-1]   ;links
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
        mov bx, [di]     ;rechts
        rol bx, 1           ;N5 in bl
        mov dx, [di+79]  ;untenlinks
        ror dx, 1           ;N6 in dh
        xorpunktuntenlinks:
        ;cmp  cx, 38321
        xor bl, dh          ;x3 in bl
        ;cmp cx, 38320
        ;jge xorpunktletztezeile
        mov bh, [di+80]  ;N7 in bh untenmitte
        mov dx, [di+80]  ;untenrechts
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
        mov [di], bh     ;xxx1 -> 0x0506
        mov [di+1], al   ;xxa1 -> 0x0507
        mov [di+2], ah   ;xax1 -> 0x0508
        ;ENDE XOR BLOCK
        ;START AND BLOCK
        mov cx, OFFSET
        mov es, cx
        pop cx              ;POP 3 <- SP 0xEE   
        mov di, cx
        ;cmp cx, 81
        ;jl andpunktobenmitte
        mov ax, [di-81]  ;obenlinks
        ror ax, 1           ;N1 in ah
        mov bl, [di-80]  ;N2 in bl obenmitte
        and ah, bl          ;a1 in ah
        andpunktobenmitte:
        ;cmp cx, 80
        ;jl andpunktlinks
        mov bx, [di-80]  ;obenrechts
        rol bx, 1           ;N3 in bl
        andpunktlinks:
        ;cmp cx, 0
        ;je andpunktrechts
        mov dx, [di-1]   ;links
        ror dx, 1           ;N4 in dh
        and bl, dh          ;a2 in bl
        mov al, ah          ;cp a1 -> al
        and ah, bl          ;aa1 in ah
        xor al, bl          ;ax1 in al
        andpunktrechts:
        mov bx, [di]     ;rechts
        rol bx, 1           ;N5 in bl
        mov dx, [di+79]  ;untenlinks
        ror dx, 1           ;N6 in dh
        and bl, dh          ;a3 in bl
        mov bh, [di+80]  ;N7 in bh untenmitte
        mov dx, [di+80]  ;untenrechts
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
        mov bh, [di]     ;xax1 in bh
        mov dh, bh          ;cp xax1 in dh
        xor bh, bl          ;ANDx1 in bh
        mov dl, [di-1]   ;xxa1 in dl
        xor bh, dl          ;ANDxx1 in bh
        mov dl, [di-2]   ;xxx1 in dl
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
        mov cx, [di]     ;LOAD Iteration CX = +-0
        mov di, cx
        mov dx, OFFSET
        mov es, dx
        mov al, [di]     ;ALTE CELL
        and al, bh
        or al, bl           ;NEUE CELL
        mov dx, 0x1200
        mov es, dx
        mov [di], al     ;Speichere neue cell
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
        mov ax, [di]     ;ax <- [NEW CELL]
        mov [si], ax     ;[CELL] <- ax
        cmp di, 0
        jne forcpraser
    pop si
    pop ds

jmp printvv

; kbhit:
; 	mov ah, 0x00	; read keyboard, blocking
; 	int 0x16
; 	ret
