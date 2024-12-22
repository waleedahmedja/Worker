import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation

  bool _isSignUp = true; // Determines if the user is signing up or logging in

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Worker Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_isSignUp)
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Name is required' : null,
                  ),
                if (_isSignUp)
                  _buildTextField(
                    controller: _cnicController,
                    label: 'CNIC Number',
                    validator: _validateCnic,
                  ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  validator: _validateEmail,
                ),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _handleSubmit(authProvider),
                  child: Text(_isSignUp ? 'Sign Up' : 'Log In'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log In'
                        : 'Don’t have an account? Sign Up',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a reusable text field with validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscureText,
      validator: validator,
    );
  }

  /// Handles signup/login submission
  Future<void> _handleSubmit(AuthProvider authProvider) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (_isSignUp) {
          await authProvider.signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            cnic: _cnicController.text.trim(),
            role: 'worker', // Role fixed as worker
          );
        } else {
          await authProvider.signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication Successful')),
        );

        // Navigate to worker dashboard
        Navigator.pushReplacementNamed(context, '/worker-dashboard');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Validates the email field
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// Validates the password field
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  /// Validates the CNIC field
  String? _validateCnic(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNIC is required';
    }
    final cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicRegex.hasMatch(value)) {
      return 'Enter a valid CNIC (e.g., 12345-1234567-1)';
    }
    return null;
  }
}
