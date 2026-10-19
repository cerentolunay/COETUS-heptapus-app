# Algoritma Teknik Uygulama Notlari

Bu dokuman, `doc/05-algoritmalar.md` dosyasindaki algoritma kararlarinin
uygulamadaki teknik karsiligini netlestirir.

## 1. Matching Uygulamasi

- Exact skill match ana eslesme kuralidir.
- Skill Graph verisi varsa related skill match opsiyonel olarak desteklenir.
- Related match skoru, graph `relationStrength` degeri ile agirliklandirilir.
- Skill seviyesi skoru `min((TeacherLevel - StudentLevel) / 5, 1)` formuluyle hesaplanir.
- `TeacherLevel - StudentLevel` degeri 2'den kucukse eslesme onerilmez.
- `TrustScore`, iki kullanicinin trust skorunun ortalamasidir ve 0-1 araligina normalize edilir.
- `AvailabilityScore`, iki kullanicinin `availabilitySlots` listelerinde ortak slot varsa 1, yoksa 0 olur.
- `ProfileCompleteness`, mevcut MVP modelinde name, bio, teachSkills, learnSkills ve verified alanlarina gore hesaplanir.

```text
MatchScore =
0.40 * SkillScore +
0.30 * TrustScore +
0.20 * AvailabilityScore +
0.10 * ProfileCompleteness
```

## 2. Match Explanation

Her match sonucu sadece toplam skor tasimaz. Algoritmanin neden bu sonucu
urettigini aciklayan bir `explanation` alani da tasir.

Explanation alanlari:

- `skillMatchType`: exact veya related
- `skillCompatibilityScore`: exact match icin 1, related match icin relationStrength
- `hasAvailabilityOverlap`: ortak availability slotu var mi
- `averageTrustScore`: iki kullanicinin normalize trust ortalamasi
- `profileCompleteness`: aday profilinin tamamlanma orani

## 3. Trust Score Uygulamasi

Trust score asagidaki aktivitelerden hesaplanir:

```text
SessionScore = min(completedSessionCount * 2, 40)
VerificationScore = min(verificationCount * 10, 30)
CancellationPenalty = cancelledSessionCount * 5
TrustScore = clamp(SessionScore + VerificationScore - CancellationPenalty, 0, 100)
```

MVP servis katmaninda session status listesi uzerinden completed ve cancelled
sayilari ozetlenebilir. Gercek Firestore session ve verification kayitlarindan
otomatik guncelleme backend entegrasyonu ile tamamlanir.

## 4. Credit ve Escrow Uygulamasi

> 19 Ekim 2026 ürün düzeltmesi: Bu bölüm eski tek yönlü öğretici/öğrenci modelini
> anlatır. Güncel hedef, iki kişinin de hem paylaşıp hem öğrendiği karşılıklı
> takas ve katılımcı bazlı escrow'dur. Mevcut kod da dönüşüm gerektirir.
> [Güncel dönüşüm planı](../YAYIN_YOL_HARITASI.md).


Credit cost asagidaki formulle hesaplanir:

```text
CreditCost = BaseCredit * (TeacherLevel / 3)
```

MVP'de sonuc min/max sinirlariyla korunur. Varsayilan sinirlar 10 ve 100
kredidir.

Escrow state gecisleri:

```text
pending -> locked -> completed
pending -> cancelled
locked -> refunded
```

Kredi kilitlenmeden session tamamlanamaz. Gercek bakiye dusme, escrow kaydi
olusturma ve ogreticiye kredi aktarma islemleri Firestore transaction veya
backend servis katmaninda uygulanmalidir.

## 5. Skill Graph Uygulamasi

Skill Graph edge yapisi:

```text
fromSkillId
toSkillId
relationStrength
```

`relationStrength` 0-1 araligindadir. Skill onerilerinde skor:

```text
RecommendedSkillScore = UserSkillLevel * relationStrength / 7
```

Matching icinde graph kullanimi opsiyoneldir. Graph servisi verilmezse sistem
sadece exact skill match uretir.
