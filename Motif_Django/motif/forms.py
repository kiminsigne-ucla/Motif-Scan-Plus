from django import forms

# class InputForm(forms.Form):
	# inputFile = forms.FileField(
	# 	label = 'Please upload your sequence',
	# 	help_text = 'FASTA format')

class InputForm(forms.Form):
	inputFile = forms.FileField(
		required= True,
		label = 'Please upload your sequence in FASTA format')

	motifType = forms.ChoiceField(
		widget= forms.RadioSelect,
		required = True,
		label = 'Please select a motif type',
		choices = ([('known', 'known motif'), ('denovo', 'de novo motif')])
		)

	# denovoMotif = forms.BooleanField(
	# 	widget = forms.RadioSelect
	# 	)
	# knownMotif = forms.ChoiceField(
	# 	widget = forms.RadioSelect,
	# 	choices = ([('dna', 'DNA'), ('protein', 'protein')])
		# )
	dnaMotifUpload = forms.FileField(
		label ='Your motif file:'
		)
	proteinMotifUpload = forms.CharField(
		widget = forms.Textarea(
				 attrs={'placeholder': "Enter a PROSITE accession or identifier or your own pattern or a combination"}
				 )
		)

	analysisOptions = forms.MultipleChoiceField(
		widget = forms.CheckboxSelectMultiple,
		label = 'Further analysis',
		choices = ([('go', 'GO terms'), ('kegg', 'KEGG pathways'),
					('biocarta', 'BioCarta pathways'), ('omim', 'OMIM disease associations'),
					('meth', 'DNA methylation')])
		)



