from django.conf.urls import patterns, include, url
from django.conf import settings
from django.conf.urls.static import static


from django.contrib import admin
admin.autodiscover()

from motif import views

urlpatterns = patterns('',
	url(r'^media/(?P<path>.*)$', 'django.views.static.serve', {'document_root':
		settings.MEDIA_ROOT}),
    url(r'^home/', include('motif.urls')),
    url(r'^admin/', include(admin.site.urls)),
    url(r'^$', include('motif.urls')),
    url(r'^homer/$', views.homer, name='homer'),
    url(r'^knownMotif/$', views.knownMotif),
    url(r'^denovoMotif/$', views.denovoMotif),
    url(r'^noMotifType/$', views.noMotifType),
    url(r'^prosite/$', views.prosite),
    url(r'^fail/$', views.fail),
    ) + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)


