from django.db import models

# either from uploaded file or database
class seqFile(models.Model):
	inputFile = models.FileField(upload_to='sequences/')
	# protein or DNA
	seq_type = models.CharField(max_length = 200)

class motifFile(models.Model):
	inputFile = models.FileField(upload_to='motifs/')

class backgroundFile(models.Model):
	inputFile = models.FileField(upload_to='background/')
