// mami hamza
// ignore_for_file: deprecated_member_use

import 'package:bookshare/views/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookshare/services/database_service.dart';
import 'package:bookshare/components/default_button.dart';
import 'package:bookshare/components/default_form_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String firstNameValue = "";
  String lastNameValue = "";
  String emailValue = "";
  String passwordValue = "";

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName('$firstName $lastName');
        await _databaseService.saveUserData(
          user.uid,
          firstName,
          lastName,
          email,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Sign up failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Please choose a stronger password.';
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

   @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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

                    Row(
                      children: [
                        Expanded(
                          child: DefaultFormField(
                            controller: _firstNameController,
                            type: TextInputType.name,
                            label: 'First Name',
                            prefix: const Icon(Icons.person_outline, size: 20),
                            validate: (value) {
                              if (value == null || value.isEmpty) {
                                return 'First name is required.';
                              }
                              return null;
                            },
                            onChange: (value) {
                              setState(() {
                                firstNameValue = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DefaultFormField(
                            controller: _lastNameController,
                            type: TextInputType.name,
                            label: 'Last Name',
                            prefix: const Icon(Icons.person_outline, size: 20),
                            validate: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Last name is required.';
                              }
                              return null;
                            },
                            onChange: (value) {
                              setState(() {
                                lastNameValue = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    DefaultFormField(
                      controller: _emailController,
                      type: TextInputType.emailAddress,
                      label: 'Email',
                      prefix: const Icon(Icons.email_outlined, size: 20),
                      validate: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                      onChange: (value) {
                        setState(() {
                          emailValue = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    DefaultFormField(
                      controller: _passwordController,
                      type: TextInputType.visiblePassword,
                      label: 'Password',
                      isPassword: true,
                      suffix: true,
                      prefix: const Icon(Icons.lock_outline, size: 20),
                      validate: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        if (value.length < 8) {
                          return 'Please enter a password of at least 8 characters.';
                        }
                        return null;
                      },
                      onChange: (value) {
                        setState(() {
                          passwordValue = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DefaultButton(
                        text: 'Create Account',
                        pressed: _handleSignUp,
                        activated: firstNameValue.isNotEmpty &&
                            lastNameValue.isNotEmpty &&
                            emailValue.isNotEmpty &&
                            passwordValue.isNotEmpty &&
                            !_isLoading,
                        loading: _isLoading,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignInScreen()));
                      },
                      child: const Text(
                        'Already have an account? Sign in!',
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
