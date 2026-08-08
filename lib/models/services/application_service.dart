import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mukammal_pakistan_admin/models/membership_application.dart';


class ApplicationService {
  ApplicationService._();
  static final ApplicationService instance = ApplicationService._();

  final CollectionReference _col =
  FirebaseFirestore.instance.collection('membership_applications');

  // ── List stream (filtered) ────────────────────────────────────────────────
  // NOTE: Firestore requires a composite index for (status + submitted_at).
  // Create it at: https://console.firebase.google.com → Firestore → Indexes
  Stream<List<MembershipApplication>> streamApplications({
    String filter = 'all',
  }) {
    Query query = _col.orderBy('submitted_at', descending: true);
    if (filter != 'all') {
      query = query.where('status', isEqualTo: filter);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(MembershipApplication.fromDoc).toList(),
    );
  }

  // ── Stats stream (counts per status) ─────────────────────────────────────
  Stream<Map<String, int>> streamCounts() {
    return _col.snapshots().map((snap) {
      int pending = 0, approved = 0, rejected = 0;
      for (final doc in snap.docs) {
        final raw = Map<String, dynamic>.from(doc.data() as Map);
        final status = (raw['status'] as String?) ?? 'pending';
        if (status == 'approved') {
          approved++;
        } else if (status == 'rejected') {
          rejected++;
        } else {
          pending++;
        }
      }
      return {
        'total': snap.docs.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
      };
    });
  }

  // ── Single application stream ─────────────────────────────────────────────
  Stream<MembershipApplication> streamApplication(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((doc) => MembershipApplication.fromDoc(doc));
  }

  // ── Review action (batch-updates app + user) ──────────────────────────────
  // `post` is optional — pass it when the admin also wants to allot a party
  // post (chairman, president, member, etc.) at the moment of approval.
  Future<void> reviewApplication({
    required String applicationId,
    required String userId,
    required String status, // 'approved' | 'rejected' | 'pending'
    required String adminId,
    String? post,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final appUpdate = <String, dynamic>{
      'status': status,
      'reviewed_at': FieldValue.serverTimestamp(),
      'reviewed_by': adminId,
    };
    if (post != null) {
      appUpdate['assigned_post'] = post;
    }
    batch.update(_col.doc(applicationId), appUpdate);

    if (userId.isNotEmpty) {
      final userUpdate = <String, dynamic>{'membership_status': status};
      if (post != null) {
        userUpdate['post'] = post;
      }
      // set + merge instead of update: update() throws if the user doc
      // doesn't exist yet, which would fail the whole batch.
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(userId),
        userUpdate,
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  // ── Assign / change post without touching approval status ────────────────
  Future<void> assignPost({
    required String applicationId,
    required String userId,
    required String post,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(applicationId), {'assigned_post': post});

    if (userId.isNotEmpty) {
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(userId),
        {'post': post},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}