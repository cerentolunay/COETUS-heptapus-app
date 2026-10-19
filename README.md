# COETUS MVP

COETUS, eşleşen iki kişinin birbirine beceri paylaştığı ve birlikte öğrendiği bir mobil uygulamadır. Tokenlar karşılıklı takas taahhüdü için escrow'da tutulur.

## Temel Mantık

Eşleş → Karşılıklı paylaş ve öğren → Takası birlikte tamamla

Hedef ürün budur. Mevcut backend'in tek yönlü öğretmen/öğrenci modeli henüz bu
modele dönüştürülmedi; [yayın görevleri](YAYIN_GOREVLERI.md) 01 ve 04–09 bu farkı
kapatır. Eşit katkı ve escrow çözüm politikası ürün kararı bekler.

## Proje Amacı

Bu proje, yüksek kurs maliyetlerine alternatif olarak insanların birbirlerine yetenek öğretebildiği bir ekosistem oluşturmayı hedefler.

Aynı zamanda kullanıcıların:

- yeni ilgi alanları keşfetmesini
- sosyalleşmesini
- üretken bir öğrenme topluluğu oluşturmasını

sağlamayı amaçlar.

## Proje Durumu

Bu repo, 8 kişilik bir öğrenci ekibi tarafından geliştirilen 45 günlük MVP sürecini içermektedir.

## MVP Kapsamı

- Kullanıcı kayıt ve giriş sistemi
- Profil oluşturma
- Skill (yetenek) ekleme
- Skill keşfetme (kaydırma yok – marketplace mantığı)
- Teklif gönderme
- Session oluşturma
- Kredi sistemi
- Escrow (emanet kredi)
- Doğrulama sistemi

## Dokümantasyon

Tüm proje planları ve teknik detaylar `/doc` klasöründe bulunmaktadır.


## Yayına hazırlık

- **[Buradan başla: sıralı 25 yayın görevi](YAYIN_GOREVLERI.md)**
- **[Telefon test sürümü ve kurulum](TELEFONDA_TEST.md)**
- [Ayrıntılı yayın yol haritası](YAYIN_YOL_HARITASI.md): mevcut durum, eksikler,
  Firebase/maliyet kararı, Google girişi, token güvenliği, moderasyon, hesap silme,
  Android/iOS mağaza adımları ve üretime çıkış kontrol listesi.
- [Gerçek cihaz test matrisi](doc/21-yayin-test-matrisi.md)
- [Doğrulama kaydı ve sınırlar](doc/22-yayin-hazirligi-dogrulama.md)

Bu belgeler ve GitHub'a yükleme, canlı Firebase veya mağaza yayını yapıldığı
anlamına gelmez. Ücretli altyapı ve gerçek ödeme bu geliştirme kapsamında açılmaz.
