import 'package:cloud_firestore/cloud_firestore.dart';

String? _str(dynamic v) => v is String ? v : null;

class ContactInfo {
  final String address;
  final String city;
  final String email;
  final String phone;

  const ContactInfo({
    required this.address,
    required this.city,
    required this.email,
    required this.phone,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> m) {
    return ContactInfo(
      address: (m['address'] as String?) ?? '',
      city: (m['city'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      phone: (m['phone'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'email': email,
      'phone': phone,
    };
  }
}

class AppDocuments {
  final List<String> cnicImages;
  final String educationCertificate;
  final String profileImage;
  final List<String> otherDocuments;

  const AppDocuments({
    required this.cnicImages,
    required this.educationCertificate,
    required this.profileImage,
    required this.otherDocuments,
  });

  factory AppDocuments.fromMap(Map<String, dynamic> m) {
    final cnicRaw = m['cnic_images'];
    final List<String> cnicImages =
    cnicRaw is List ? cnicRaw.whereType<String>().toList() : <String>[];

    final String educationCertificate =
        (m['education_certificate'] as String?) ?? '';

    final String profileImage = (m['profile_image'] as String?) ?? '';

    final otherRaw = m['other_documents'];
    final List<String> otherDocuments = otherRaw is List
        ? otherRaw.whereType<String>().where((e) => e.isNotEmpty).toList()
        : <String>[];

    return AppDocuments(
      cnicImages: cnicImages,
      educationCertificate: educationCertificate,
      profileImage: profileImage,
      otherDocuments: otherDocuments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cnic_images': cnicImages,
      'education_certificate': educationCertificate,
      'profile_image': profileImage,
      'other_documents': otherDocuments,
    };
  }
}

class EducationInfo {
  final String educationLevel;
  final String institution;
  final String profession;
  final String selectedRole;
  final String yearOfCompletion;

  const EducationInfo({
    required this.educationLevel,
    required this.institution,
    required this.profession,
    required this.selectedRole,
    required this.yearOfCompletion,
  });

  factory EducationInfo.fromMap(Map<String, dynamic> m) {
    return EducationInfo(
      educationLevel: (m['education_level'] as String?) ?? '',
      institution: (m['institution'] as String?) ?? '',
      profession: (m['profession'] as String?) ?? '',
      selectedRole: (m['selected_role'] as String?) ?? 'member',
      yearOfCompletion: (m['year_of_completion'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'education_level': educationLevel,
      'institution': institution,
      'profession': profession,
      'selected_role': selectedRole,
      'year_of_completion': yearOfCompletion,
    };
  }
}

class PersonalInfo {
  final String cnic;
  final DateTime? dateOfBirth;
  final String fatherName;
  final String fullName;
  final String gender;

  const PersonalInfo({
    required this.cnic,
    this.dateOfBirth,
    required this.fatherName,
    required this.fullName,
    required this.gender,
  });

  factory PersonalInfo.fromMap(Map<String, dynamic> m) {
    DateTime? dob;
    final rawDob = m['date_of_birth'];
    if (rawDob is Timestamp) {
      dob = rawDob.toDate();
    }

    return PersonalInfo(
      cnic: (m['cnic'] as String?) ?? '',
      dateOfBirth: dob,
      fatherName: (m['father_name'] as String?) ?? '',
      fullName: (m['full_name'] as String?) ?? '',
      gender: (m['gender'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cnic': cnic,
      'date_of_birth': dateOfBirth,
      'father_name': fatherName,
      'full_name': fullName,
      'gender': gender,
    };
  }
}

class MembershipApplication {
  final String id;

  final ContactInfo contactInfo;
  final AppDocuments documents;
  final EducationInfo educationInfo;
  final PersonalInfo personalInfo;

  final DateTime? reviewedAt;
  final String? reviewedBy;

  final String status;
  final DateTime submittedAt;
  final String userId;

  /// Party post allotted to this member by an admin (e.g. "chairman",
  /// "general_secretary", "member" ...). Null until an admin sets it.
  final String? assignedPost;

  const MembershipApplication({
    required this.id,
    required this.contactInfo,
    required this.documents,
    required this.educationInfo,
    required this.personalInfo,
    this.reviewedAt,
    this.reviewedBy,
    required this.status,
    required this.submittedAt,
    required this.userId,
    this.assignedPost,
  });

  factory MembershipApplication.fromDoc(DocumentSnapshot doc) {
    final raw = Map<String, dynamic>.from(
      doc.data() as Map<String, dynamic>,
    );

    Map<String, dynamic> nested(String key) {
      final value = raw[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return <String, dynamic>{};
    }

    // ── personal_info, with fallback to legacy flat fields ─────────────
    var personalMap = nested('personal_info');
    if (personalMap.isEmpty) {
      personalMap = {
        'full_name': _str(raw['full_name']) ?? _str(raw['name']) ?? '',
        'cnic': _str(raw['cnic']) ?? '',
        'father_name': _str(raw['father_name']) ?? '',
        'gender': _str(raw['gender']) ?? '',
        'date_of_birth': raw['date_of_birth'],
      };
    }

    // ── contact_info, with fallback to legacy flat fields ──────────────
    var contactMap = nested('contact_info');
    if (contactMap.isEmpty) {
      contactMap = {
        'address': _str(raw['address']) ?? '',
        'city': _str(raw['city']) ?? _str(raw['district']) ?? '',
        'email': _str(raw['email']) ?? '',
        'phone': _str(raw['phone']) ?? '',
      };
    }

    // ── education_info (no legacy flat equivalent — stays empty if absent)
    final educationMap = nested('education_info');

    // ── documents, with fallback to legacy flat fields ─────────────────
    var documentsMap = nested('documents');
    if (documentsMap.isEmpty) {
      documentsMap = {
        'profile_image':
        _str(raw['profile_image']) ?? _str(raw['profile_picture']) ?? '',
        'cnic_images': raw['cnic_images'] ?? <String>[],
        'education_certificate': _str(raw['education_certificate']) ?? '',
        'other_documents': raw['other_documents'] ?? <String>[],
      };
    }

    // ── Reviewed At ──────────────────────────────────────────────────
    DateTime? reviewedAt;
    final reviewedRaw = raw['reviewed_at'];
    if (reviewedRaw is Timestamp) {
      reviewedAt = reviewedRaw.toDate();
    }

    // ── Submitted At ─────────────────────────────────────────────────
    DateTime submittedAt = DateTime.now();
    final submittedRaw = raw['submitted_at'];
    if (submittedRaw is Timestamp) {
      submittedAt = submittedRaw.toDate();
    }

    return MembershipApplication(
      id: doc.id,
      contactInfo: ContactInfo.fromMap(contactMap),
      documents: AppDocuments.fromMap(documentsMap),
      educationInfo: EducationInfo.fromMap(educationMap),
      personalInfo: PersonalInfo.fromMap(personalMap),
      reviewedAt: reviewedAt,
      reviewedBy: raw['reviewed_by'] as String?,
      status: (raw['status'] as String?) ?? 'pending',
      submittedAt: submittedAt,
      userId: (raw['user_id'] as String?) ?? '',
      assignedPost: raw['assigned_post'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contact_info': contactInfo.toMap(),
      'documents': documents.toMap(),
      'education_info': educationInfo.toMap(),
      'personal_info': personalInfo.toMap(),
      'reviewed_at': reviewedAt,
      'reviewed_by': reviewedBy,
      'status': status,
      'submitted_at': submittedAt,
      'user_id': userId,
      'assigned_post': assignedPost,
    };
  }
}

/// Fixed list of party posts an admin can allot to an approved member.
/// Edit freely — it drives the dropdown in the detail screen.
const List<String> kAvailablePosts = [
  'chairman',
  'general_secretary',
  'president',
  'president_of_uc',
  'vice_chairman',
  'vice_president',
  'vice_president_of_uc',
  'member',
];

String formatPostLabel(String post) {
  return post
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}