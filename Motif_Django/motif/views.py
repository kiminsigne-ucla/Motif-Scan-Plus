from django.shortcuts import render, render_to_response
from django.http import HttpResponse, HttpResponseRedirect
from django.template import RequestContext
from django.core.urlresolvers import reverse
from django.core.files.uploadedfile import SimpleUploadedFile

from motif.models import seqFile, motifFile, backgroundFile
from motif.forms import InputForm


# a view that displays the home page 
def homepage(request):
	return render(request, 'motif/homepage.html')

def scan(request):
	return HttpResponse("Scanning for motifs...")

def homer(request):
	return HttpResponse("HOMER page.")

def motif(request):
	return HttpResponse("Motif only stuff.")

def processForm(request):
	if request.method == 'POST': # if form has been submitted
		form = InputForm(request.POST, request.FILES) # A form bound to the POST data
		if form.is_valid(): 
			if 'inputFile' in request.FILES:
				seq = seqFile(inputFile = request.FILES['inputFile'])
				bg = backgroundFile(inputFile = request.FILES['background'])
				seq.save()
				bg.save()

			motifType = form.cleaned_data['motifType']
	
			if motifType == 'known':
				if 'dnaMotifUpload' in request.FILES:
					newMotifFile = motifFile(inputFile = request.FILES['dnaMotifUpload'])
					newMotifFile.save()
				if 'proteinMotifUpload' in request.FILES:
					newMotifFile = motifFile(inputFile = request.FILES['proteinMotifUpload'])
					newMotifFile.save()
				if 'inputFile' in request.FILES:
					return HttpResponseRedirect('/homer/')
				else:
					return HttpResponseRedirect('/motif/')
			else:
				return HttpResponseRedirect('/scan/')

			analysisOptions = form.cleaned_data['analysisOptions']

	else:
		form = InputForm() # unbound form
		# return HttpResponseRedirect('/fail')

	return render(request, 'motif/inputForm.html', {'form': form,})




