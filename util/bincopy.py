import sys

if sys.argv[1] == "help":
    print("python3 bincopy.py BinaryFile FloppyImage")
    exit()

#initialisiere Variablen
str_File = sys.argv[1]
str_Floppy = sys.argv[2]
int_StartProgramAddress = 0x4400
i = 0
inhalt_Programm = bytearray()
inhalt_Floppy_Alt = bytearray()
inhalt_Floppy_Neu = bytearray()

#Lade Floppy
program = open(str_Floppy,"rb")
while(zeile := program.read(1)):
    inhalt_Floppy_Alt.extend(zeile)
program.close()

#Lade Binary und schreibe in Floppy RAM
program = open(str_File,"rb")
while(zeile := program.read(1)):
    inhalt_Floppy_Alt[int_StartProgramAddress] = int.from_bytes(zeile,'little')
    int_StartProgramAddress = int_StartProgramAddress+1 
program.close()

#clear rest
for position in range(int_StartProgramAddress,len(inhalt_Floppy_Alt),1):
    inhalt_Floppy_Alt[position] = 0

#Schreibe Floppy
with open(str_Floppy, 'wb') as file:
    file.write(inhalt_Floppy_Alt)
file.close()