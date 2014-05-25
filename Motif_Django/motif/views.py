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

def processForm(request):
	if request.method == 'POST': # if form has been submitted
		form = InputForm(request.POST, request.FILES) # A form bound to the POST data
		if form.is_valid(): 
			inputFile = Sequence_File(inputFile = request.FILES['inputFile'])
			motifType = form.cleaned_data['motifType']
			analysisOptions = form.cleaned_data['analysisOptions']

	else:
		form = InputForm() # unbound form

	return render(request, 'motif/inputForm.html', {'form': form,})

# def list(request):
# 	if request.method == 'POST':
# 		form = InputForm(request.POST, request.FILES)
# 		if form.is_valid():
# 			# get docfile from form and save it in Sequence_File object
# 			newFile = Sequence_File(inputFile = request.FILES['inputFile'])
# 			newFile.save()

# 			# Redirect to the document list after POST
# 			return HttpResponseRedirect(reverse('motif.views.list'))
# 	else:
# 		form = InputForm() # empty, unbound form

# 	# load document for the list page
# 	documents = Sequence_File.objects.all()

# 	# Render list page with the documents and the form
# 	return render_to_response(
# 		'motif/list.html',
# 		{'documents': documents, 'form': form},
# 		context_instance = RequestContext(request)
	# )


