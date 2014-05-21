from django.shortcuts import render
from django.http import HttpResponse
from django.template import RequestContext, loader

# a view that displays the home page 
def homepage(request):
	return render(request, 'motif/homepage.html')