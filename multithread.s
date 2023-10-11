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


; GraphicsInfo:
;         dw 0x0550
;     GraphicsGeneral:
;         dw 0                ;modeattributes
;         dw 0                ;Window A&B
;         dw 0                ;Window Granularity
;         dw 0                ;Window Size
;         dw 0                ;Start Seg WinA
;         dw 0                ;Start Seg WinB
;         dd 0                ;Far Window Pos
;         dw 0                ;Bytes per Scanline
;     GraphicsVESA1:
;         dw 0                ;Width
;         dw 0                ;Hight
;         db 0                ;Hight of Cell
;         db 0                ;Width of cell
;         db 0                ;number of mem planes
;         db 0                ;number of bits per pixel
;         db 0                ;number of banks
;         db 0                ;memory type model
;         db 0                ;size of bank in kb
;         db 0                ;number of image pages
;         db 0                ;reserved
;     GraphicsVESA12:
;         db 0                ;RedMask
;         db 0                ;Red field pos
;         db 0                ;GreenMask
;         db 0                ;Green field pos
;         db 0                ;BlueMask
;         db 0                ;Blue field pos
;         db 0                ;ResMask
;         db 0                ;Res field pos
;         db 0                ;direct color mode
;     GraphicsVESA2:
;         dd 0                ;physical address LVB
;         dd 0                ;pointer offscreen memory
;         dw 0                ;kb offscreen momory
;     GraphicsVESA3:
;         dw 0                ;bytes per scanline
;         db 0                ;number of images for banked
;         db 0                ;number of images for linear
;         db 0                ;direct color red mask
;         db 0                ;direct color red LSB
;         db 0                ;direct color green mask
;         db 0                ;direct color green LSB
;         db 0                ;direct color blue mask
;         db 0                ;direct color blue LSB
;         db 0                ;direct color res mask
;         db 0                ;direct color res LSB
; GraphicsEnd:
; Reserve:
;     dd 0
;     dd 0
;     dd 0


;Bootloader Address
[org 0x7c00]

;equ == const
CODE_SEG equ code_descriptor - GDT_Start
DATA_SEG equ data_descriptor

jmp start

error:
mov ax, 0x0000
int 0x10

errora:
mov ax, 0x0A35
int 0x10
jmp errora


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

start:
cld
mov ax, 0x07e0
mov bx, 0x0000
mov di, bx
mov si, bx
mov es, ax

;read from floppy
call ReadFloppy
call ReadFloppy
call ReadFloppy


setvidgrp:
mov ah, 0x4f        ;VBE
mov al, 0x02        ;Set VBE Videomode
mov bx, 0x411C      ;video mode 1600x1200x8  0x011C
;mov bx, 0x4107      ;video mode 1280x1024x8  0x0107
int 0x10

getvidinfo:
mov ah, 0x4f        ;VBE
mov al, 0x01        ;Get VBE Videomode
mov cx, 0x411C      ;Video Mode
mov bx, 0x0000
mov es, bx
mov di, 0x0550
int 0x10

cmp ax, 0x004f
jne error

enableA20:
mov ax, 0x2401
int 0x15                    ;enable A20

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
mov ax, 0x0010
; load all seg regs to 0x10
mov ds, ax
; flat memory model
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

setupstack:
mov edx, 0x90000000
mov esp, edx

printvbe:
    mov ecx, 0x1D4C00
    mov al, 0x25
    mov ebx, dword [0x00000578]
    forprintvbe:
        mov [ebx], al
        inc ebx
        dec ecx
        cmp ecx, 0
        jne forprintvbe

hlt

jmp 0x00007e00              ;jump to loaded Program


;Fill the rest with '\0'
times 510-($-$$) db 0
dw 0xAA55