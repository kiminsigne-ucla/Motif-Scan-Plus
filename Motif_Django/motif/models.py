from django.db import models

# either from uploaded file or database
class Sequence_File(models.Model):
	inputFile = models.FileField(upload_to='sequences/%Y/%m/%d')
	# protein or DNA
	seq_type = models.CharField(max_length = 200)

class Motif(models.Model):
	inputFile = models.FileField(upload_to='motifs/%Y/%m/%d')
	# either de novo or known 
	motif_type = models.CharField(max_length = 200)