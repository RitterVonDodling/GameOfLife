# cgol
creating a baremetal program for conways game of life

## goal
- create a program that runs cgol in 640x480 cells, written in x86asm
- cells are not calculated individually, but 8 at a time

## status
- not working - searching for bugs in the algorithm
- last fixed: forgot to fetch N6
- many more to come
- comments are mostly in german, change incoming

## old
in old/ is an older working version for ax 0x0013 int0x10
and individual cell calculation

## special thanks to: 
- https://github.com/nanobyte-dev       for 
- https://github.com/alexfru/BootProg   for the bootloader
- https://wiki.osdev.org

### license
none use it however you want
