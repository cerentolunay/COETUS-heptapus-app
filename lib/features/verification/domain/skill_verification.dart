import 'package:cloud_firestore/cloud_firestore.dart';

class SkillVerification {
  const SkillVerification({
    required this.id,
    required this.ownerId,
    required this.skillName,
    required this.status,
    required this.type,
    required this.description,
    this.ownerName = '',
    this.studentName = '',
    this.reason = '',
    this.reward = 0,
    this.files = const [],
  });
  final String id,
      ownerId,
      skillName,
      status,
      type,
      description,
      ownerName,
      studentName,
      reason;
  final int reward;
  final List<Map<String, dynamic>> files;
  String get statusLabel => switch (status) {
    'approved' =>
      type == 'peer' ? 'Eşleştiği kişiden onay' : 'Eski çalışma kaydı',
    'published' => 'Çalışma örneği paylaşıldı',
    'deleted' => 'Kaldırıldı',
    'rejected' => 'Yeniden kanıt gerekli',
    _ => 'Eski başvuru · Manuel inceleme kaldırıldı',
  };
  factory SkillVerification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return SkillVerification(
      id: doc.id,
      ownerId: d['ownerId'] as String? ?? '',
      skillName: d['skillName'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      type: d['type'] as String? ?? 'media',
      description: d['description'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? '',
      studentName: d['studentName'] as String? ?? '',
      reason: d['reason'] as String? ?? '',
      reward: (d['reward'] as num?)?.toInt() ?? 0,
      files: (d['files'] as List? ?? [])
          .map((f) => Map<String, dynamic>.from(f as Map))
          .toList(),
    );
  }
}
