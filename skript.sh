COMPILE="TRUE"
DEBUG="FALSE"
DEMO="FALSE"
DEMOFLAG=""
IMAGEFILE="floppy.img"
IMAGESTAN=0
BOOTFILE=""
BOOTSTAN=0


for var in "$@"
do
    if [ $var == "help" ]
    then
        echo keine Parameter für normalen Durchlauf
        echo die Reihenfolge der Parameter ist einzuhalten
        echo Parameter -debug für extra Debug Infos
        echo Parameter -nc ohne Compilierung, nur Virtualisierung
        echo Parameter -demo ohne Compilierung und Vollbild
        echo Parameter -f image.img für Start mit anderem Image
        echo Parameter -b boot.s für compilierung und änderung des bootsektors
        exit 0
    fi
    
    if [ $var == "-nc" ]
    then
        COMPILE="FALSE"
    fi
    
    if [ $var == "-debug" ]
    then
        DEBUG="TRUE"
    fi

    if [ $var == "-demo" ]
    then
        DEMO="TRUE"
    fi

    if [ $IMAGESTAN == 1 ]
    then
        IMAGEFILE=$var
        IMAGESTAN=0
    fi
    
    if [ $var == "-f" ]
    then
        IMAGESTAN=1
    fi

    if [ $BOOTSTAN == 1 ]
    then
        nasm -f bin -g -O0 -o boot.bin $var
        python3 ./util/bincopy.py boot.bin $IMAGEFILE 0
        BOOTSTAN=0
    fi

    if [ $var == "-b" ]
    then
        BOOTSTAN=1
    fi

done

if [ $COMPILE == "TRUE" ]
then
    nasm -f bin -g -O0 -o STARTUP.BIN main.s
    python3 util/bincopy.py STARTUP.BIN $IMAGEFILE 512
fi

if [ $DEMO == "TRUE" ]
then
    DEMOFLAG=" -full-screen"
fi

if [ $DEBUG == "TRUE" ]
then
    ndisasm -b 16 STARTUP.BIN > debug_info/diasm.txt
    #bochs -f debug_info/bochs.conf
    qemu-system-i386 -s -S -m 1024k -drive if=floppy,index=0,format=raw,file=$IMAGEFILE
else
    qemu-system-i386 -vga std $DEMOFLAG -m 1024k -drive if=floppy,index=0,format=raw,file=$IMAGEFILE
fi

