import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String membershipStatus;
  final bool isOnline;
  final bool blocked;
  final DateTime? joinedAt;
  final DateTime? lastSeen;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.membershipStatus,
    required this.isOnline,
    required this.blocked,
    this.joinedAt,
    this.lastSeen,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    // SAFE web conversion — never cast directly
    final raw = Map<String, dynamic>.from(doc.data() as Map);

    DateTime? parseTs(String key) {
      final v = raw[key];
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return AppUser(
      uid: (raw['uid'] as String?) ?? doc.id,
      email: (raw['email'] as String?) ?? '',
      name: (raw['name'] as String?) ?? '',
      phone: (raw['phone'] as String?) ?? '',
      role: (raw['role'] as String?) ?? 'member',
      membershipStatus: (raw['membership_status'] as String?) ?? 'pending',
      isOnline: (raw['isOnline'] as bool?) ?? false,
      blocked: (raw['blocked'] as bool?) ?? false,
      joinedAt: parseTs('joined_at'),
      lastSeen: parseTs('lastSeen'),
    );
  }
}