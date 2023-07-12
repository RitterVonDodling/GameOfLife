#nasm main.s -f elf -g -o debug.elf
#objcopy -O binary debug.elf STARTUP.BIN
#sudo mount -o loop floppy.img mount
#wait
#sudo cp STARTUP.BIN mount/STARTUP.BIN
#wait
#sudo umount mount
#sudo qemu-system-i386 -s -S -m 4096k -drive if=floppy,index=0,format=raw,file=floppy.img
#hexdump -s 17408 -n 1024 -C  cp_floppy.img  #17408 = 0x4400 Addresse von STARTUP.BIN auf floppy.img
#objcopy -O binary main.elf STARTUP.BIN

# QEMU:
# qemu-system-i386 -m 4096k -drive if=floppy,index=0,format=raw,file=floppy.img -s -S -monitor stdio -singlestep


# GDB:
# gdb -x ./gdbskript
# nasm -f elf -g -F dwarf main.s -o main.o
# gdb main.o
# target remote:1234
# tui reg general
# info functions
# c continue, aber kein  singlestep :/
# x/1b 0x1b5ee info memloc



# gdb 
#     target remote :1234
#     info reg
#     tui reg all
#     br *0x0600
#     ignore 2 60
#     si
#     c
#     set $i=0
#     set $end=90
#     while($i<$end)
#         si
#         c
#         set $i=$i+1
#     end
#     dump binary memory result.bin 0x00000 0x9FFFF
#symbol-file debug.elf
