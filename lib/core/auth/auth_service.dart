import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// LOGIN
  Future<User?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("✅ LOGIN SUCCESS: ${cred.user?.uid}");
      return cred.user;
    } on FirebaseAuthException catch (e) {
      print("❌ LOGIN ERROR: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("❌ UNKNOWN LOGIN ERROR: $e");
      rethrow;
    }
  }

  /// CHECK ADMIN
  Future<bool> isAdmin(User user) async {
    try {
      print("🔍 Checking admin for UID: ${user.uid}");

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      print("📄 Document exists: ${doc.exists}");

      if (!doc.exists) return false;

      final data = doc.data();
      print("📦 User data: $data");

      final isAdmin =
          data?['role'] == 'admin' &&
              data?['membership_status'] == 'approved' &&
              data?['active'] == true;

      print("✅ isAdmin result: $isAdmin");

      return isAdmin;
    } catch (e) {
      print("❌ ADMIN CHECK ERROR: $e");
      return false;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    print("🚪 Logging out...");
    await _auth.signOut();
  }

  /// AUTH STATE STREAM
  Stream<User?> get authState => _auth.authStateChanges();
}