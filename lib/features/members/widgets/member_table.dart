import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/member_service.dart';
import 'member_detail_dialog.dart';

class MemberTable extends StatelessWidget {
  const MemberTable({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MemberService();

    return StreamBuilder<QuerySnapshot>(
      stream: service.getMembers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!.docs;

        return SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Role")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Actions")),
            ],
            rows: members.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return DataRow(cells: [
                DataCell(Text(data['name'] ?? '')),
                DataCell(Text(data['email'] ?? '')),
                DataCell(Text(data['role'] ?? '')),
                DataCell(_statusChip(data['membership_status'])),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              MemberDetailDialog(data: data),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.block, color: Colors.orange),
                      onPressed: () {
                        service.updateStatus(doc.id, 'rejected');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        service.deleteUser(doc.id);
                      },
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _statusChip(String? status) {
    Color color;

    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status ?? ''),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}