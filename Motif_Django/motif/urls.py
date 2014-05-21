from django.conf.urls import patterns, include, url

from motif import views

urlpatterns = patterns('',

	url(r'^$', views.homepage, name='home'),

)