from django.shortcuts import render, render_to_response
from django.http import HttpResponse, HttpResponseRedirect
from django.template import RequestContext
from django.core.urlresolvers import reverse
from django.core.files.uploadedfile import SimpleUploadedFile
import os.path

from motif.models import seqFile,  backgroundFile
from motif.forms import InputForm
from motif.tasks import runHomer

import subprocess
import os.path


# a view that displays the home page 
def homepage(request):
	return render(request, 'motif/homepage.html')

def fail(request):
	return HttpResponse("The form was not filled out correctly. Please go back and try again.")

def checkHomerStatus(job):
	if job.ready() == True:
		return HttpResponseRedirect('/knownMotif/')
	else:
		return HttpResponse("HOMER is running (this will take a few minutes...)")

def homer(request):
	return HttpResponse("HOMER is running (this will take a few minutes...)")

def knownMotif(request):
	return render(request, '/home/kimberly/Motif-Scan-Plus/homer/bin/output/knownResults.html')
	
def denovoMotif(request):
	return render(request, '/home/kimberly/Motif-Scan-Plus/homer/bin/output/homerResults.html')

def noMotifType(request):
	return HttpResponse("Please go back and pick a motif type.")

def prosite(request):
	return HttpResponse("ScanProsite is running (this may take a few minutes...)")

def processForm(request):
	if request.method == 'POST': # if form has been submitted
		form = InputForm(request.POST, request.FILES) # A form bound to the POST data
		if form.is_valid(): 

			seqType = form.cleaned_data['seqType']
			motifType = form.cleaned_data['motifType']
			analysisOptions = form.cleaned_data['analysisOptions']

			# if 'inputFile' in request.FILES:
			# 	seq = seqFile(inputFile = request.FILES['inputFile'], seq_type = seqType)
			# 	seq.save()
			# if 'background' in request.FILES:
			# 	bg = backgroundFile(inputFile = request.FILES['background'])
			# 	bg.save()

			if 'inputFile' in request.FILES:
				seq = seqFile(inputFile = request.FILES['inputFile'], seq_type = seqType)
				seq.save()
				# if seqType == 'dna':

				if 'background' in request.FILES:
					bg = backgroundFile(inputFile = request.FILES['background'])
					bg.save()
					processHomer(request.FILES['inputFile'].name, request.FILES['background'].name, motifType)
					return HttpResponseRedirect('/homer/')
				else:
					processHomer(request.FILES['inputFile'].name, '', motifType)
					return HttpResponseRedirect('/homer/')
					# return HttpResponseRedirect('/homer/')
					# if motifType == 'known':
					# 	return HttpResponseRedirect('/knownMotif/')
					# 	# return HttpResponseRedirect('/homer')
					# elif motifType == 'denovo':
					# 	return HttpResponseRedirect('/denovoMotif/')
					# else:
					# 	return HttpResponseRedirect('/noMotifType/')

			# 	if seqType == 'protein':
			# 		if motifType == 'known':
			# 			return HttpResponseRedirect('/prosite/')
			# 		if motifType == 'denovo':
			# 			if 'background' in request.FILES:
			# 				processHomer(request.FILES['inputFile'].name, request.FILES['background'].name, motifType)
			# 			else:
			# 				processHomer(request.FILES['inputFile'].name, '', motifType)
		else:
			return HttpResponseRedirect('/fail/')
	else:
		form = InputForm() # unbound form
		

	return render(request, 'motif/inputForm.html', {'form': form,})

def processHomer(sequence, background, motifType):

	path = "/home/kimberly/Motif-Scan-Plus/Motif_Django/media/"
	# output = open('/home/kimberly/Motif-Scan-Plus/homer/output.txt', 'w')
	inputFile = path + "sequences/" + sequence

	if background != '':
		bgFile = path + "background/" + background
	else:
		bgFile = ''

	result = runHomer.delay(inputFile, bgFile)

	
# 	os.chdir("/home/kimberly/Motif-Scan-Plus/homer/bin")

# 	if background != '':
# 		bgFile = path + "background/" + background
# 		subprocess.check_call(['./findMotifs.pl', inputFile,'fasta', 'output/', '-fasta', bgFile])
# 	else:
# 		subprocess.check_call(['./findMotifs.pl', inputFile,'fasta', 'output/', '-fasta'])
	


	


	
	






