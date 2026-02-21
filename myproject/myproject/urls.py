from django.contrib import admin
from django.urls import path
from django.http import HttpResponse


def home(request):
    return HttpResponse(
        "<h1>Django + PostgreSQL + Nginx in Docker</h1>"
        "<p>The application is running successfully!</p>"
        "<p><a href='/admin/'>Admin Panel</a></p>"
    )


urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home),
]
