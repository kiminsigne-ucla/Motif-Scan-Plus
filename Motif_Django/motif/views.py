from django.shortcuts import render
from django.http import HttpResponse


# a view that displays the home page 
def homepage(request):
	return render(request, 'motif/homepage.html')

def scan(request):
	return HttpResponse("Scanning for motifs...")