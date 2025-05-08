import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false; // Start in signup mode
  bool rememberMe = false;
  bool acceptedTerms = false;
  Color buttonColor = const Color(0xFF007BFF); // Track button color

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _loadCredentials();

    // Redirect to home if already logged in
    if (box.read('isLoggedIn') == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }

    // Listen for isLoggedIn changes
    box.listenKey('isLoggedIn', (value) {
      if (mounted) {
        final route = value == true ? '/home' : '/';
        Navigator.pushReplacementNamed(context, route);
      }
    });
  }

  void _loadCredentials() {
    final savedEmail = box.read('email');
    final savedPass = box.read('password');

    if (savedEmail != null && savedPass != null) {
      emailController.text = savedEmail;
      passwordController.text = savedPass;
      rememberMe = true;
    }
  }

  void _showStyledSnackBar(String message, {IconData icon = Icons.info, bool isError = false}) {
    final backgroundColor = isError ? Colors.redAccent : Colors.deepPurple;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
        backgroundColor: backgroundColor,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCredentials() async {
    if (rememberMe || !isLogin) {
      box.write('name', nameController.text);
      box.write('email', emailController.text);
      box.write('phone', phoneController.text);
      box.write('password', passwordController.text);
      box.write('isLoggedIn', true);
    } else {
      box.remove('name');
      box.remove('email');
      box.remove('phone');
      box.remove('password');
      box.write('isLoggedIn', false);
    }
  }

  void _toggleMode() {
    setState(() => isLogin = !isLogin);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(
            '''
By using Pixel Page, you agree to the following Terms & Conditions:

1. Account Information: You must provide accurate personal information during registration. You are responsible for maintaining the confidentiality of your login credentials.

2. Data Storage: Your name, email, phone number, and password are securely stored on your device using encrypted local storage (GetStorage).

3. QR Code Usage: QR codes are generated and encrypted by Pixel Page. Tampering or misuse of QR codes may result in restricted access.

4. Permissions: Pixel Page requires access to your device's camera, storage, and gallery solely for scanning and saving educational content.

5. Data Loss: Pixel Page is not liable for any data loss that may occur due to device resets or app deletion.

6. Security: While your data is stored locally and not shared externally, you are responsible for your device’s security and backup.

7. Usage Scope: Pixel Page is intended for educational use only. Commercial reproduction or redistribution without consent is prohibited.

By continuing, you confirm you’ve read and accepted these terms.
            ''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF007BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                "Pixel Page",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin ? "Welcome back!" : "Let's get started!",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Form(
                  key: isLogin ? _loginFormKey : _signupFormKey,
                  child: Column(
                    children: [
                      // Signup fields (only in signup mode)
                      if (!isLogin) ...[
                        _buildField(nameController, "Full Name", Icons.person),
                        const SizedBox(height: 12),
                        _buildField(phoneController, "Phone Number", Icons.phone),
                        const SizedBox(height: 12),
                      ],
                      _buildField(emailController, "Email", Icons.email),
                      const SizedBox(height: 12),
                      _buildField(passwordController, "Password", Icons.lock, obscure: true),
                      const SizedBox(height: 8),
                      if (isLogin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (v) => setState(() => rememberMe = v!),
                            ),
                            const Text("Remember Me"),
                          ],
                        ),
                      if (!isLogin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: acceptedTerms,
                              onChanged: (v) => setState(() => acceptedTerms = v!),
                            ),
                            GestureDetector(
                              onTap: _showTermsDialog,
                              child: const Text(
                                "I accept Terms & Conditions",
                                style: TextStyle(decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if ((isLogin && _loginFormKey.currentState!.validate()) ||
                              (!isLogin && _signupFormKey.currentState!.validate())) {
                            if (!isLogin && !acceptedTerms) {
                              _showStyledSnackBar(
                                'You must accept Terms and Conditions to sign up.',
                                icon: Icons.error_outline,
                                isError: true,
                              );
                              return;
                            }

                            if (isLogin) {
                              final savedEmail = box.read('email');
                              final savedPassword = box.read('password');

                              if (emailController.text == savedEmail &&
                                  passwordController.text == savedPassword) {
                                await _saveCredentials();
                                setState(() {
                                  buttonColor = Colors.green[700]!; // Success color
                                });
                                _showStyledSnackBar(
                                  'Login successful!',
                                  icon: Icons.check_circle_outline,
                                  isError: false,
                                );
                                box.write('isLoggedIn', true);
                                // Revert button color after 1 second
                                Future.delayed(const Duration(seconds: 1), () {
                                  if (mounted) {
                                    setState(() {
                                      buttonColor = primaryColor;
                                    });
                                  }
                                });
                                Navigator.pushReplacementNamed(context, '/home');
                              } else {
                                _showStyledSnackBar(
                                  'Incorrect email or password',
                                  icon: Icons.error_outline,
                                  isError: true,
                                );
                              }
                            } else {
                              await _saveCredentials();
                              setState(() {
                                buttonColor = Colors.green[700]!; // Success color
                              });
                              _showStyledSnackBar(
                                'Signup successful! Please login',
                                icon: Icons.check_circle_outline,
                                isError: false,
                              );
                              box.write('isLoggedIn', true);
                              // Revert button color after 1 second
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted) {
                                  setState(() {
                                    buttonColor = primaryColor;
                                  });
                                }
                              });
                              Future.delayed(const Duration(milliseconds: 800), () {
                                setState(() {
                                  isLogin = true;
                                });
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor, // Dynamic button color
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isLogin ? 'Login' : 'Sign Up',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _toggleMode,
                        child: Text(
                          isLogin ? "Don't have an account? Sign up" : "Already have an account? Login",
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}

