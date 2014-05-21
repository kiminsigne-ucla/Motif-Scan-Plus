from django.conf.urls import patterns, include, url

from django.contrib import admin
admin.autodiscover()

from motif import views

urlpatterns = patterns('',

    url(r'^home/', include('motif.urls')),
    url(r'^admin/', include(admin.site.urls)),
    url(r'^$', include('motif.urls')),
    url(r'^scan/', views.scan),
)
