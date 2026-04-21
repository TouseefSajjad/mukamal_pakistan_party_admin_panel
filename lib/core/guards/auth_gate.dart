import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mukamal_pakistan_admin/core/auth/auth_service.dart';
import 'package:mukamal_pakistan_admin/dashboard/dashboard_screen.dart';
import 'package:mukamal_pakistan_admin/features/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final AuthService auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authState,
      builder: (context, snapshot) {
        print("🔄 AuthState: ${snapshot.connectionState}");
        print("👤 User: ${snapshot.data?.uid}");

        /// 🔥 LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        /// ❌ NOT LOGGED IN
        if (user == null) {
          return const LoginScreen();
        }

        /// 🔍 CHECK ADMIN
        return FutureBuilder<bool>(
          future: auth.isAdmin(user),
          builder: (context, adminSnap) {
            print("⏳ Admin check state: ${adminSnap.connectionState}");

            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (adminSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text("Error: ${adminSnap.error}"),
                ),
              );
            }

            final isAdmin = adminSnap.data ?? false;

            /// ❌ NOT ADMIN
            if (!isAdmin) {
              print("🚫 Not admin → blocking access");

              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Access Denied",
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => auth.logout(),
                        child: const Text("Logout"),
                      )
                    ],
                  ),
                ),
              );
            }

            /// ✅ ADMIN → DASHBOARD
            print("🎉 Admin verified → Dashboard");

            return const DashboardScreen();
          },
        );
      },
    );
  }
}