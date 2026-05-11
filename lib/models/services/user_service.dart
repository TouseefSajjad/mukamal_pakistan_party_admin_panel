import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mukammal_pakistan_admin/models/app_user.dart';


class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final CollectionReference _col =
  FirebaseFirestore.instance.collection('users');

  /// Stream all users ordered by join date
  Stream<List<AppUser>> streamUsers() {
    return _col.orderBy('joined_at', descending: true).snapshots().map(
          (snap) => snap.docs.map(AppUser.fromDoc).toList(),
    );
  }

  /// Permanently delete user document from Firestore
  Future<void> deleteUser(String uid) async {
    await _col.doc(uid).delete();
  }

  /// Toggle blocked status
  Future<void> setBlocked(String uid, {required bool blocked}) async {
    await _col.doc(uid).update({'blocked': blocked});
  }

  /// Change role: member | moderator | admin
  Future<void> changeRole(String uid, String role) async {
    await _col.doc(uid).update({'role': role});
  }
}