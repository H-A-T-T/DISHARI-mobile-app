class UserProfile {
  final int? id;
  final String fullName;
  final String phone;
  final String? email;
  final String citizenId;

  UserProfile({
    this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.citizenId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      citizenId: json['citizen_id'] ?? json['citizenId'] ?? 'BD-USER-782',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'citizen_id': citizenId,
    };
  }

  UserProfile copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? email,
    String? citizenId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      citizenId: citizenId ?? this.citizenId,
    );
  }
}

