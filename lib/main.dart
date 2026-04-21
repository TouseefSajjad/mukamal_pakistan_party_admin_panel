import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mukamal_pakistan_admin/dashboard/dashboard_screen.dart';
import 'package:mukamal_pakistan_admin/features/alerts/screens/alerts_screen.dart';
import 'package:mukamal_pakistan_admin/layout/admin_scaffold.dart';
import 'firebase_options.dart';
import 'package:mukamal_pakistan_admin/core/guards/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminScaffold(),
    );
  }
}