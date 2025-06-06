import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_page.dart';
import 'registration_page.dart';
import 'utils/constants.dart';
import 'widgets/loading_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String error = '';
  final _storage = const FlutterSecureStorage();

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
    _fadeSlideController.dispose(); // Dispose animation controller
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showLoadingDialog(context);

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (mounted) Navigator.pop(context); // Remove loading indicator

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String token = data['token'];
        await _storage.write(key: AUTH_TOKEN_KEY, value: token);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(title: 'Money lending app', token: token),
          ),
        );
      } else {
        String errorMessage = 'Login failed. Please check your credentials.';
        try {
          final errorData = json.decode(response.body);
          if (errorData.containsKey('non_field_errors')) {
            errorMessage = errorData['non_field_errors'][0];
          } else if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'];
          } else {
            errorMessage = 'Login failed. Status: ${response.statusCode}';
          }
        } catch (e) {
          errorMessage = 'Login failed. Unexpected response from server.';
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

  void createAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0, // No shadow
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // To wrap content
                        children: [
                          // App Logo/Icon
                          Icon(
                            Icons.lock_open,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome Back!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColorDark,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to access your loans',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _usernameController,
                            decoration: _buildInputDecoration(
                                context, 'Username', Icons.person),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            decoration: _buildInputDecoration(
                                context, 'Password', Icons.lock),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: login,
                            icon: const Icon(Icons.login),
                            label: const Text('Login'),
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
                          TextButton(
                            onPressed: createAccount,
                            child: Text(
                              'Don\'t have an account? Register Here',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
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

  InputDecoration _buildInputDecoration(
      BuildContext context, String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // No border for cleaner look
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
// import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // New: Secure Storage
// import 'home_page.dart';
// import 'registration_page.dart';
// import 'utils/constants.dart'; // New: Base URL
// import 'widgets/loading_dialog.dart'; // New: Reusable loading dialog

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>(); // New: Form key for validation
//   String error = '';
//   final _storage = const FlutterSecureStorage(); // New: Secure storage instance

//   @override
//   void dispose() { // New: Dispose controllers
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> login() async {
//     if (!_formKey.currentState!.validate()) { // New: Validate form
//       return;
//     }

//     showLoadingDialog(context); // Use reusable loading dialog

//     try {
//       final response = await http.post(
//         Uri.parse('$BASE_URL/api/login/'), // Use constant
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'username': _usernameController.text,
//           'password': _passwordController.text,
//         }),
//       );

//       Navigator.pop(context); // Remove loading indicator

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         String token = data['token'];
//         await _storage.write(key: AUTH_TOKEN_KEY, value: token); // New: Store token securely

//         if (!mounted) return; // Check if widget is still mounted
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => HomePage(title: 'Money lending app', token: token),
//           ),
//         );
//       } else {
//         // New: Handle different error statuses and provide generic messages
//         String errorMessage = 'Login failed. Please check your credentials.';
//         try {
//           final errorData = json.decode(response.body);
//           if (errorData.containsKey('non_field_errors')) {
//             errorMessage = errorData['non_field_errors'][0];
//           } else if (errorData.containsKey('detail')) {
//             errorMessage = errorData['detail'];
//           } else {
//             // Log raw response.body on backend for debugging, not here
//             errorMessage = 'Login failed. Status: ${response.statusCode}';
//           }
//         } catch (e) {
//           // If response body is not JSON or unexpected, use generic error
//           errorMessage = 'Login failed. Unexpected response from server.';
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

//   void createAccount() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const RegisterPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Form( // New: Wrap with Form for validation
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   TextFormField( // Use TextFormField for validation
//                     controller: _usernameController,
//                     decoration: const InputDecoration(labelText: 'Username'),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your username';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField( // Use TextFormField for validation
//                     controller: _passwordController,
//                     decoration: const InputDecoration(labelText: 'Password'),
//                     obscureText: true,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your password';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: login,
//                     child: const Text('Login'),
//                   ),
//                   TextButton(
//                     onPressed: createAccount,
//                     child: const Text('Create Account'),
//                   ),
//                   if (error.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 16.0),
//                       child: Text(error, style: const TextStyle(color: Colors.red)),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }