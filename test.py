import os
import glob
import subprocess

os.chdir("/home/kimberly/Motif-Scan-Plus/homer/bin")
if bgFile != '':
	subprocess.check_call(['./findMotifs.pl', inputFile,'fasta', 'output/', '-fasta', bgFile])
else:
	subprocess.check_call(['./findMotifs.pl', inputFile,'fasta', 'output/', '-fasta'])
