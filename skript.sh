COMPILE="TRUE"
DEBUG="FALSE"
DEMO="FALSE"
DEMOFLAG=""

for var in "$@"
do
    if [ $var == "help" ]
    then
        echo keine Parameter für normalen Durchlauf
        echo Parameter debug für extra Debug Infos
        echo Parameter nc ohne Compilierung, nur Virtualisierung
        echo Parameter demo ohne Compilierung und Vollbild
        exit 0
    fi
    
    if [ $var == "nc" ]
    then
        COMPILE="FALSE"
    fi
    
    if [ $var == "debug" ]
    then
        DEBUG="TRUE"
    fi

    if [ $var == "demo" ]
    then
        DEMO="TRUE"
    fi
done

if [ $COMPILE == "TRUE" ]
then
    nasm -f bin -g -O0 -o STARTUP.BIN main.s
    python3 util/bincopy.py STARTUP.BIN floppy.img
fi

if [ $DEMO == "TRUE" ]
then
    DEMOFLAG=" -full-screen"
fi

if [ $DEBUG == "TRUE" ]
then
    ndisasm -b 16 STARTUP.BIN > debug_info/diasm.txt
    #bochs -f debug_info/bochs.conf
    qemu-system-i386 -s -S -m 1024k -drive if=floppy,index=0,format=raw,file=floppy.img
else
    qemu-system-i386 -vga std $DEMOFLAG -m 1024k -drive if=floppy,index=0,format=raw,file=floppy.img
fi

