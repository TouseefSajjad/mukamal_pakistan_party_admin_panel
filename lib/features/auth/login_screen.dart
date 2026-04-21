import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mukamal_pakistan_admin/core/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final AuthService auth = AuthService();

  bool loading = false;

  /// LOGIN FUNCTION
  void login() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      final user = await auth.login(
        emailC.text.trim(),
        passC.text.trim(),
      );

      print("👤 Login returned: ${user?.uid}");

      if (user == null) {
        showError("Invalid credentials");
      }

      // 🚫 NO NAVIGATION HERE
      // AuthGate handles routing automatically

    } on FirebaseAuthException catch (e) {
      showError(e.message ?? "Login failed");
    } catch (e) {
      showError(e.toString());
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  /// ERROR SNACKBAR
  void showError(String msg) {
    print("❌ UI ERROR: $msg");

    if (mounted) {
      setState(() => loading = false);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Mukammal Pakistan Party Admin",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F6F3C),
                ),
              ),

              const SizedBox(height: 20),

              /// EMAIL
              TextField(
                controller: emailC,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              /// PASSWORD
              TextField(
                controller: passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6F3C),
                  ),
                  child: loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text("Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}