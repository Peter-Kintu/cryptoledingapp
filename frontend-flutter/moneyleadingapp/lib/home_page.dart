// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';
import 'utils/constants.dart';
import 'widgets/loading_dialog.dart'; // Corrected: .h changed to .dart
import 'admin_loans_page.dart';

class HomePage extends StatefulWidget {
  final String title;
  final String token;
  const HomePage({super.key, required this.title, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String profile = 'Loading...';
  List<dynamic> loans = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final _loanRequestFormKey = GlobalKey<FormState>();
  String loanRequestStatus = '';
  final _storage = const FlutterSecureStorage();

  bool _isAdmin = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    fetchProfile();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    _purposeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    _isLoadingProfile = true;
    _fadeController.reset();
    _slideController.reset();

    final response = await http.get(
      Uri.parse('$BASE_URL/api/profile/'),
      headers: {'Authorization': 'Token ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String? wallet = data['wallet_address'];
      String balance = 'N/A';
      if (wallet != null && wallet.isNotEmpty) {
        balance = await fetchWalletBalance(wallet);
      }
      List<dynamic> fetchedLoans = await fetchLoans();

      setState(() {
        profile = '''
Username: ${data['username']}
Phone: ${data['phone_number']}
Wallet: ${wallet ?? 'Not Set'}
KYC: ${data['kyc_status']}
ETH Balance: $balance
''';
        _isAdmin = data['is_staff'] ?? false;
        loans = fetchedLoans;
        _isLoadingProfile = false;
      });
      _fadeController.forward();
      _slideController.forward();
    } else {
      setState(() {
        profile = 'Failed to load profile: ${response.statusCode} - ${response.body}';
        _isLoadingProfile = false;
      });
      if (response.statusCode == 401 || response.statusCode == 403) {
        logout();
      }
    }
  }

  Future<String> fetchWalletBalance(String walletAddress) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/wallet-balance/?address=$walletAddress'),
        headers: {'Authorization': 'Token ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['balance']?.toString() ?? '0';
      } else {
        print('Failed to load balance: ${response.statusCode} - ${response.body}');
        return 'Failed to load balance';
      }
    } catch (e) {
      print('Network error fetching wallet balance: $e');
      return 'Network Error';
    }
  }

  Future<List<dynamic>> fetchLoans() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/loans/list/'),
        headers: {'Authorization': 'Token ${widget.token}'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load loans: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Network error fetching loans: $e');
      return [];
    }
  }

  Future<void> requestLoan() async {
    if (!_loanRequestFormKey.currentState!.validate()) {
      return;
    }

    showLoadingDialog(context); // This method should now be found

    final response = await http.post(
      Uri.parse('$BASE_URL/api/loans/request/'),
      headers: {
        'Authorization': 'Token ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'amount': double.tryParse(_amountController.text) ?? 0,
        'duration_months': int.tryParse(_durationController.text) ?? 0,
        'purpose': _purposeController.text,
      }),
    );

    if (mounted) Navigator.pop(context);

    setState(() {
      if (response.statusCode == 201) {
        loanRequestStatus = 'Loan requested successfully!';
        _amountController.clear();
        _durationController.clear();
        _purposeController.clear();
        fetchProfile();
      } else {
        String errorMessage = 'Failed to request loan.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            errorMessage = errorData.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
          } else {
            errorMessage += ' Status: ${response.statusCode}';
          }
        } catch (e) {
          errorMessage += ' Unexpected server response.';
        }
        loanRequestStatus = errorMessage;
      }
    });
  }

  void logout() async {
    await _storage.delete(key: AUTH_TOKEN_KEY);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminLoansPage(token: widget.token),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, 'Your Profile', Icons.person),
                        _buildProfileCard(),
                        const SizedBox(height: 30),
                        _buildSectionTitle(context, 'Your Loans', Icons.wallet_travel),
                        _buildLoansList(),
                        const SizedBox(height: 30),
                        _buildSectionTitle(context, 'Request a Loan', Icons.request_quote),
                        _buildLoanRequestForm(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark,
              ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileDetailRow(
              context,
              'Username',
              profile.split('\n')[0].split(': ')[1],
              Icons.account_circle,
            ),
            _buildProfileDetailRow(
              context,
              'Phone',
              profile.split('\n')[1].split(': ')[1],
              Icons.phone,
            ),
            _buildProfileDetailRow(
              context,
              'Wallet',
              profile.split('\n')[2].split(': ')[1],
              Icons.wallet,
            ),
            _buildProfileDetailRow(
              context,
              'KYC Status',
              profile.split('\n')[3].split(': ')[1],
              Icons.check_circle_outline,
            ),
            _buildProfileDetailRow(
              context,
              'ETH Balance',
              profile.split('\n')[4].split(': ')[1],
              Icons.currency_bitcoin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansList() {
    return loans.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('No loans found.', style: TextStyle(fontStyle: FontStyle.italic)),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              return _buildLoanCard(loan);
            },
          );
  }

  Widget _buildLoanCard(dynamic loan) {
    Color statusColor;
    switch (loan['status']) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusColor = Colors.blue;
        break;
      case 'active':
        statusColor = Colors.green;
        break;
      case 'repaid':
        statusColor = Colors.greenAccent;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'overdue':
        statusColor = Colors.deepOrange;
        break;
      case 'liquidated':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan ID: ${loan['id']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loan['status'].toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 15, thickness: 1),
            _buildLoanDetailRow(context, 'Amount', '${loan['amount']} ETH'),
            _buildLoanDetailRow(context, 'Duration', '${loan['duration_months'] ?? '-'} months'),
            _buildLoanDetailRow(context, 'Purpose', loan['purpose'] ?? '-'),
            if (loan['status'] == 'approved' || loan['status'] == 'active' || loan['status'] == 'repaid') ...[
              _buildLoanDetailRow(context, 'Approved By', loan['approved_by_username'] ?? 'N/A'),
              _buildLoanDetailRow(
                context,
                'Approved Date',
                loan['approved_date'] != null
                    ? DateTime.parse(loan['approved_date']).toLocal().toString().split('.')[0]
                    : 'N/A',
              ),
              _buildLoanDetailRow(
                context,
                'Disbursement Date',
                loan['disbursement_date'] != null
                    ? DateTime.parse(loan['disbursement_date']).toLocal().toString().split('.')[0]
                    : 'N/A',
              ),
            ],
            if (loan['status'] == 'repaid' || loan['status'] == 'overdue' || loan['status'] == 'liquidated')
              _buildLoanDetailRow(context, 'Repaid Amount', '${loan['repaid_amount'] ?? '0.00'} ETH'),
            if (loan['status'] == 'repaid' && loan['last_repayment_date'] != null)
              _buildLoanDetailRow(
                context,
                'Last Repayment',
                DateTime.parse(loan['last_repayment_date']).toLocal().toString().split('.')[0],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanRequestForm() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _loanRequestFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(context, 'Amount (e.g., 100.00 ETH)', Icons.attach_money),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(context, 'Duration (months, e.g., 6)', Icons.timelapse),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid positive integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _purposeController,
                decoration: _buildInputDecoration(context, 'Purpose (e.g., Business Expansion)', Icons.business_center),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a purpose for the loan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: requestLoan,
                icon: const Icon(Icons.send),
                label: const Text('Request Loan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (loanRequestStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    loanRequestStatus,
                    style: TextStyle(
                      color: loanRequestStatus.contains('successfully') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      BuildContext context, String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }
}