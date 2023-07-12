import array

def layout(i,bytef_Memory):
    obennachbarlinks = str(f'{bytef_Memory[i-82]:08b}')
    obenlinks = str(f'{bytef_Memory[i-81]:08b}')
    obenmitte = str(f'{bytef_Memory[i-80]:08b}')
    obenrechts = str(f'{bytef_Memory[i-79]:08b}')
    obennachbarrechts = str(f'{bytef_Memory[i-78]:08b}')
    links = str(f'{bytef_Memory[i-1]:08b}')
    nachbarlinks = str(f'{bytef_Memory[i-2]:08b}')
    rechts = str(f'{bytef_Memory[i+1]:08b}')
    nachbarrechts = str(f'{bytef_Memory[i+2]:08b}')
    untenlinks = str(f'{bytef_Memory[i+79]:08b}')
    untennachbarlinks = str(f'{bytef_Memory[i+78]:08b}')
    untenmitte = str(f'{bytef_Memory[i+80]:08b}')
    untenrechts = str(f'{bytef_Memory[i+81]:08b}')
    untennachbarrechts = str(f'{bytef_Memory[i+82]:08b}')
    summe = [0,0,0,0,0,0,0,0]
    w, h = 10, 3
    Matrix = [[0 for x in range(w)] for y in range(h)]
    Matrix[0][0] = obenlinks[7]
    for z in range(1,9):
        Matrix[0][z] = obenmitte[z-1]
        Matrix[1][z] = str(f'{bytef_Memory[i]:08b}')[z-1]
        Matrix[2][z] = untenmitte[z-1]
    Matrix[0][9] = obenrechts[0]
    Matrix[1][0] = links[7]
    Matrix[1][9] = rechts[0]
    Matrix[2][0] = untenlinks[7]
    Matrix[2][9] = untenrechts[0]
    print(Matrix[0])
    print(Matrix[1])
    print(Matrix[2])
    for x in range (8):
        summe[x] = int(Matrix[0][x]) + int(Matrix[0][x+1]) + int(Matrix[0][x+2]) 
        summe[x] += int(Matrix[1][x]) + int(Matrix[1][x+2])
        summe[x] += int(Matrix[2][x]) + int(Matrix[2][x+1]) + int(Matrix[2][x+2])
    print(obenlinks+"|"+obenmitte+"|"+obenrechts)
    #print("---------------------------------")
    print(links+"|"+'\033[93m'+str(f'{bytef_Memory[i]:08b}')+'\033[1;37m'+"|"+rechts)
    #print("---------------------------------")
    print(untenlinks+"|"+untenmitte+"|"+untenrechts)
    print("---------------------------------")
    print('Anzahl   ', *summe, sep='')
    print("WertNeu: "+str(f'{bytef_Memory[i+40960]:08b}')+"---------")
    print("Neue Addresse: "+ hex(i+40960))