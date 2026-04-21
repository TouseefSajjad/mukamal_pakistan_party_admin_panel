import 'package:flutter/material.dart';
import 'package:mukamal_pakistan_admin/features/members/widgets/member_table.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Members Management",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

        const SizedBox(height: 20),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const MemberTable(),
          ),
        ),
      ],
    );
  }
}