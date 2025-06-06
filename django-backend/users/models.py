from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    phone_number = models.CharField(max_length=15, unique=True, blank=True, null=True)
    kyc_status = models.CharField(max_length=20, default='pending') # e.g., 'pending', 'verified', 'rejected'
    wallet_address = models.CharField(max_length=42, unique=True, blank=True, null=True) # Ethereum address

    def __str__(self):
        return self.username