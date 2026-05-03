class AppUser {
  final String id;
  final String name;
  final String email;
  final String bio;
  final String? location;
  final String? photoUrl;
  final int trustScore;
  final int credits;
  final bool verified;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    this.location,
    this.photoUrl,
    this.trustScore = 0,
    this.credits = 0,
    this.verified = false,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    String? location,
    String? photoUrl,
    int? trustScore,
    int? credits,
    bool? verified,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      trustScore: trustScore ?? this.trustScore,
      credits: credits ?? this.credits,
      verified: verified ?? this.verified,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'name': name,
      'displayName': name,
      'email': email,
      'bio': bio,
      'trustScore': trustScore,
      'credits': credits,
      'verified': verified,
    };

    if (location != null) {
      map['location'] = location;
    }

    if (photoUrl != null) {
      map['photoUrl'] = photoUrl;
    }

    return map;
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      name: map['displayName'] as String? ?? map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      location: map['location'] as String?,
      photoUrl: map['photoUrl'] as String?,
      trustScore: map['trustScore'] as int? ?? 0,
      credits: map['credits'] as int? ?? 0,
      verified: map['verified'] as bool? ?? false,
    );
  }
}
