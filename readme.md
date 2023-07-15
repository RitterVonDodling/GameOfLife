# cgol
creating a baremetal program for conways game of life

## goal
- create a program that runs cgol in 640x480 cells, written in x86 assembly
- cells are not calculated individually, but 8 at a time

## status
- finally a working version
- last fixed: a4 had mixed up registers
- next up: optimization
- comments are mostly in german, change incoming

## if you want to run it
1. compile main.s:
<br   />nasm -f bin -g -O0 -o STARTUP.BIN main.s
2. get a bootmedium, e.g. the fat12 floppy from alexfru
3. put the STARTUP.BIN on the bootmedium
4. run a vm with your bootmedium in your favorite x86 capable virtualizer
<br   />e.g qemu with: qemu-system-i386 -vga std -m 1024k -drive if=floppy,index=0,format=raw,file=floppy.img

## old
in old/ is an older working version for ax 0x0013 int0x10 320x240
and individual cell calculation

## special thanks to: 
- https://github.com/nanobyte-dev
- https://github.com/alexfru/BootProg   for the bootloader
- https://wiki.osdev.org

### license
none use it however you want
