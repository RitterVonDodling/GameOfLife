# cgol
creating a baremetal program for conways game of life

## goal
- create a program that runs cgol in 640x480 cells, written in x86 assembly
- cells are not calculated individually, but 8 at a time

## status
- not working - searching for bugs in the algorithm
- last fixed: wrong segment for loading the old cell
- many more to come
- comments are mostly in german, change incoming

## if you want to run it
1. compile main.s:
<br   />nasm -f bin -g -O0 -o STARTUP.BIN main.s
2. get a bootmedium, e.g. the fat12 floppy from alexfru 
3. put the STARTUP.BIN on the bootmedium
4. run a vm with your bootmedium in your favorite x86 capable virtualizer
<br   />e.g qemu with: qemu-system-i386 -vga std -enable-kvm -m 1024k -drive if=floppy,index=0,format=raw,file=floppy.img

## old
in old/ is an older working version for ax 0x0013 int0x10
and individual cell calculation

## special thanks to: 
- https://github.com/nanobyte-dev
- https://github.com/alexfru/BootProg   for the bootloader
- https://wiki.osdev.org

### license
none use it however you want
