import '../../../../core/text/skill_normalization.dart';
import '../models/skill_model.dart';

class InterestBranch {
  const InterestBranch(this.id, this.label, this.skills);
  final String id, label;
  final List<String> skills;
}

const interestBranches = [
  InterestBranch('music', 'Müzik', [
    'Gitar',
    'Piyano',
    'Şarkı sözü yazarlığı',
    'Beat yapımı',
    'Şan',
    'Davul',
    'Keman',
  ]),
  InterestBranch('software', 'Yazılım', [
    'Python',
    'JavaScript',
    'Flutter',
    'Web geliştirme',
    'C++',
    'C#',
    'Veri analizi',
    'Oyun geliştirme',
  ]),
  InterestBranch('anime', 'Anime', [
    'Anime çizimi',
    'Manga çizimi',
    'Karakter tasarımı',
    'Japonca',
    'Animasyon',
  ]),
  InterestBranch('books', 'Kitap', [
    'Yaratıcı yazarlık',
    'Şiir',
    'Edebiyat',
    'Kitap analizi',
    'Hikâye anlatıcılığı',
  ]),
  InterestBranch('film', 'Dizi ve sinema', [
    'Senaryo yazarlığı',
    'Film analizi',
    'Video kurgu',
    'Oyunculuk',
    'Fotoğrafçılık',
  ]),
  InterestBranch('psychology', 'Psikoloji', [
    'Psikolojiye giriş',
    'İletişim becerileri',
    'Sosyal psikoloji',
    'Araştırma yöntemleri',
  ]),
  InterestBranch('design', 'Sanat ve tasarım', [
    'Dijital çizim',
    'Grafik tasarım',
    'UI/UX tasarımı',
    'Resim',
    'Seramik',
  ]),
  InterestBranch('languages', 'Diller', [
    'İngilizce',
    'Almanca',
    'İspanyolca',
    'Fransızca',
    'Japonca',
    'Türkçe',
  ]),
  InterestBranch('movement', 'Spor ve hareket', [
    'Satranç',
    'Dans',
    'Yoga',
    'Koşu',
    'Fitness',
  ]),
  InterestBranch('kitchen', 'Gastronomi ve yemek yapımı', [
    'Yemek yapımı',
    'Pastacılık',
    'Kahve demleme',
    'Ekmek yapımı',
  ]),
  InterestBranch('crafts', 'El sanatları', [
    'Örgü',
    'Nakış',
    'Takı tasarımı',
    'Origami',
  ]),
  InterestBranch('photography', 'Fotoğrafçılık', [
    'Portre fotoğrafçılığı',
    'Doğa fotoğrafçılığı',
    'Fotoğraf düzenleme',
  ]),
  InterestBranch('animal_care', 'Hayvan bakımı', [
    'Kedi bakımı',
    'Köpek bakımı',
    'Akvaryum bakımı',
    'Hayvan davranışları',
  ]),
  InterestBranch('history', 'Tarih', [
    'Dünya tarihi',
    'Türkiye tarihi',
    'Sanat tarihi',
    'Mitoloji',
  ]),
  InterestBranch('strategy_games', 'Strateji oyunları', [
    'Satranç',
    'Go',
    'Masa oyunları',
    'Strateji geliştirme',
  ]),
  InterestBranch('video_games', 'Bilgisayar oyunları', [
    'Oyun analizi',
    'Takım oyunları',
    'E-spor',
    'Oyun tasarımı',
  ]),
  InterestBranch('travel', 'Seyahat', [
    'Gezi planlama',
    'Rota oluşturma',
    'Kültür keşfi',
    'Seyahat fotoğrafçılığı',
  ]),
  InterestBranch('nature', 'Doğa', [
    'Doğa gözlemi',
    'Kuş gözlemciliği',
    'Ekoloji',
    'Doğa yürüyüşü',
  ]),
  InterestBranch('camping', 'Kamp', [
    'Çadır kurma',
    'Kamp planlama',
    'Doğada yön bulma',
    'Kamp yemekleri',
  ]),
  InterestBranch('gardening', 'Bahçecilik', [
    'Bitki bakımı',
    'Sebze yetiştirme',
    'Kompost',
    'Balkon bahçeciliği',
  ]),
  InterestBranch('diy', 'DIY ve kendin yap', [
    'Ahşap işleri',
    'Geri dönüşüm tasarımı',
    'Ev dekorasyonu',
    'Dikiş',
  ]),
  InterestBranch('content_creation', 'Dijital içerik üreticiliği', [
    'Video içerik üretimi',
    'Podcast',
    'Sosyal medya',
    'İçerik planlama',
  ]),
  InterestBranch('finance', 'Finans ve yatırım', [
    'Finansal okuryazarlık',
    'Bütçe yönetimi',
    'Yatırım araçları',
    'Risk yönetimi',
  ]),
  InterestBranch('astrology', 'Astroloji', [
    'Burçlar',
    'Doğum haritası',
    'Astroloji tarihi',
  ]),
];

class SkillChoice {
  SkillChoice(this.name, this.category);
  final String name, category;
  bool learn = true, teach = false;
  int level = 1;
  SkillModel toSkill() => SkillModel(
    id: 'skill_${Uri.encodeComponent(skillKey(name))}',
    name: name,
    category: category,
    level: level,
    teachable: teach,
    learnable: learn,
  );
}

class InterestSelection {
  final Set<String> branches = {};
  final Map<String, SkillChoice> skills = {};
  final Map<String, String> _categoryIds = {};
  void toggleBranch(String id) {
    // Collapsing a branch preserves chosen skills; no hidden loss of user input.
    branches.contains(id) ? branches.remove(id) : branches.add(id);
  }

  void toggleSkill(String name, String category, {String? branchId}) {
    if (branchId != null) _categoryIds[category] = branchId;
    final key = skillKey(name);
    skills.containsKey(key)
        ? skills.remove(key)
        : skills[key] = SkillChoice(name, category);
  }

  List<String> get selectedInterestIds => {
    ...branches,
    for (final choice in skills.values)
      if (_categoryIds.containsKey(choice.category))
        _categoryIds[choice.category]!,
    for (final branch in interestBranches)
      if (skills.values.any((s) => s.category == branch.label)) branch.id,
  }.toList();
  List<SkillModel> get selectedSkills =>
      skills.values.map((c) => c.toSkill()).toList();
}
