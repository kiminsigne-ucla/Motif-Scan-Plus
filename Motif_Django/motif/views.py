from django.shortcuts import render, render_to_response
from django.http import HttpResponse, HttpResponseRedirect
from django.template import RequestContext
from django.core.urlresolvers import reverse
from django.core.files.uploadedfile import SimpleUploadedFile
import os.path

from motif.models import seqFile,  backgroundFile, motifFile
from motif.forms import InputForm
from motif.tasks import runHomer, runTomtom

import subprocess
import os.path
import glob 

result = ''

# a view that displays the home page 
def homepage(request):
	return render(request, 'motif/homepage.html')

def fail(request):
	return HttpResponse("The form was not filled out correctly. Please go back and try again.")


def checkHomerStatusKnown(request):
	if os.path.isfile('/home/kimberly/Motif-Scan-Plus/homer/bin/output/knownResults.html') == False:
		return render(request, 'motif/runKnown.html')
	else:
		return HttpResponseRedirect('/knownMotif/')

def checkHomerStatusDenovo(request):
	# os.mkdir('/home/kimberly/Motif-Scan-Plus/homer/bin/output/')
	os.chdir('/home/kimberly/Motif-Scan-Plus/homer/bin/output/')
	# tmpFiles = glob.glob("*.tmp")
	# if len(tmpFiles) != 0:
	if os.path.isfile('/home/kimberly/Motif-Scan-Plus/homer/bin/output/group.ug.txt') == True:
		return render(request, 'motif/runDenovo.html')
	else:
		return HttpResponseRedirect('/denovoMotif/')

def checkTomtom(request):
	if os.path.isfile('/home/kimberly/Motif-Scan-Plus/Motif_Django/motif/static/motif/done.txt') == False:
		return render(request, 'motif/runningTomtom.html')
	else:
		processTomtom()
		return HttpResponseRedirect('/static/TomTom_final_output.txt')


def homer(request):
	return HttpResponse("HOMER is running (this will take a few minutes...)")

def knownMotif(request):
	return HttpResponseRedirect('/static/knownResults.html')

def denovoMotif(request):
	return HttpResponseRedirect('/static/homerResults.html')

def noMotifType(request):
	return HttpResponse("Please go back and pick a motif type.")

def prosite(request):
	return HttpResponse("ScanProsite is running (this may take a few minutes...)")

def processForm(request):
	if request.method == 'POST': # if form has been submitted
		form = InputForm(request.POST, request.FILES) # A form bound to the POST data
		if form.is_valid(): 

			# seqType = form.cleaned_data['seqType']
			motifType = form.cleaned_data['motifType']
			analysisOptions = form.cleaned_data['analysisOptions']
			tomtom = form.cleaned_data['tomtom']

			if 'inputFile' in request.FILES:
				seq = seqFile(inputFile = request.FILES['inputFile'])
				seq.save()
				# if seqType == 'dna':

				if 'background' in request.FILES:
					bg = backgroundFile(inputFile = request.FILES['background'])
					bg.save()
					processHomer(request.FILES['inputFile'].name, request.FILES['background'].name, motifType)
	
				else:
					processHomer(request.FILES['inputFile'].name, '', motifType)

				
				
				if motifType == 'known':
					return HttpResponseRedirect('/checkHomerStatusKnown/')
				if motifType == 'denovo':
					return HttpResponseRedirect('/checkHomerStatusDenovo/')

			if 'dnaMotifUpload' in request.FILES:
				motifs = motifFile(inputFile = request.FILES['dnaMotifUpload'])
				motifs.save()
				inputFile = '/home/kimberly/Motif-Scan-Plus/Motif_Django/media/motifs/' + request.FILES['dnaMotifUpload'].name
				runTomtom(inputFile)
				return HttpResponseRedirect('/checkTomtom/')


		else:
			return HttpResponseRedirect('/fail/')
	else:
		form = InputForm() # unbound form
		

	return render(request, 'motif/inputForm.html', {'form': form,})

def processHomer(sequence, background, motifType):

	path = "/home/kimberly/Motif-Scan-Plus/Motif_Django/media/"
	inputFile = path + "sequences/" + sequence

	if background != '':
		bgFile = path + "background/" + background
	else:
		bgFile = ''

	result = runHomer.delay(inputFile, bgFile)

def processTomtom():
	os.chdir('/home/kimberly/Motif-Scan-Plus/Motif_Django/motif/static/motif')
	output = open('TomTom_final_output.txt', 'w')
	for tomtomFile in glob.glob("tomtom_*"):
		inputFile = open(tomtomFile, 'r')
		for line in inputFile.readlines():
			output.write(line)
		
		os.remove(tomtomFile)

	output.close()

	






	


	


	
	






