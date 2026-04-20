// mami hamza
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bookshare/firebase_options.dart';
import 'package:bookshare/views/auth/onboarding.dart';
import 'package:bookshare/views/auth/sign_in_screen.dart';
import 'package:bookshare/views/auth/sign_up_screen.dart';
import 'package:bookshare/views/auth/home/main_wrapper_with_roles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BookShareApp());
}

class BookShareApp extends StatelessWidget {
  const BookShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Share',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/signin': (_) => const SignInScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/home': (_) => const MainWrapperWithRoles(),
      },
    );
  }
}