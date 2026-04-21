import 'package:cloud_firestore/cloud_firestore.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMembers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> updateStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update({
      'membership_status': status,
    });
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}