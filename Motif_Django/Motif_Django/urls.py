from django.conf.urls import patterns, include, url

from django.contrib import admin
admin.autodiscover()


urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'Motif_Django.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^motif/', include('motif.urls')),
    url(r'^admin/', include(admin.site.urls)),
)
