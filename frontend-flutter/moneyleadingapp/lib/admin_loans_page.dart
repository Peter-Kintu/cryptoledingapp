// lib/admin_loans_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/constants.dart';
import 'widgets/loading_dialog.dart'; // Ensure this widget exists

class AdminLoansPage extends StatefulWidget {
  final String token;
  const AdminLoansPage({super.key, required this.token});

  @override
  State<AdminLoansPage> createState() => _AdminLoansPageState();
}

class _AdminLoansPageState extends State<AdminLoansPage> {
  List<dynamic> _allLoans = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllLoans();
  }

  Future<void> _fetchAllLoans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/loans/list/'), // This endpoint now returns all loans for admins
        headers: {'Authorization': 'Token ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _allLoans = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load loans: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        print('Error fetching loans: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
      print('Network error fetching loans for admin: $e');
    }
  }

  Future<void> _performLoanAction(int loanId, String action) async {
    showLoadingDialog(context);
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/loans/$loanId/approve/'), // Use your specific approval endpoint
        headers: {
          'Authorization': 'Token ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'action': action}), // 'approve' or 'reject'
      );

      if (mounted) Navigator.pop(context); // Dismiss loading dialog

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan $loanId successfully $action.')),
        );
        _fetchAllLoans(); // Refresh the list
      } else {
        String errorMsg = 'Failed to $action loan $loanId.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMsg = errorData['detail'];
          }
        } catch (e) {
          // ignore
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMsg Status: ${response.statusCode}')),
        );
        print('Error $action loan: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
      print('Network error performing loan action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Loan Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Loans',
            onPressed: _fetchAllLoans,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _allLoans.isEmpty
                  ? const Center(child: Text('No loans found for review.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _allLoans.length,
                      itemBuilder: (context, index) {
                        final loan = _allLoans[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Loan ID: ${loan['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Borrower: ${loan['borrower_username'] ?? 'N/A'}'),
                                Text('Amount: ${loan['amount']}'),
                                Text('Duration: ${loan['duration_months'] ?? '-'} months'),
                                Text('Purpose: ${loan['purpose'] ?? '-'}'),
                                Text('Status: ${loan['status'] ?? '-'}',
                                    style: TextStyle(
                                        color: loan['status'] == 'pending'
                                            ? Colors.orange
                                            : loan['status'] == 'approved'
                                                ? Colors.green
                                                : Colors.red)),
                                // Display approval/disbursement info if available
                                if (loan['approved_by_username'] != null)
                                  Text('Approved By: ${loan['approved_by_username']}'),
                                if (loan['approved_date'] != null)
                                  Text('Approved Date: ${DateTime.parse(loan['approved_date']).toLocal().toString().split('.')[0]}'),
                                if (loan['disbursement_date'] != null)
                                  Text('Disbursement Date: ${DateTime.parse(loan['disbursement_date']).toLocal().toString().split('.')[0]}'),

                                // Action buttons only for 'pending' loans
                                if (loan['status'] == 'pending')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _performLoanAction(loan['id'], 'approve'),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () => _performLoanAction(loan['id'], 'reject'),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Reject'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}