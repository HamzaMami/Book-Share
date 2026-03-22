// mami hamza
// ignore_for_file: deprecated_member_use

import 'package:bookshare/components/default_button.dart';
import 'package:bookshare/components/default_form_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookshare/views/auth/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String emailValue = "";
  String passwordValue = "";
  final _formKey = GlobalKey<FormState>();
  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signed in successfully.')));
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String message = 'Sign in failed. Please try again.';
        if (e.code == 'invalid-email') {
          message = 'Please enter a valid email address.';
        } else if (e.code == 'user-not-found') {
          message = 'No account found for this email.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Incorrect email or password.';
        } else if (e.code == 'too-many-requests') {
          message = 'Too many attempts. Please try again later.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error. Please try again.')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Image.asset('assets/book_share.png', height: 120, color: Colors.blue),
                    const SizedBox(height: 50),

                    DefaultFormField(
                      onChange: (value) {
                        setState(() {
                          emailValue = value;
                          // This will trigger a rebuild to update the button state
                        });
                      },
                      controller: _emailController,
                      type: TextInputType.emailAddress,
                      label: 'Email',
                      validate: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                      prefix: const Icon(
                        Icons.email_outlined,
                        size: 20,
                      ),
                    ),
                    // FIX: Added the Icons here
                    const SizedBox(height: 20),

                    DefaultFormField(
                      label: "Password",
                      type: TextInputType.visiblePassword,
                      controller: _passwordController,
                      isPassword: true,
                      validate: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        if (value.length < 8) {
                          return 'Please enter a password of at least 8 characters.';
                        }
                        return null;
                      },
                      suffix: true,
                      prefix: Icon(Icons.lock_outline, size: 20),
                      onChange: (value) {
                        setState(() {
                          passwordValue = value;
                          // This will trigger a rebuild to update the button state
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DefaultButton(
                        text: "Sign In",
                        pressed: _handleSignIn,
                        activated: emailValue.isNotEmpty &&
                            passwordValue.isNotEmpty &&
                            !_isLoading,
                        loading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        'No account? Create one!',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
