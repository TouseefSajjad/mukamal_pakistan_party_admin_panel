import 'package:flutter/material.dart';
import 'package:mukamal_pakistan_admin/core/auth/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Settings",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () async {
            await auth.logout();
          },
          child: const Text("Logout"),
        )
      ],
    );
  }
}