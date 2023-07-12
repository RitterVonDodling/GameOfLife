import sys
import debug

if sys.argv[1] == "help":
    print("python3 datainspector.py MemFile")
    exit()

str_File = sys.argv[1]
inhalt_File = bytearray()

#Lade Floppy
program = open(str_File,"rb")
while(zeile := program.read(1)):
    inhalt_File.extend(zeile)
program.close()

print("q = Quit")
print("0xXXXX as hex input")
print("1264 as dez input")
print("1234x as hex output")
print("1234n as bin output")
print("1234i as dec output")
print("1234 - 4567 lists all")
print("1234 - 5627 block8 for 01 02 ... 08")
print("1234b gol for neighbors")
print("")

while(True):
    eingabe = input("Addresse:")
    
    if eingabe == "q":
        break

    eingabe = eingabe.replace(" ","")
    eingabe = eingabe.lower()

    blockindex = 0
    blockindex = eingabe.find("block")
    
    bloecke = 1
    if blockindex != -1:
        bloecke = int(eingabe[blockindex+5:])
        eingabe = eingabe[:blockindex]

    gol = False
    if eingabe.find("gol") != -1:
        eingabe = eingabe[:eingabe.find("gol")]
        gol = True

    formatierung = "08b"

    eingabe = eingabe.split("-")

    startaddresse = eingabe[0]

    if(len(eingabe) == 2):
        endaddresse = eingabe[1]


    if(startaddresse[-1] == "x"):
        startaddresse = startaddresse[:-1]
        formatierung = "2x"
    
    if(startaddresse[-1] == "i"):
        startaddresse = startaddresse[:-1]
        formatierung = "d"
    
    if(startaddresse[-1] == "n"):
        startaddresse = startaddresse[:-1]
        formatierung = "08b"

    if(startaddresse[0:2] == "0x"):
        startaddresse = int(startaddresse[2:],16)
    
    if gol:
        debug.layout(startaddresse,inhalt_File)
    else:
        if(len(eingabe) == 1):
            endaddresse = startaddresse + 1
        else:
            if(endaddresse[-1] == ("n" or "i" or "x")):
                endaddresse = endaddresse[:-1]
            
            if(endaddresse[0:2] == "0x"):
                endaddresse = int(endaddresse[2:],16)

        for addresse in range(int(startaddresse),int(endaddresse),bloecke):
            ausgabe = ""
            try:
                for addressblock in range(addresse,addresse+bloecke,1):
                    ausgabe = ausgabe + str(f'{inhalt_File[int(addressblock)]:{formatierung}}') + " "
                print(hex(addresse) + ": " + ausgabe)
            except Exception as e: print(e)