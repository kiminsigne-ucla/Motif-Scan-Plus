from django.conf.urls import patterns, include, url

from motif import views

urlpatterns = patterns('',

	# url(r'^$', views.homepage, name='home'),
	url(r'^$', views.processForm, name='process')
	# url(r'^list/$', views.list, name='list')

)