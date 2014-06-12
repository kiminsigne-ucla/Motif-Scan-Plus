import subprocess
import os

from motif.tasks import runHomer

os.chdir("/home/kimberly/Motif-Scan-Plus/homer/bin")
path = "/home/kimberly/Motif-Scan-Plus/Motif_Django/media/"
sequence = "crp0.fasta"
inputFile = path + "sequences/" + sequence
background = "crp0.fasta"

inputFile = '/home/kimberly/Motif-Scan-Plus/Motif_Django/media/sequences/crp0.fasta'
bgFile = '/home/kimberly/Motif-Scan-Plus/Motif_Django/media/background/crp0.fasta'
# bgFile = path + "background/" + background


# subprocess.check_call(['./findMotifs.pl', inputFile,'fasta', 'output/', '-fasta'])
result = runHomer.delay(inputFile, bgFile)

if result.ready() == False:
	print result.ready()