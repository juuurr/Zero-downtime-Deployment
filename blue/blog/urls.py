from django.urls import path
from . import views

urlpatterns = [
    path('', views.PostList.as_view()),
    path('<int:pk>/', views.PostDetail.as_view()),
    #path('', views.index),  # blog/ 경로로 접속할 때 index 뷰를 실행
]