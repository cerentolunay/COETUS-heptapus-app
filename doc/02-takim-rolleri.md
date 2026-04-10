# Takım Rolleri ve Sorumluluklar

Bu proje, 8 kişilik bir öğrenci ekibi tarafından 30 gün içerisinde geliştirilecek bir MVP (Minimum Viable Product) olarak planlanmıştır. Her ekip üyesi belirli bir modülün ana sorumlusu olacak ve ilgili modülün geliştirilmesi, test edilmesi ve dokümante edilmesinden sorumlu olacaktır.

Amaç, ekip içinde sorumlulukların net bir şekilde belirlenmesi ve geliştirme sürecinin verimli ilerlemesidir.

---

# 1. Proje Yürütücüsü (Project Lead)

## Rol Tanımı

Proje yürütücüsü, projenin genel koordinasyonundan sorumludur. Projenin zaman planına uygun ilerlemesini sağlar ve ekip üyeleri arasındaki iletişimi yönetir.

## Temel Sorumluluklar

- Proje planını oluşturmak
- Görev dağılımını yapmak
- GitHub proje yönetimini yürütmek
- Sprint planlamasını yapmak
- Ekip içi koordinasyonu sağlamak
- Proje çıktılarının kontrolünü yapmak
- Dokümantasyon sürecini denetlemek

## Kullanılacak Araçlar

- GitHub Issues
- GitHub Project Board
- Markdown dokümantasyon
- Figma inceleme

## Çıktılar

- Güncel görev listesi
- Sprint planları
- Proje ilerleme raporları
- Son teslim çıktıları

---

# 2. Teknik Koordinatör

## Rol Tanımı

Teknik koordinatör, sistem mimarisinin tutarlı şekilde ilerlemesini sağlar. Geliştiriciler arasında teknik uyumluluğu denetler.

## Temel Sorumluluklar

- Sistem mimarisini belirlemek
- Veri modelini tasarlamak
- Kod standartlarını belirlemek
- Modüller arası entegrasyonu denetlemek
- Teknik sorunlara çözüm üretmek

## Bilmesi Gereken Konular

- Yazılım mimarisi
- Firebase yapısı
- Mobil uygulama veri akışı
- API ve backend mantığı

## Çıktılar

- Veri modeli dokümanı
- Sistem mimarisi açıklaması
- Teknik kararlar dokümanı

---

# 3. Mobil Uygulama Geliştirici 1

## Rol Tanımı

Mobil uygulamanın kullanıcı giriş sistemi ve kullanıcı profil yönetimi modülünü geliştirir.

## Temel Sorumluluklar

- Login ve register ekranları
- Onboarding akışı
- Profil oluşturma
- Skill ekleme ve düzenleme
- Kullanıcı bilgilerinin Firebase'e kaydedilmesi

## Bilmesi Gereken Konular

- Flutter widget sistemi
- Navigation
- Form yönetimi
- Firebase Auth entegrasyonu

## Çıktılar

- Giriş ve kayıt sistemi
- Kullanıcı profil ekranı
- Skill yönetim ekranı

---

# 4. Mobil Uygulama Geliştirici 2

## Rol Tanımı

Mobil uygulamanın keşif sistemi ve kullanıcı etkileşim modüllerini geliştirir.

## Temel Sorumluluklar

- Skill keşfetme ekranı
- Filtreleme sistemi
- Profil detay ekranı
- Teklif gönderme sistemi
- Session ekranları
- Bildirim yönlendirmeleri

## Bilmesi Gereken Konular

- Flutter UI tasarımı
- Liste ve filtreleme sistemleri
- Firestore veri çekme
- Modal ve bottom sheet yapıları

## Çıktılar

- Discovery ekranı
- Profil görüntüleme
- Teklif sistemi
- Session ekranı

---

# 5. Backend Geliştirici

## Rol Tanımı

Backend geliştirici, Firebase altyapısını kurar ve uygulamanın veri yönetimi sistemini geliştirir.

## Temel Sorumluluklar

- Firebase proje kurulumu
- Firestore veri yapısı
- Cloud Functions yazımı
- Kredi sistemi backend mantığı
- Escrow sistemi
- Güvenlik kuralları

## Bilmesi Gereken Konular

- Firebase Firestore
- Cloud Functions
- NoSQL veri modeli
- Güvenlik kuralları

## Çıktılar

- Çalışan backend sistemi
- Veri modeli
- Güvenli kredi transfer sistemi

---

# 6. Algoritma Geliştirici

## Rol Tanımı

Algoritma geliştirici, kullanıcıların eşleşmesini sağlayan ve kredi hesaplamalarını yöneten algoritmaları tasarlar.

## Temel Sorumluluklar

- Matching algoritması
- Skill seviyesine göre eşleşme
- Kredi hesaplama sistemi
- Güven skoru algoritması
- Adalet mekanizması

## Bilmesi Gereken Konular

- Algoritma tasarımı
- Veri sıralama yöntemleri
- basit öneri sistemleri

## Çıktılar

- Matching algoritması
- Kredi hesaplama formülü
- Trust score modeli

---

# 7. UI / UX Tasarımcı

## Rol Tanımı

UI/UX tasarımcı uygulamanın kullanıcı arayüzünü tasarlar ve tasarım sistemini oluşturur.

## Temel Sorumluluklar

- Figma tasarımlarını hazırlamak
- Design system oluşturmak
- Component kütüphanesi hazırlamak
- Kullanıcı akışlarını tasarlamak
- Eksik ekran durumlarını tasarlamak

## Bilmesi Gereken Konular

- Figma
- Mobil UX prensipleri
- Kullanıcı akış tasarımı

## Çıktılar

- Tam Figma tasarımı
- Component library
- UI akış diyagramı

---

# 8. QA / Test Sorumlusu

## Rol Tanımı

Test sorumlusu, uygulamanın hatalarını bulur ve sistemin stabil çalışmasını sağlar.

## Temel Sorumluluklar

- Test senaryoları hazırlamak
- Kullanıcı akışlarını test etmek
- Hata raporlamak
- Edge case testleri yapmak
- Beta test sürecini yönetmek

## Bilmesi Gereken Konular

- Test planı hazırlama
- kullanıcı akış analizi
- hata raporlama

## Çıktılar

- Test planı
- Bug listesi
- Beta test raporu

---

# Platform Uyumluluğu Notu

Uygulama Flutter kullanılarak geliştirilecektir. Bu nedenle Android ve iOS için ayrı geliştirici rolleri tanımlanmamıştır.

Mobil geliştiriciler ortak bir Flutter kod tabanı üzerinden geliştirme yapacak ve uygulama her iki platform için derlenebilir olacaktır.

Platforma özgü ayarlar (build ayarları, izinler, mağaza hazırlıkları) mobil geliştiriciler arasında paylaştırılacaktır.

---

# Ekip Çalışma Prensibi

Her ekip üyesi kendi modülünün ana sorumlusudur.

Ancak tüm geliştirmeler:

- GitHub üzerinden
- Pull Request sistemi ile
- Kod incelemesi yapılarak

ilerletilecektir.
