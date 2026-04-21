import 'package:flutter/material.dart';

class Topbar extends StatelessWidget {
  final String title;

  const Topbar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 60,
      color: primaryColor, // ✅ Theme color
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),

          /// Avatar
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 10),

          const Text(
            "Admin",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}