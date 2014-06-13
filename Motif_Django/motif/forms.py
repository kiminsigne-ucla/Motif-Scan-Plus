from django import forms

# class InputForm(forms.Form):
	# inputFile = forms.FileField(
	# 	label = 'Please upload your sequence',
	# 	help_text = 'FASTA format')

class InputForm(forms.Form):
	inputFile = forms.FileField(
		required= False,
		label = 'Please upload your sequence in FASTA format')

	background = forms.FileField(
		required = False, 
		label = 'If you wish to do motif discovery, please upload an appropriate background file in FASTA format')

	seqType = forms.ChoiceField(
		required = False,
		choices = ([('dna', 'DNA'), ('protein', 'protein')])
		)
			
	motifType = forms.ChoiceField(
		widget= forms.RadioSelect,
		required = False,
		label = 'Please select a motif type',
		choices = ([('known', 'known motif'), ('denovo', 'de novo motif')])
		)

	dnaMotifUpload = forms.FileField(
		required = False,
		label ='Your motif file:'
		)
	# proteinMotifUpload = forms.CharField(
	# 	widget = forms.Textarea(
	# 			 attrs={'placeholder': "Enter a PROSITE accession or identifier or your own pattern or a combination"}
	# 			 ),
	# 	required = False
	# 	)
	tomtom = forms.MultipleChoiceField(
		widget = forms.CheckboxSelectMultiple,
		required= False,
		choices = ([('tomtom', 'Tom Tom analysis (this will open a new browser to run commands)')])
		)

	analysisOptions = forms.MultipleChoiceField(
		widget = forms.CheckboxSelectMultiple,
		required = False,
		label = 'Further analysis',
		choices = ([('go', 'GO terms'), ('kegg', 'KEGG pathways'),
					('biocarta', 'BioCarta pathways')])
		)



