import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Total Members (approved users)
  Future<int> getTotalMembers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('membership_status', isEqualTo: 'approved')
        .get();
    return snapshot.docs.length;
  }

  /// Pending Applications
  Future<int> getPendingApplications() async {
    final snapshot = await _firestore
        .collection('membership_applications')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  /// Approved Today
  Future<int> getApprovedToday() async {
    final today      = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('membership_applications')
        .where('status', isEqualTo: 'approved')
        .where('reviewed_at', isGreaterThanOrEqualTo: startOfDay)
        .get();
    return snapshot.docs.length;
  }

  /// Active Chats (simple count)
  Future<int> getActiveChats() async {
    final snapshot = await _firestore.collection('chats').get();
    return snapshot.docs.length;
  }
}