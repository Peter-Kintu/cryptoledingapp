from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from .models import User
from .serializers import UserRegisterSerializer, UserProfileSerializer, ChangePasswordSerializer
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

# You'll need to define how you get token_balance, e.g., interacting with a blockchain API
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def token_balance(request):
    # Example placeholder: Replace with actual logic to fetch token balance
    # from a blockchain API based on request.user.wallet_address
    user_wallet_address = request.user.wallet_address
    if not user_wallet_address:
        return Response({"error": "Wallet address not set for user."}, status=status.HTTP_400_BAD_REQUEST)

    # --- Actual logic would go here ---
    # try:
    #     # Example: Query a blockchain explorer API (e.g., Etherscan)
    #     # response = requests.get(f'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=YOUR_TOKEN_CONTRACT_ADDRESS&address={user_wallet_address}&tag=latest&apikey=YOUR_ETHERSCAN_API_KEY')
    #     # data = response.json()
    #     # balance = int(data['result']) / (10**TOKEN_DECIMALS) # Convert from wei/smallest unit
    #     balance = 1000 # Placeholder balance
    # except Exception as e:
    #     return Response({"error": f"Failed to fetch token balance: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({"token_balance": 1000}) # Example value


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,) # Allow unauthenticated users to register
    serializer_class = UserRegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        # Optionally log the user in immediately after registration
        # token, created = Token.objects.get_or_create(user=user)
        # return Response({"token": token.key, "message": "Registration successful and logged in."}, status=status.HTTP_201_CREATED)
        return Response({"message": "Registration successful! Please log in."}, status=status.HTTP_201_CREATED)

class ProfileView(generics.RetrieveAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_object(self):
        # The profile view returns the authenticated user's profile
        return self.request.user

class ProfileUpdateView(generics.UpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        return Response(serializer.data)

class ChangePasswordView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, *args, **kwargs):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        old_password = serializer.validated_data.get('old_password')
        new_password = serializer.validated_data.get('new_password')

        if not user.check_password(old_password):
            return Response({"old_password": ["Wrong password."]}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()
        return Response({"message": "Password changed successfully."}, status=status.HTTP_200_OK)

class WalletBalanceView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, *args, **kwargs):
        wallet_address = request.query_params.get('address', None)
        if not wallet_address:
            # If no address provided, try to use the authenticated user's wallet address
            wallet_address = request.user.wallet_address
            if not wallet_address:
                return Response({"error": "Wallet address not provided and not found for user."}, status=status.HTTP_400_BAD_REQUEST)

        # --- Placeholder for actual blockchain interaction ---
        # In a real app, you'd use web3.py or similar to query an Ethereum node
        # For demonstration, let's return a dummy balance
        try:
            # Example: Using a web3 library to query a node
            # from web3 import Web3
            # w3 = Web3(Web3.HTTPProvider('https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID'))
            # checksum_address = w3.to_checksum_address(wallet_address)
            # balance_wei = w3.eth.get_balance(checksum_address)
            # balance_eth = w3.from_wei(balance_wei, 'ether')
            balance_eth = "5.1234" # Dummy balance for demonstration
            return Response({"wallet_address": wallet_address, "balance": balance_eth}, status=status.HTTP_200_OK)
        except Exception as e:
            # Log the full error: print(f"Error fetching wallet balance: {e}")
            return Response({"error": f"Failed to fetch wallet balance for {wallet_address}. Details: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class KYCVerifyView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, *args, **kwargs):
        user = request.user
        # In a real KYC system, you would integrate with a third-party KYC provider
        # This is a simplified placeholder
        # Expected data in request.data: e.g., 'id_document_url', 'selfie_url', 'name', 'dob'
        
        # Validate incoming KYC data
        # For simplicity, let's just mark as pending/verified immediately
        # You'd typically have a more complex state machine and external calls
        
        # Example: Simulating a KYC submission and setting status
        user.kyc_status = 'submitted' # Or 'pending_review'
        user.save()
        
        # In real-world:
        # 1. Store submitted KYC documents/data securely (e.g., S3, IPFS)
        # 2. Call a KYC provider API (e.g., Onfido, SumSub)
        # 3. Handle webhooks/callbacks from KYC provider to update status
        
        return Response({"message": "KYC verification request submitted. Status: pending review."}, status=status.HTTP_202_ACCEPTED)

    def get(self, request, *args, **kwargs):
        # Allow users to check their current KYC status
        user = request.user
        return Response({"kyc_status": user.kyc_status}, status=status.HTTP_200_OK)