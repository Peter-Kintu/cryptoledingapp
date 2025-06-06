# mylendingapp_backend/wallet/views.py
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from .models import UserWallet
from .serializers import UserWalletSerializer, WalletBalanceSerializer
from web3 import Web3, exceptions as web3_exceptions # Assuming web3.py is installed
import os
from dotenv import load_dotenv

load_dotenv() # Load environment variables

# Configure Web3 provider from .env
WEB3_PROVIDER_URL = os.getenv('WEB3_PROVIDER_URL')
w3 = None
if WEB3_PROVIDER_URL:
    try:
        w3 = Web3(Web3.HTTPProvider(WEB3_PROVIDER_URL))
        if not w3.is_connected():
            print(f"Warning: Web3 is not connected to {WEB3_PROVIDER_URL}")
            w3 = None
    except Exception as e:
        print(f"Error initializing Web3 provider {WEB3_PROVIDER_URL}: {e}")
        w3 = None
else:
    print("WEB3_PROVIDER_URL not set in .env. Wallet balance features will be limited.")


class UserWalletCreateView(generics.CreateAPIView):
    """
    API endpoint for a user to set their wallet address.
    """
    serializer_class = UserWalletSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Ensure the user doesn't already have a wallet linked
        if hasattr(self.request.user, 'wallet_info') and self.request.user.wallet_info:
            return Response(
                {"detail": "User already has a wallet address set. Use update endpoint instead."},
                status=status.HTTP_400_BAD_REQUEST
            )
        serializer.save(user=self.request.user)


class UserWalletRetrieveUpdateView(generics.RetrieveUpdateAPIView):
    """
    API endpoint for a user to retrieve or update their wallet address.
    """
    serializer_class = UserWalletSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        # Ensure the user can only access/update their own wallet
        try:
            return self.request.user.wallet_info
        except UserWallet.DoesNotExist:
            raise status.HTTP_404_NOT_FOUND({"detail": "Wallet address not set for this user."})

class WalletBalanceView(APIView):
    """
    API endpoint to fetch the native token balance of a given wallet address.
    Can be used by authenticated users to check their own wallet or any public address.
    """
    permission_classes = [permissions.AllowAny] # Allow anyone to query public wallet balances

    def get(self, request, *args, **kwargs):
        wallet_address = request.query_params.get('address', None)

        if not wallet_address:
            # If no address provided, try to use the authenticated user's wallet address
            if request.user.is_authenticated:
                try:
                    user_wallet = request.user.wallet_info
                    wallet_address = user_wallet.address
                except UserWallet.DoesNotExist:
                    return Response({"error": "Wallet address not provided and not found for authenticated user."}, status=status.HTTP_400_BAD_REQUEST)
            else:
                return Response({"error": "Wallet address not provided. Please provide an 'address' query parameter."}, status=status.HTTP_400_BAD_REQUEST)

        if not w3:
            return Response({"error": "Blockchain connection not available. Please check WEB3_PROVIDER_URL in .env."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        try:
            # Validate Ethereum address format
            if not w3.is_address(wallet_address):
                return Response({"error": "Invalid Ethereum wallet address format."}, status=status.HTTP_400_BAD_REQUEST)

            checksum_address = w3.to_checksum_address(wallet_address)
            balance_wei = w3.eth.get_balance(checksum_address)
            balance_eth = w3.from_wei(balance_wei, 'ether') # Convert wei to Ether

            serializer = WalletBalanceSerializer(data={
                'wallet_address': wallet_address,
                'balance': str(balance_eth) # Convert Decimal to string for JSON
            })
            serializer.is_valid(raise_exception=True)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except web3_exceptions.InvalidAddress as e:
            return Response({"error": f"Invalid wallet address: {e}"}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            # Log the detailed error on the server side
            print(f"Error fetching wallet balance for {wallet_address}: {e}")
            return Response({"error": "An internal error occurred while fetching wallet balance."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# You can add more views here, e.g., for fetching ERC-20 token balances,
# interacting with the Loan Manager smart contract, etc.
# For ERC-20, you'd need the contract ABI and address.

# Example placeholder for fetching a specific ERC-20 token balance:
@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def erc20_token_balance(request):
    wallet_address = request.query_params.get('address')
    token_contract_address = request.query_params.get('token_address') # e.g., USDC, DAI

    if not all([wallet_address, token_contract_address]):
        return Response({"error": "Both 'address' and 'token_address' are required."}, status=status.HTTP_400_BAD_REQUEST)

    if not w3:
        return Response({"error": "Blockchain connection not available."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    try:
        if not w3.is_address(wallet_address) or not w3.is_address(token_contract_address):
            return Response({"error": "Invalid Ethereum address format for wallet or token contract."}, status=status.HTTP_400_BAD_REQUEST)

        # Example ERC-20 ABI snippet for balanceOf
        ERC20_ABI = [
            {"constant": True,"inputs": [{"name": "_owner","type": "address"}],"name": "balanceOf","outputs": [{"name": "balance","type": "uint256"}],"type": "function"},
            {"constant": True, "inputs": [], "name": "decimals", "outputs": [{"name": "", "type": "uint8"}], "type": "function"},
            {"constant": True, "inputs": [], "name": "symbol", "outputs": [{"name": "", "type": "string"}], "type": "function"},
        ]

        token_contract = w3.eth.contract(address=w3.to_checksum_address(token_contract_address), abi=ERC20_ABI)
        token_balance_raw = token_contract.functions.balanceOf(w3.to_checksum_address(wallet_address)).call()
        token_decimals = token_contract.functions.decimals().call()
        token_symbol = token_contract.functions.symbol().call()

        token_balance_formatted = token_balance_raw / (10**token_decimals)

        return Response({
            "wallet_address": wallet_address,
            "token_address": token_contract_address,
            "symbol": token_symbol,
            "balance": str(token_balance_formatted)
        }, status=status.HTTP_200_OK)

    except Exception as e:
        print(f"Error fetching ERC-20 token balance: {e}")
        return Response({"error": "An error occurred while fetching token balance."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)