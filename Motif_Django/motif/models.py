from django.db import models

# either from uploaded file or database
class Sequence(models.model):
	# protein or DNA
	seq_type = models.CharField(max_length = 200)

class Motif(models.model):
	# either de novo or known 
	motif_type = models.CharField(max_length = 200)