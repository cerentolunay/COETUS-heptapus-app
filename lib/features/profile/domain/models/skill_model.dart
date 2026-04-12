class SkillModel {
  final String id;
  final String name;
  final int level;

  const SkillModel({
    required this.id,
    required this.name,
    required this.level,
  });

  SkillModel copyWith({
    String? id,
    String? name,
    int? level,
  }) {
    return SkillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
    };
  }

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      level: map['level'] as int? ?? 0,
    );
  }
}
