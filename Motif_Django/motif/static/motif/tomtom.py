import time
import sys

inputFile = sys.argv[1]
motifs = open(inputFile, "r")

line = motifs.readline()
print line

s = ''

while True:
    line = motifs.readline().strip()
    if line == '':
        break
    if line.startswith('>') == False:
        s += ' '.join(x for x in map(str, line.split())) + '\n'
    else:
        #print "Opening browser..."
        from splinter import Browser
        browser = Browser()
        browser.visit("http://meme.nbcr.net/meme/cgi-bin/tomtom.cgi")
        #print "Filling form..."
        
        browser.choose("motif_src", "matrix")
        browser.fill("matrix_data", s)
        browser.select("motif_db", 3)
        browser.find_by_name('search').click()
        
        while True:
            time.sleep(4)
            if browser.title.endswith('e'):
                break
        
        #print "Getting txt output..."
        u = browser.url        
        browser.visit(u[:-10]+"tomtom.txt")
        page = browser.html
        browser.quit()
        
        #print "Creating " + u[33:48] + ".txt"
        
        f = open(str(u[33:48]+".txt"), 'w')
        f.write(page[188:-20])
        f.close()        

        s = ''

motifs.close()

done = open('done.txt', 'w')
done.write('done')
done.close()

s = "0.001 0.001 0.997 0.001\n"+\
"0.556 0.001 0.442 0.001\n"+\
"0.001 0.845 0.117 0.037\n"+\
"0.057 0.001 0.874 0.068\n"+\
"0.001 0.997 0.001 0.001\n"+\
"0.001 0.212 0.001 0.786\n"+\
"0.001 0.997 0.001 0.001\n"+\
"0.001 0.997 0.001 0.001\n"+\
"0.001 0.091 0.001 0.907\n"+\
"0.001 0.997 0.001 0.001\n"+\
"0.818 0.180 0.001 0.001\n"+\
"0.001 0.997 0.001 0.001"
'''

'''