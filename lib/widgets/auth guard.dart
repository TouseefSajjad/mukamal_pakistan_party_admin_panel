import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../screens/LOGIN.dart';

/// Wraps a protected screen so it can never render without a signed-in
/// Firebase Auth user — even if someone pastes a direct URL to that
/// route (e.g. yourapp.web.app/#/users) into a browser that never went
/// through the login screen.
///
/// Usage in main.dart:
///   AppRoutes.users: (_) => const AuthGuard(child: UsersScreen()),
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking whether a session exists — show a blank loader,
        // never the protected screen, while we wait to find out.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // No signed-in user — show the login screen instead of the
        // protected content, regardless of what URL was requested.
        if (snapshot.data == null) {
          return const AdminLoginScreen();
        }

        // Signed in — safe to show the actual screen.
        return child;
      },
    );
  }
}