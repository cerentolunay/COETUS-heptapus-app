# YAYIN-00 — Telefon inceleme kaydı

Görev: [Issue #24](https://github.com/cerentolunay/COETUS-heptapus-app/issues/24).
Tarih: 19 Ekim 2026. Testi yürüten: Codex; görsel ürün onayı: ürün sahibi.

## Sürüm ve cihaz

- Kaynak başlangıcı: `d17ff071d039b6a00f8c0c03fc9ec201a7988a85` (PR #30). Bu inceleme dalı: `test/yayin-00-phone-review`; henüz main ile birleştirilmedi.
- Paket: `com.heptapus.coetus`, sürüm `1.0.0+1`, debug. Cihaz testi için `integration_test/phone_review_test.dart` derlendi ve kaldırma yapılmadan kuruldu.
- Fiziksel cihaz: Samsung Galaxy A33 / SM-A336E; Android 16, API 36; 1080×2400; sistem yazı ölçeği 1.1.
- Çevrimdışı örnek Deniz hesabı. Firebase başlatılmaz; gerçek bakiye, mesaj, ödeme veya hesap silme işlemi yapılmaz.
- Test paketi kurulumu başarılı. Fiziksel ekran testi ilk adımda ekran kilidinde kaldığı için durduruldu; ardından USB bağlantısı kesildi. Son düzeltmeleri içeren normal çevrimdışı APK derlendi ancak bağlantı kesildiği için kurulamadı. Otomatik yerel sonuçlar fiziksel cihaz sonucu yerine yazılmadı.

## Ekran listesi

Yerel sütun: 360×800 açılış/galeriye dönüş ve 320×640 / 1.3 yazı ölçeğinde açılış kontrolleri. Fiziksel sütun, cihazda alınmış kanıt olmadan kapatılmaz. Listedeki 30 ekran `previewScreens` kataloğundan alınmıştır; main tabanlı eski indirme paketinde 28 ekran bulunabilir.

| No | Ekran | Yol | Yerel otomatik kontrol | Fiziksel cihaz |
|---|---|---|---|---|
| 01 | Kullanıcı adı ve QR ile bul | `/find-profile` | Geçti | Bekliyor: ekran kilidi |
| 02 | Profil QR kodu okut | `/scan-profile` | Geçti | Bekliyor: ekran kilidi |
| 03 | Premium ve token paketleri | `/premium` | Geçti | Bekliyor: ekran kilidi |
| 04 | Açılış | `/splash` | Geçti | Bekliyor: ekran kilidi |
| 05 | Karşılama | `/welcome` | Geçti | Bekliyor: ekran kilidi |
| 06 | Tanıtım | `/onboarding` | Geçti | Bekliyor: ekran kilidi |
| 07 | Giriş yap | `/login` | Geçti | Bekliyor: ekran kilidi |
| 08 | Kayıt ol | `/register` | Geçti | Bekliyor: ekran kilidi |
| 09 | Şifremi unuttum | `/forgot-password` | Geçti | Bekliyor: ekran kilidi |
| 10 | İlgi alanlarını keşfet | `/discovery` | Geçti | Bekliyor: ekran kilidi |
| 11 | Profili tamamla ve beceri ağacı | `/complete-profile` | Geçti | Bekliyor: ekran kilidi |
| 12 | Eşleşmeler ve topluluk akışı | `/matching` | Geçti | Bekliyor: ekran kilidi |
| 13 | Yetenek detayı | `/skill-detail` | Geçti | Bekliyor: ekran kilidi |
| 14 | Kişinin profili | `/other-profile` | Geçti | Bekliyor: ekran kilidi |
| 15 | Eşleşme kutlaması | `/match-success` | Geçti | Bekliyor: ekran kilidi |
| 16 | Paylaşım detayı | `/community-post/preview-post` | Geçti | Bekliyor: ekran kilidi |
| 17 | Paylaşım oluştur | `/compose` | Geçti | Bekliyor: ekran kilidi |
| 18 | Yorumlar | `/comments` | Geçti | Bekliyor: ekran kilidi |
| 19 | Token desteği | `/support` | Geçti | Bekliyor: ekran kilidi |
| 20 | Mesajlar | `/chat` | Geçti | Bekliyor: ekran kilidi |
| 21 | Sohbet | `/chat-detail/preview-chat` | Geçti | Bekliyor: ekran kilidi |
| 22 | Bildirimler | `/notifications` | Geçti | Bekliyor: ekran kilidi |
| 23 | Aktif, bekleyen ve geçmiş | `/exchange` | Geçti | Bekliyor: ekran kilidi |
| 24 | Oturum detayı | `/exchange-detail/preview-session` | Geçti | Bekliyor: ekran kilidi |
| 25 | Profilim ve beceriler | `/profile` | Geçti | Bekliyor: ekran kilidi |
| 26 | Profili düzenle | `/profile/edit` | Geçti | Bekliyor: ekran kilidi |
| 27 | Hesap profili | `/account` | Geçti | Bekliyor: ekran kilidi |
| 28 | Çalışmalarım | `/verification` | Geçti | Bekliyor: ekran kilidi |
| 29 | Çalışma detayı | `/work-detail` | Geçti | Bekliyor: ekran kilidi |
| 30 | Hesap silme onayı | `/delete-account` | Geçti | Bekliyor: ekran kilidi |

## Etkileşimler ve bulgular

| ID | Bulgu / beklenen | İşlem ve doğrulama |
|---|---|---|
| 00-F01 | Sohbette 320×640, yazı 1.3 ve 280 piksel klavye alanıyla alt tarafta 21 piksel taşma. Mesaj alanı erişilebilir kalmalı. | Klavye açıkken ek takas bilgi kutusu daraltıldı; başlık ve detay kilit ikonu korunur. Yeni klavye/geri testi geçti. Fiziksel Android klavyesiyle yeniden test bekliyor. |
| 00-F02 | Görev ve telefon rehberi 28 ekran diyordu; mevcut dalda 30 ekran var. | Güncel liste bu kayda eklendi; eski indirilebilir APK ile yeni dal ayrıldı. |
| 00-F03 | Önizleme açıklaması token bakiyesinin örnek olduğunu ayrıca belirtmiyordu. | Galeriye “Gösterilen token bakiyesi örnektir; gerçek bakiyen değildir” açıklaması eklendi; çevrimdışı uyarı testi geçti. Ürün sahibinin okuyup onaylaması bekliyor. |

Yerel `phone_preview_readiness_test.dart`: 35 test geçti (30 ekran, dört klavye/geri senaryosu, örnek bakiye açıklaması). Toplam 173 Flutter testi geçti; statik analiz temiz. Klavye ve sistem geri davranışı bu dosyada simüle edilir; gerçek Android IME/predictive back testi sayılmaz. Diğer mevcut testler maskot, dokunma pırıltısı, keşif halkaları, eşleşme kutlaması, ortak ilgi ağacı ve pasif Premium akışını kapsar.

## Yeniden çalıştırma ve kanıtlar

```powershell
flutter test --no-pub test/phone_preview_readiness_test.dart test/preview_gallery_test.dart
flutter drive --no-pub --driver test_driver/phone_review_driver.dart --target integration_test/phone_review_test.dart -d TELEFON_KIMLIGI
```

Telefon açık ve kilitsiz olmalıdır. Cihaz testi, 30 gerçek uygulama ekranını örnek verilerle açar, Flutter hatalarını ve Firebase başlatılmadığını kontrol eder, her ekrandan Ekranlar düğmesiyle galeriye döner. Gerçek hesaplara giriş yapmaz ve kamera/galeri yüklemesi başlatmaz. Ekran görüntüleri ancak çekim tamamlanınca `build/phone-review/screen-01.png` … `screen-30.png`, özet `result.json` içine kaydedilir. Bu dosyalar şu anda oluşmadı; tamamlanmış kanıt olarak gösterilmez. Telefon seri numarası, cihazdaki kişisel içerik ve debug servis URL'leri repoya eklenmez.

Kullanıcının açabileceği normal çevrimdışı APK:

```powershell
flutter build apk --debug --no-pub --target lib/main_preview.dart --target-platform android-arm64
adb -s TELEFON_KIMLIGI install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s TELEFON_KIMLIGI shell am start -n com.heptapus.coetus/.MainActivity
```

## Açık kabul ölçütleri

- [x] Telefon modeli, Android ve kurulan sürüm kaydedildi.
- [x] Güncel 30 ekran listelendi; yerel sonuçlar ve bulgular ayrı kaydedildi.
- [ ] 30 ekranın fiziksel cihaz testi ve ekran kanıtları tamamlandı.
- [ ] Gerçek Android klavye/geri düğmesi ve ürün sahibinin görsel incelemesi tamamlandı.
- [ ] Ürün sahibi önizleme bakiyesinin gerçek bakiyesi olmadığını okuduğunu onayladı.

Issue, fiziksel cihaz kanıtları ve ürün onayı beklediği için açık bırakılır. Ücretli hizmet, plan değişikliği veya canlı Firebase yayını yapılmaz.

## Derlenen son APK

- Yol: `build/app/outputs/flutter-apk/app-debug.apk`
- Mod/giri?: debug / `lib/main_preview.dart`
- Boyut: 150035053 bayt
- SHA-256: `d22c1f699b2a2bc22df83afc71157a1c359d85c14d30728e9da10ad45dcb9c63`
- Durum: derlendi; USB ba?lant?s? kesildi?i i?in son paket kurulamad?.
