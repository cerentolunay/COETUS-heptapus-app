# Yayına hazırlık — sıralı görevler

Önce **00** ile telefon sürümünü incele; sonra bağımlılıklara göre **01 → 22**
üretim işlerini gerçekleştir. **23 (iOS)** ve **24 (ödeme)** sonraki aşamadır.
Numara tek başına bağımlılığı ortadan kaldırmaz; her dosyadaki ön koşulu kontrol et.

Her görev ayrı dosyada yapılacak adımlar, sorumlu, ön koşullar, kabul ölçütleri ve
kanıt alanı içerir. Kutuları kanıt olmadan kapatma. Kodda bulunan ama gerçek cihazda
ve canlıda denenmemiş işler tamamlanmış değildir. 50/20 hediyeler ve tek yönlü
eskiden kalan escrow testleri, hedef karşılıklı takasın hazır olduğunu kanıtlamaz.

## GitHub’da nasıl takip edilir?

1. Aşağıdaki görev dosyasını aç ve ön koşullarını tamamla.
2. Dosyanın üstündeki **Bu görevi GitHub Issue olarak aç** bağlantısına dokun.
   Başlık ve kabul ölçütleri hazır gelir; GitHub’da **Submit new issue** ile kaydet.
3. Oluşan Issue’yu kendine ata; gerekli ekran görüntüsü ve test sonuçlarını ekle.
4. Kabul ölçütleri bitince Issue’yu kapat ve dosyanın tamamlama kaydına bağlantısını yaz.

Bu çalışma ortamında GitHub Issues API erişimi engelli olduğu için Issue nesneleri
otomatik oluşturulamadı. **Aşağıdakiler GitHub’a yüklenen görev dosyalarıdır;
önceden açılmış Issue numarası gibi sunulmaz.** Bağlantılardan mevcut hesap yetkinle
tek tek Issue oluşturabilirsin veya dosyaları GitHub düzenleyicisinden takip edebilirsin.

| Sıra | Bitti | Görev | Ön koşul | Sorumlu |
|---|---|---|---|---|
| 00 | [ ] | [Telefon test sürümünü incele ve bulguları kaydet](gorevler/00.md) | Yok | Ürün sahibi |
| 01 | [ ] | [Karşılıklı öğrenme ve escrow ürün kararlarını kesinleştir](gorevler/01.md) | 00 | Ürün sahibi + geliştirici |
| 02 | [ ] | [Firebase maliyetini ve ücretsiz backend yolunu kararlaştır](gorevler/02.md) | 01 | Ürün sahibi + geliştirici |
| 03 | [ ] | [Test ortamını ve güvenli geliştirme sürecini kur](gorevler/03.md) | 02 | Geliştirici |
| 04 | [ ] | [İki yönlü takas veri modelini ve eski kayıt geçişini tasarla](gorevler/04.md) | 01, 03 | Geliştirici |
| 05 | [ ] | [Karşılıklı beceri eşleşmesini doğrula](gorevler/05.md) | 04 | Geliştirici |
| 06 | [ ] | [İki kişinin mutabakatını ve atomik escrow kilidini geliştir](gorevler/06.md) | 02, 04, 05 | Geliştirici |
| 07 | [ ] | [Ortak tamamlama ve escrow çözümünü uygula](gorevler/07.md) | 01, 06 | Geliştirici |
| 08 | [ ] | [Karşılıklı iptal, anlaşmazlık ve zaman aşımını tamamla](gorevler/08.md) | 07 | Ürün sahibi + geliştirici |
| 09 | [ ] | [Firestore/Storage kuralları ve indeksleri yeni modele uyarla](gorevler/09.md) | 04, 06, 07, 08 | Geliştirici |
| 10 | [ ] | [Google/e-posta girişini ve şifre resetini gerçek cihazda doğrula](gorevler/10.md) | 02, 03, 09 | Hesap sahibi + geliştirici |
| 11 | [ ] | [50/20 token hediyelerini canlı geçişte ve yeni takasta doğrula](gorevler/11.md) | 06, 09, 10 | Geliştirici + testçi |
| 12 | [ ] | [Yönetici hesabını ve ilgi önerisi operasyonunu hazırla](gorevler/12.md) | 09, 10 | Ürün sahibi + yetkili geliştirici |
| 13 | [ ] | [Kullanıcı engelleme ve genel şikâyet/moderasyonunu geliştir](gorevler/13.md) | 04, 09, 12 | Geliştirici + yönetici |
| 14 | [ ] | [Hesap silmeyi yeni escrow modeliyle uçtan uca tamamla](gorevler/14.md) | 02, 08, 09, 13 | Geliştirici + testçi |
| 15 | [ ] | [Medya, izinler ve veri yaşam döngüsünü doğrula](gorevler/15.md) | 02, 09, 14 | Geliştirici + ürün sahibi |
| 16 | [ ] | [Bildirimleri ve yönlendirmeleri gerçek hesaplarla dene](gorevler/16.md) | 07, 08, 10, 13 | Geliştirici + testçi |
| 17 | [ ] | [Tüm cihaz kabul testlerini kapat](gorevler/17.md) | 00, 05, 06, 07, 08, 10, 11, 13, 14, 15, 16 | Testçi + ürün sahibi |
| 18 | [ ] | [Gizlilik, kullanım, topluluk ve silme sayfalarını yayınla](gorevler/18.md) | 01, 13, 14, 15 | Ürün sahibi |
| 19 | [ ] | [Android release imzasını ve uygulama kimliğini hazırla](gorevler/19.md) | 03, 10 | Hesap sahibi + geliştirici |
| 20 | [ ] | [Üretim AAB’sini aynı commit’ten üret ve doğrula](gorevler/20.md) | 09, 17, 18, 19 | Geliştirici + testçi |
| 21 | [ ] | [Play Console hesabı, mağaza sayfası ve zorunlu testi tamamla](gorevler/21.md) | 18, 19, 20 | Play hesabı sahibi |
| 22 | [ ] | [Onaylı backend ve mağaza yayınını kontrollü gerçekleştir](gorevler/22.md) | 02, 09, 12, 14, 17, 18, 20, 21 | Ürün sahibi + yetkili geliştirici |
| 23 | [ ] | [iOS Google/Apple kurulumu ve TestFlight hazırlığı](gorevler/23.md) | 02, 17, 18; Android ilk yayınına göre sonraki aşama | Apple hesabı sahibi + geliştirici |
| 24 | [ ] | [Premium ve 250 token satışını ayrı sürümde geliştir](gorevler/24.md) | 01, 02, 07, 18, 22 | Ürün sahibi + ödeme geliştiricisi |

## Üretime çıkış kapısı

- [ ] Karşılıklı takas ve escrow çözüm kuralı kesin ve uygulanmış.
- [ ] Ücretli Firebase işlemi açılmadan maliyet/backend kararı verilmiş.
- [ ] Auth, hesap silme, engelleme/şikâyet ve token güvenliği gerçek cihazda doğrulanmış.
- [ ] Gizlilik/silme adresleri ve mağaza beyanları hazır.
- [ ] Release imzası, son AAB ve mağaza test şartları tamam.
- [ ] Ürün sahibinin yayına onayı ve destek/geri dönüş planı var.

[Telefon kurulumu](TELEFONDA_TEST.md) · [Yol haritası](YAYIN_YOL_HARITASI.md) ·
[Cihaz test matrisi](doc/21-yayin-test-matrisi.md)
