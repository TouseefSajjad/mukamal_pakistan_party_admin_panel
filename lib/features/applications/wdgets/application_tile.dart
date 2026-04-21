import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getApplications() {
    return _firestore
        .collection('membership_applications')
        .orderBy('submitted_at', descending: true)
        .snapshots();
  }

  Future<void> approveApplication(String docId, String userId) async {
    await _firestore.collection('membership_applications').doc(docId).update({
      'status': 'approved',
      'reviewed_at': Timestamp.now(),
    });

    await _firestore.collection('users').doc(userId).update({
      'membership_status': 'approved',
    });
  }

  Future<void> rejectApplication(String docId, String userId) async {
    await _firestore.collection('membership_applications').doc(docId).update({
      'status': 'rejected',
      'reviewed_at': Timestamp.now(),
    });

    await _firestore.collection('users').doc(userId).update({
      'membership_status': 'rejected',
    });
  }
}