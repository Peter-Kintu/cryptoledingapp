from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('users.urls')), # Your users app URLs
    path('api/loans/', include('loans.urls')), # Loans app URLs
    path('api/wallet/', include('wallet.urls')), # Wallet app URLs (for wallet-balance, token-balance)
    path('api/kyc/', include('kyc.urls')), # KYC app URLs
]