import 'package:demo_social_media_app/auth/login_or_register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo_social_media_app/pages/home_page.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is logged in
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            // User not logged in
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
