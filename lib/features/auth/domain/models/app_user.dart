class AppUser {
  final String id;
  final String name;
  final String email;
  final String bio;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
    );
  }
}
