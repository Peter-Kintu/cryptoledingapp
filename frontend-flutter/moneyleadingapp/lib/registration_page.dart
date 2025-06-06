import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart'; // Ensure this is imported for navigation
import 'utils/constants.dart';
import 'widgets/loading_dialog.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String error = '';
  String success = '';

  // Animation Controllers
  late AnimationController _fadeSlideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut));

    _fadeSlideController.forward(); // Start animation when page loads
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _fadeSlideController.dispose(); // Dispose animation controller
    super.dispose();
  }

  Future<void> register() async {
    setState(() {
      error = '';
      success = '';
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // This password check logic is within your original `register` function,
    // so I'm keeping it here as per your request not to change functions.
    // However, it's generally better to place this validation within the
    // TextFormField's validator for `_confirmPasswordController`.
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        error = 'Passwords do not match!'; // Use 'error' for mismatch
      });
      return;
    }


    showLoadingDialog(context);

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'phone_number': _phoneController.text,
        }),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 201) {
        setState(() {
          success = 'Registration successful! You can now log in.';
          // Optionally clear fields
          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _phoneController.clear();
        });
        // Added a slight delay before navigating back to login for better UX
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        });
      } else {
        String errorMessage = 'Registration failed. Please try again.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            errorMessage = errorData.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
          } else {
            errorMessage = 'Registration failed. Status: ${response.statusCode}';
          }
        } catch (e) {
          errorMessage = 'Registration failed. Unexpected response from server.';
        }
        setState(() {
          error = errorMessage;
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() {
        error = 'Network error. Please check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Theme.of(context).primaryColor, // Consistent color
        elevation: 0, // No shadow
      ),
      body: Container(
        // Consistent gradient background
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  // Elevated card with rounded corners
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0), // Increased padding
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Eye-catching icon for registration
                          Icon(
                            Icons.person_add,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 20),
                          // Engaging title and subtitle
                          Text(
                            'Create Your Account',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColorDark,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Join our P2P lending platform',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 30),
                          // Username field
                          TextFormField(
                            controller: _usernameController,
                            decoration: _buildInputDecoration(
                                context, 'Username', Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          // Phone Number field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _buildInputDecoration(
                                context, 'Phone Number', Icons.phone),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              // Basic phone number validation regex
                              if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                                return 'Enter a valid phone number (e.g., +2567xxxxxxxx)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            decoration: _buildInputDecoration(
                                context, 'Password', Icons.lock_outline),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          // Confirm Password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: _buildInputDecoration(
                                context, 'Confirm Password', Icons.lock_reset),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              // This validation is crucial and complements the `register()` function's check
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          // Register Button
                          ElevatedButton.icon(
                            onPressed: register,
                            icon: const Icon(Icons.app_registration),
                            label: const Text('Register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              textStyle: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Error message display
                          if (error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Text(
                                error,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // Success message display
                          if (success.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Text(
                                success,
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 10),
                          // Back to Login button
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Goes back to the previous route (Login Page)
                            },
                            child: Text(
                              'Already have an account? Login Here',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for consistent input decoration
  InputDecoration _buildInputDecoration(
      BuildContext context, String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }
}































// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'utils/constants.dart'; // New: Base URL
// import 'widgets/loading_dialog.dart'; // New: Reusable loading dialog

// class RegisterPage extends StatefulWidget {
//   const RegisterPage({super.key});
//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController(); // New: Confirm Password
//   final TextEditingController _phoneController = TextEditingController();
//   final _formKey = GlobalKey<FormState>(); // New: Form key for validation
//   String error = '';
//   String success = '';

//   @override
//   void dispose() { // New: Dispose controllers
//     _usernameController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> register() async {
//     setState(() {
//       error = '';
//       success = '';
//     });

//     if (!_formKey.currentState!.validate()) { // New: Validate form
//       return;
//     }

//     showLoadingDialog(context); // Use reusable loading dialog

//     try {
//       final response = await http.post(
//         Uri.parse('$BASE_URL/api/register/'), // Use constant
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'username': _usernameController.text,
//           'password': _passwordController.text,
//           'phone_number': _phoneController.text,
//         }),
//       );

//       Navigator.pop(context); // Remove loading indicator

//       if (response.statusCode == 201) {
//         setState(() {
//           success = 'Registration successful! You can now log in.';
//           // Optionally clear fields
//           _usernameController.clear();
//           _passwordController.clear();
//           _confirmPasswordController.clear();
//           _phoneController.clear();
//         });
//       } else {
//         String errorMessage = 'Registration failed. Please try again.';
//         try {
//           final errorData = json.decode(response.body);
//           if (errorData is Map) {
//             // Iterate through errors to provide more specific feedback
//             errorMessage = errorData.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
//           } else {
//             errorMessage = 'Registration failed. Status: ${response.statusCode}';
//           }
//         } catch (e) {
//           errorMessage = 'Registration failed. Unexpected response from server.';
//         }
//         setState(() {
//           error = errorMessage;
//         });
//       }
//     } catch (e) {
//       if (mounted) Navigator.pop(context); // Remove loading indicator if still mounted
//       setState(() {
//         error = 'Network error. Please check your connection.'; // Generic network error
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Register')),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Form( // New: Wrap with Form for validation
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   TextFormField( // Use TextFormField
//                     controller: _usernameController,
//                     decoration: const InputDecoration(labelText: 'Username'),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a username';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField( // Use TextFormField
//                     controller: _passwordController,
//                     decoration: const InputDecoration(labelText: 'Password'),
//                     obscureText: true,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a password';
//                       }
//                       if (value.length < 8) {
//                         return 'Password must be at least 8 characters long';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField( // New: Confirm Password Field
//                     controller: _confirmPasswordController,
//                     decoration: const InputDecoration(labelText: 'Confirm Password'),
//                     obscureText: true,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please confirm your password';
//                       }
//                       if (value != _passwordController.text) {
//                         return 'Passwords do not match';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField( // Use TextFormField
//                     controller: _phoneController,
//                     decoration: const InputDecoration(labelText: 'Phone Number'),
//                     keyboardType: TextInputType.phone,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your phone number';
//                       }
//                       // Basic regex for phone number validation
//                       if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
//                         return 'Enter a valid phone number (e.g., +2567xxxxxxxx)';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: register,
//                     child: const Text('Register'),
//                   ),
//                   if (error.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 16.0),
//                       child: Text(error, style: const TextStyle(color: Colors.red)),
//                     ),
//                   if (success.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 16.0),
//                       child: Text(success, style: const TextStyle(color: Colors.green)),
//                     ),
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Back to Login'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }