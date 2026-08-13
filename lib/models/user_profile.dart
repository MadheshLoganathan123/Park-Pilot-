class UserProfile {
  const UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImage,
  });

  final String id;
  final String firebaseUid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profileImage;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    firebaseUid: json['firebaseUid'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    profileImage: json['profileImage'] as String?,
    role: json['role'] as String,
  );
}
