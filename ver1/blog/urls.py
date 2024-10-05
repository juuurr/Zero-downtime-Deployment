from django.urls import path
from . import views

urlpatterns = [
    path('<int:pk>/', views.single_post_page),
    path('', views.index),  # blog/ 경로로 접속할 때 index 뷰를 실행
]