;set GDT wer wo was
;flat memory model
;Code Segement descriptor 1001
    ;Present 1
    ;Privilige 00 ring höchst priviligiert
    ;Type 1 code segment
    ;Start 0  Base
    ;Größe 0xfffff Limit
    ;Flags
        ;Type Flags 1010
            ;enthält Code 1
            ;Conforming 0 niedere privilegien können nicht zugreifen
            ;readable 1
            ;accessed 0 wird durch cpu auf 1 gesetzt, wenn in nutzung
        ;Other Flags 1100
            ;Granularität 1 Limit * 0x1000 => zugriff auf volle 4GB RAM
            ;32 bit? 1
            ;00 unused

;Data Segment descriptor 1001
    ;Present 1
    ;Privilige 00 ring höchst priviligiert
    ;Type 1 code segment
    ;Start 0  Base
    ;Größe 0xfffff Limit
    ;Flags
        ;Type Flags 0010
            ;enthält Code 0
            ;direction 0 
            ;writeable 1
            ;accessed 0 wird durch cpu auf 1 gesetzt, wenn in nutzung
        ;Other Flags
            ;Granularität 1 Limit * 0x1000 => zugriff auf volle 4GB RAM
            ;32 bit? 1
            ;00 unused
;db def byte 8bit
;dw def word 16bit
;dd def double 32bit

;Bootloader Address
[org 0x7c00]



;equ == const
CODE_SEG equ code_descriptor - GDT_Start
DATA_SEG equ data_descriptor

setvidgrp:
mov ah, 0x4f        ;VBE
mov al, 0x02        ;Set VBE Videomode
mov bx, 0xC11C      ;video mode 1600x1200x8  0x011C
;mov bx, 0xC107      ;video mode 1280x1024x8  0x0107
int 10h

mov ax, 0x2401
int 0x15            ;enable A20

cli                         ;disable Interrupts != sti
lgdt [GDT_Descriptor]       ;load gdt
mov eax, cr0
or eax, 1
mov cr0, eax                ;letztes Bit von cr0 -> 1, enables 32bit
jmp CODE_SEG:start_protected_mode

GDT_Start:
    null_descriptor:
        dd 0
        dd 0
    code_descriptor:
        dw 0xffff       ;first 16bit of Limit
        dw 0
        db 0            ;first 24bit of Base
        db 10011010b    ;CodeFlags + TypeFlags
        db 11001111b    ;Other Flags + last 4Bits of Limit
        db 0            ;last 8 bit of Base
    data_descriptor:
        dw 0xffff
        dw 0
        db 0
        db 10010010b
        db 11001111b
        db 0
GDT_End:

GDT_Descriptor:
    dw GDT_End - GDT_Start - 1  ;size
    dd GDT_Start                ;pointer to start 

[bits 32]
start_protected_mode:

GrfTest:
mov ax, 0x10
; load all seg regs to 0x10
mov ds, ax
; flat memory model
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov esp, edx
mov edi, esi

printvbe:
    mov ecx, 0xFFFFF
    mov al, 0x25
    mov ebx, 0xA0000
    mov edi, 0x2BF52
    forprintvbe:
        mov [edi], al
        ; inc al
        inc edi
        dec ecx
        cmp ecx, 0
        jne forprintvbe

hlt



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

;Fill the rest with '\0'
times 510-($-$$) db 0
dw 0xAA55