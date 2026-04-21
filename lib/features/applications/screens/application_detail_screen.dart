import 'package:flutter/material.dart';
import 'package:mukamal_pakistan_admin/features/applications/wdgets/application_tile.dart';


class ApplicationDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ApplicationDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final service = ApplicationService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F6F3C),
        title: const Text("Application Detail"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            /// LEFT: Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row("User ID", data['user_id']),
                  _row("Post", data['post']),
                  _row("Status", data['status']),
                ],
              ),
            ),

            const SizedBox(width: 30),

            /// RIGHT: Documents
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Documents",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      _openUrl(data['documents']['id_card']);
                    },
                    child: const Text("View ID Card"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _openUrl(data['documents']['certificate']);
                    },
                    child: const Text("View Certificate"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// ACTION BUTTONS
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () async {
                  await service.approveApplication(
                      docId, data['user_id']);
                  Navigator.pop(context);
                },
                child: const Text("Approve"),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await service.rejectApplication(
                      docId, data['user_id']);
                  Navigator.pop(context);
                },
                child: const Text("Reject"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openUrl(String? url) {
    if (url != null) {
      // open in browser (use url_launcher later)
    }
  }
}