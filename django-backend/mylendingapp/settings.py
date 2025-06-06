import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv() # Make sure this is at the top of your settings.py

DEBUG = os.getenv('DEBUG', 'False') == 'True' # Default to False if not set
SECRET_KEY = os.getenv('SECRET_KEY', 'a-very-insecure-default-for-dev')

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '').split(',')
if '' in ALLOWED_HOSTS:
    ALLOWED_HOSTS.remove('') # Remove empty string if no hosts are set

# For DATABASE_URL, you might use a library like `dj-database-url` for parsing.
# DATABASES = {
#     'default': dj_database_url.parse(os.getenv('DATABASE_URL'))
# }

WEB3_PROVIDER_URL = os.getenv('WEB3_PROVIDER_URL')
LOAN_MANAGER_ADDRESS = os.getenv('LOAN_MANAGER_ADDRESS')

# Load environment variables from .env file
load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'your-insecure-default-key-for-dev-only') # <<< CRITICAL: Change for production

DEBUG = os.getenv('DJANGO_DEBUG', 'True') == 'True' # Set to False in production

ALLOWED_HOSTS = ['127.0.0.1', 'localhost'] # Add your production domain(s) here

# Application definition
INSTALLED_APPS = [
    'jazzmin',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken', # For token authentication
    'corsheaders',              # For handling CORS (Cross-Origin Resource Sharing)
    'users',
    'loans',
    'wallet',
    'kyc',
    # Other apps
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware', # CORS middleware
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'mylendingapp.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'mylendingapp.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3', # Change to PostgreSQL/MySQL for production
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True

STATIC_URL = 'static/'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom User Model
AUTH_USER_MODEL = 'users.User' # Important!

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated', # Default to requiring authentication
    ],
    'DEFAULT_THROTTLE_CLASSES': [ # Basic rate limiting
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/day',
        'user': '1000/day'
    },
}

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True # <<< CRITICAL: Change to specific origins for production
# CORS_ALLOWED_ORIGINS = [
#     "http://localhost:8000", # Example
#     "http://127.0.0.1:8000",
#     "http://localhost:flutter_app_port", # Replace with your Flutter app's port if running on web
# ]

# Security Settings (for production)
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = 31536000 # 1 year
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_REFERRER_POLICY = 'same-origin'