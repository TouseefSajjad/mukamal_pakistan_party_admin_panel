import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mukamal_pakistan_admin/features/applications/screens/application_detail_screen.dart';

class ApplicationsListScreen extends StatelessWidget {
  const ApplicationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseFirestore.instance.collection('applications');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Applications",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: service.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final apps = snapshot.data!.docs;

              return ListView.builder(
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final doc = apps[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(data['post'] ?? 'No Post'),
                      subtitle: Text("Status: ${data['status']}"),
                      trailing: const Icon(Icons.arrow_forward),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplicationDetailScreen(
                              docId: doc.id,
                              data: data,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}