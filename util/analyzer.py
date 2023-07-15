import sys

# if sys.argv[1] == "help":
#     print("python3 datainspector.py LogFile")
#     exit()
# str_File = sys.argv[1]

def getvalue(step,register):
    index = str(inhalt_Log[int(step)][register]).rfind("x")
    retstr = (str(inhalt_Log[int(step)][register])[index-1:])
    return retstr[:len(retstr)-1]



str_Logfile = "gdb.txt"
str_diasm = "debug_info/diasm.txt"
instruction=["ah","al","bh","bl","ch","cl","dh","dl","ip","instruction","",""]
w, h = 12, 700
inhalt_Log = [[0 for x in range(w)] for y in range(h)] 
inhalt_Diasm=[]
counter = 0
info = 0


#Lade Logfile
program = open(str_Logfile,"r")
while True:
    zeile = program.readline()
    if zeile[0:2] == "0x":
        info = 0
        counter+=1
    elif not zeile:
        break
    else:
        inhalt_Log[counter][info] = zeile
        info+=1
program.close()

#Lade Diasm
program = open(str_diasm,"r")
while(zeile := program.readline()):
    inhalt_Diasm.append(zeile)
program.close()

auswahl = "0"
step = 0
while(1):
    print("(n)ext,(p)revious,(q)uit")
    auswahl=input("zeilennummer")
    if auswahl == "q":
        break
    
    elif auswahl == "p":
        step -=1
    elif auswahl == "n":
        step+=1
    else:
        step=int(auswahl)
    
    print("ah: "+ getvalue(step,0))
    print("al: "+ getvalue(step,1))
    print("bh: "+ getvalue(step,2))
    print("bl: "+ getvalue(step,3))
    print("ch: "+ getvalue(step,4))
    print("cl: "+ getvalue(step,5))
    print("dh: "+ getvalue(step,6))
    print("dl: "+ getvalue(step,7))
    print("xxx1: "+ getvalue(step,8))
    print("xxa1: "+ getvalue(step,9))
    print("xax1: "+ getvalue(step,10))
    print("IP: "+ getvalue(step,11))