from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from .views import RegisterView, ProfileView, ProfileUpdateView, ChangePasswordView, WalletBalanceView, KYCVerifyView, token_balance

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', obtain_auth_token, name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile-update'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('token-balance/', token_balance, name='token-balance'),
    path('wallet-balance/', WalletBalanceView.as_view(), name='wallet-balance'),
    path('kyc-verify/', KYCVerifyView.as_view(), name='kyc-verify'),
]