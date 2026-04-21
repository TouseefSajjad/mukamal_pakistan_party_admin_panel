import 'package:cloud_firestore/cloud_firestore.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getAlerts() {
    return _firestore
        .collection('alerts')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> createAlert({
    required String title,
    required String message,
    required List<String> visibleTo, required String adminId,
  }) async {
    await _firestore.collection('alerts').add({
      'title': title,
      'message': message,
      'visible_to': visibleTo,
      'active': true,
      'created_at': Timestamp.now(),
      'created_by': 'admin',
    });
  }

  Future<void> toggleAlert(String id, bool status) async {
    await _firestore.collection('alerts').doc(id).update({
      'active': status,
    });
  }

  Future<void> deleteAlert(String id) async {
    await _firestore.collection('alerts').doc(id).delete();
  }
}