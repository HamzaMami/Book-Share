// mami hamza
// ignore_for_file: deprecated_member_use

import 'package:bookshare/components/default_button.dart';
import 'package:bookshare/components/default_form_field.dart';
import 'package:bookshare/services/role_management_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RoleManagementService _roleService = RoleManagementService();
  bool _isLoading = false;
  String emailValue = "";
  String passwordValue = "";
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (userCredential.user != null) {
        await _roleService.updateLastSignIn(userCredential.user!.uid);

        final userData = await _roleService.getUserById(userCredential.user!.uid);
        if (userData != null && !userData.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been deactivated. Please contact support.'),
            ),
          );
          await _auth.signOut();
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: SingleChildScrollView(
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
                  onChange: (value) => setState(() => emailValue = value),
                  controller: _emailController,
                  type: TextInputType.emailAddress,
                  label: 'Email',
                  validate: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email.';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  prefix: const Icon(Icons.email_outlined, size: 20),
                ),

                const SizedBox(height: 20),

                DefaultFormField(
                  label: "Password",
                  type: TextInputType.visiblePassword,
                  controller: _passwordController,
                  isPassword: true,
                  validate: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password.';
                    if (value.length < 8) return 'Please enter a password of at least 8 characters.';
                    return null;
                  },
                  suffix: true,
                  prefix: const Icon(Icons.lock_outline, size: 20),
                  onChange: (value) => setState(() => passwordValue = value),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DefaultButton(
                    text: "Sign In",
                    pressed: _handleSignIn,
                    activated: emailValue.isNotEmpty && passwordValue.isNotEmpty && !_isLoading,
                    loading: _isLoading,
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/signup'),
                  child: const Text(
                    'No account? Create one!',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}