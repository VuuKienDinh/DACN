class AuthUser {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String gender;
  final String birthDate;
  final String bio;
  final String avatarUrl;
  final bool isLocalAccount;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.phoneNumber = '',
    this.address = '',
    this.gender = '',
    this.birthDate = '',
    this.bio = '',
    this.avatarUrl = '',
    this.isLocalAccount = false,
  });

  AuthUser copyWith({
    int? id,
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    String? address,
    String? gender,
    String? birthDate,
    String? bio,
    String? avatarUrl,
    bool? isLocalAccount,
  }) {
    return AuthUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLocalAccount: isLocalAccount ?? this.isLocalAccount,
    );
  }

  factory AuthUser.fromJson(
    Map<String, dynamic> json, {
    bool? isLocalOverride,
  }) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['fullName'] ?? '').toString().trim(),
      username: (json['username'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString().trim(),
      phoneNumber: (json['phoneNumber'] ?? '').toString().trim(),
      address: (json['address'] ?? '').toString().trim(),
      gender: (json['gender'] ?? '').toString().trim(),
      birthDate: (json['birthDate'] ?? '').toString().trim(),
      bio: (json['bio'] ?? '').toString().trim(),
      avatarUrl: (json['avatarUrl'] ?? '').toString().trim(),
      isLocalAccount: isLocalOverride ?? (json['isLocalAccount'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'gender': gender,
      'birthDate': birthDate,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'isLocalAccount': isLocalAccount,
    };
  }
}
