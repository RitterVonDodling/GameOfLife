# cgol
creating a baremetal program for conways game of life

## goal
- create a program that runs cgol in 1600x1200 cells, written in x86 assembly
- 32bit protected mode
- multicore
- multithread
- threadpool
- cells are not calculated individually, but 8 at a time

## status
- not working
- comments are mostly in german, change incoming

## if you want to run it
1. compile main.s:
<br   />nasm -f bin -g -O0 -o STARTUP.BIN main.s
2. compile boot.s
<br   />nasm -f bin -g -O0 -o BOOT.BIN protected.s
3. put  BOOT.BIN & STARTUP.BIN on the bootmedium
<br   />BOOT.BIN from 0 to 512 and STARTUP.BIN from 512 onwards
<br   />you can use the bincopy.py program to do that for you, take a look into skript.sh how to use it
<br   />or use your own bootmedium with a custom bootloader
4. run a vm with your bootmedium in your favorite x86 capable virtualizer
<br   />e.g qemu with: qemu-system-i386 -vga std -m 1024k -drive if=floppy,index=0,format=raw,file=floppy.img

## help
in help/ are files with general information for problem solving

## old
in old/ are older working versions for 
<br/>ax 0x0013 int0x10 320x240 
<br/>0x0012 int0x10 640x480
<br/>boot.s bootloader for 16 bit realmode
<br/>protected.s bootloader for 32bit protected mode
<br/>main32bitSingle.s Mainfile for 32 bit Singlethread, needs protected.s as bootloader

## util
in util/ are some little helper programs in python for debugging and easy manipulation of the .img Files

## special thanks to: 
- https://github.com/nanobyte-dev
- https://github.com/alexfru/BootProg
- https://wiki.osdev.org
- https://github.com/mell-o-tron/OS-Reference

## license
none use it however you want
