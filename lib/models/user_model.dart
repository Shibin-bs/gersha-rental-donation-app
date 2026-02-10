/// User model to store user information in Firestore
///
/// Firestore-backed fields relevant for routing/onboarding:
/// - role: "admin" | "user"            (defaults to "user")
/// - verificationStatus: "pending" | "verified" | "rejected" (defaults to "pending")
/// - agreementAccepted: true | false   (defaults to false)
/// - kycRequired: true | false         (defaults to true)
class UserModel {
  final String uid; // Firebase Auth UID
  final String? name;
  final String? email;
  final String? phone; // Phone number (alternative to email)
  final UserRole role; // 'user' or 'admin'
  final String address; // Initially empty, can be updated later
  final VerificationStatus verificationStatus; // 'pending', 'verified', 'rejected'
  final String? verificationDocumentType; // 'aadhaar', 'driving_license', 'passport'
  final String? verificationDocumentNumber; // Masked (last few digits only)
  final bool agreementAccepted; // Digital agreement acceptance
  /// Whether this user is required to complete KYC before using the app.
  ///
  /// Defaults to true when the field is missing (older users).
  final bool kycRequired;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    this.name,
    this.email,
    this.phone,
    this.role = UserRole.user,
    this.address = '',
    this.verificationStatus = VerificationStatus.pending,
    this.verificationDocumentType,
    this.verificationDocumentNumber,
    this.agreementAccepted = false,
    this.kycRequired = true,
    required this.createdAt,
  });

  /// Convert UserModel to Map for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last, // 'user' or 'admin'
      'address': address,
      'verificationStatus': verificationStatus.toString().split('.').last,
      'verificationDocumentType': verificationDocumentType,
      'verificationDocumentNumber': verificationDocumentNumber,
      'agreementAccepted': agreementAccepted,
      'kycRequired': kycRequired,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      uid: json['uid'] as String? ?? documentId,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == (json['role'] as String? ?? 'user'),
        orElse: () => UserRole.user,
      ),
      address: json['address'] as String? ?? '',
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['verificationStatus'] as String? ?? 'pending'),
        orElse: () => VerificationStatus.pending,
      ),
      verificationDocumentType: json['verificationDocumentType'] as String?,
      verificationDocumentNumber: json['verificationDocumentNumber'] as String?,
      agreementAccepted: json['agreementAccepted'] as bool? ?? false,
      // Default to true when the field is absent (older user documents)
      kycRequired: json['kycRequired'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? address,
    VerificationStatus? verificationStatus,
    String? verificationDocumentType,
    String? verificationDocumentNumber,
    bool? agreementAccepted,
    bool? kycRequired,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationDocumentType: verificationDocumentType ?? this.verificationDocumentType,
      verificationDocumentNumber: verificationDocumentNumber ?? this.verificationDocumentNumber,
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
      kycRequired: kycRequired ?? this.kycRequired,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if user is verified (verification completed and agreement accepted)
  bool get isVerified => 
      verificationStatus == VerificationStatus.verified && agreementAccepted;
}

/// User roles enum
enum UserRole {
  user, // Normal user
  admin, // Admin user
}

/// Verification status enum
enum VerificationStatus {
  pending, // Not yet verified
  verified, // Verification completed
  rejected, // Verification rejected
}
