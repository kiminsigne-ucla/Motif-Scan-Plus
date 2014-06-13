# from __future___ import absolute_import

import os
import subprocess

from celery import Celery

from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Motif_Django.settings')

# app = Celery('tasks', backend='amqp', broker='amqp://localhost')
app = Celery('Motif_Django')

app.config_from_object('django.conf:settings')
app.autodiscover_tasks(lambda: settings.INSTALLED_APPS)
app.conf.update(CELERY_RESULT_BACKEND='djcelery.backends.database:DatabaseBackend')

@app.task(bind=True)
def debug_task(self):
	print('Request: {0!r}'.format(self.request))

@app.task(bind=True)
def runHomer(self, inputFile, bgFile):
	os.chdir("/home/kimberly/Motif-Scan-Plus/homer/bin")
	if bgFile != '':
		subprocess.check_call(['./findMotifs.pl', inputFile,'fasta', 'output/', '-fasta', bgFile])
	else:
		subprocess.check_call(['./findMotifs.pl', inputFile,'fasta', 'output/', '-fasta'])

@app.task(bind=True)
def runTomtom(self, inputFile):
	os.chdir("/home/kimberly/Motif-Scan-Plus/Motif_Django/motif/static/motif")
	subprocess.check_call(['python', 'tomtom.py', inputFile])