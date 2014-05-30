from django.shortcuts import render, render_to_response
from django.http import HttpResponse, HttpResponseRedirect
from django.template import RequestContext
from django.core.urlresolvers import reverse
from django.core.files.uploadedfile import SimpleUploadedFile

from motif.models import Sequence_File
from motif.forms import InputForm


# a view that displays the home page 
def homepage(request):
	return render(request, 'motif/homepage.html')

def scan(request):
	return HttpResponse("Scanning for motifs...")

def homer(request):
	return HttpResponse("HOMER page.")

def processForm(request):
	if request.method == 'POST': # if form has been submitted
		form = InputForm(request.POST, request.FILES) # A form bound to the POST data
		if form.is_valid(): 
			inputFile = Sequence_File(inputFile = request.FILES['inputFile'])
			motifType = form.cleaned_data['motifType']
			analysisOptions = form.cleaned_data['analysisOptions']
			inputFile.save()

			if motifType == 'known':
				return HttpResponseRedirect('/homer/')
			else:
				return HttpResponseRedirect('/scan/')

	else:
		form = InputForm() # unbound form
		# return HttpResponseRedirect('/fail')

	return render(request, 'motif/inputForm.html', {'form': form,})




