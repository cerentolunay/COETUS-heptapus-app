class SkillModel {
  final String id;
  final String name;
  final int level;
  final int peerApprovalCount;
  final String category;
  final bool teachable;
  final bool learnable;
  final String? verifiedName;
  final int? verifiedLevel;
  bool get verified => verifiedName == name && verifiedLevel == level;

  const SkillModel({
    required this.id,
    required this.name,
    required this.level,
    this.peerApprovalCount = 0,
    this.category = '',
    this.teachable = false,
    this.learnable = false,
    this.verifiedName,
    this.verifiedLevel,
  });

  SkillModel copyWith({
    String? id,
    String? name,
    int? level,
    String? category,
    bool? teachable,
    bool? learnable,
  }) {
    return SkillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      category: category ?? this.category,
      teachable: teachable ?? this.teachable,
      learnable: learnable ?? this.learnable,
      peerApprovalCount: peerApprovalCount,
      verifiedName: verifiedName,
      verifiedLevel: verifiedLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'category': category,
      'teachable': teachable,
      'learnable': learnable,
    };
  }

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      level: map['level'] as int? ?? 0,
      category: map['category'] as String? ?? '',
      teachable: map['teachable'] as bool? ?? false,
      learnable: map['learnable'] as bool? ?? false,
      peerApprovalCount: (map['peerApprovalCount'] as num?)?.toInt() ?? 0,
      verifiedName: map['verifiedName'] as String?,
      verifiedLevel: (map['verifiedLevel'] as num?)?.toInt(),
    );
  }
}
