from django.conf.urls import patterns, include, url
from django.conf import settings
from django.conf.urls.static import static

from motif import views

urlpatterns = patterns('',
	url(r'^$', views.processForm, name='process')
)
