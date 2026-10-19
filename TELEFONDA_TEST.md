# COETUS — telefonda son ekranları incele

Bu paket **Android için çevrimdışı önizlemedir**. Örnek Deniz hesabıyla açılır;
gerçek Firebase hesabına bağlanmaz. 28 ekranı, mor/lime/kırmızı tasarımı, ilgi
alanlarını, beceri pencerelerini, Premium taslağını ve animasyonları incelemek içindir.
Google girişi, e-posta teslimi, gerçek token bakiyesi, mesajlaşma ve karşılıklı escrow
bu APK ile canlı doğrulanmış sayılmaz. Premium satın alma kapalıdır.

## İndir ve kur

1. Telefonda GitHub hesabına giriş yap.
2. [APK dosyasını indir](https://github.com/cerentolunay/COETUS-heptapus-app/raw/refs/heads/builds/android-preview/coetus-preview-arm64.apk).
   Bağlantı dosyayı açarsa **Download raw file** seçeneğini kullan.
3. İndirilen `.apk` dosyasına dokun. Gerekirse Android ayarlarından yalnızca
   indirme yaptığın tarayıcı/dosya uygulamasına **Bilinmeyen uygulama yükleme** izni ver.
4. **Yükle → Aç**. Üstte **ÖNİZLEME · ÇEVRİMDIŞI** yazısını görmelisin.
5. Sağ üstteki **Ekranlar** düğmesiyle tüm sayfaları tek tek aç.
6. Testten sonra tarayıcıya verdiğin yükleme iznini kapatabilirsin.

APK **arm64-v8a** Android telefon içindir (Android 7/API 24 ve üzeri; kesin alt sınır
derleme kaydında doğrulanır). iPhone'a kurulmaz. Kurulum başarısızsa telefon modeli,
Android sürümü ve tam hata mesajını kaydet.

**Mevcut kurulum:** Paket adı `com.heptapus.coetus`; farklı anahtarla imzalanmış eski
COETUS kurulumu varsa Android güncellemeyi reddedebilir. Mevcut uygulamayı silmek
yerel verileri silebilir. Verileri korumadan kaldırma; böyle bir durumda önce hata
mesajını paylaş veya başka bir Android cihazda test et. Bu APK debug anahtarıyla
imzalanır; Play Store'a yüklenmez.

## Sırayla neyi kontrol edeceksin?

1. Açılış: maskota dokununca zıplasın; boş alan dokunuşlarında kırmızı kalp/pırıltı.
2. Eşleşmeni keşfet: halkalar büyüyüp küçülsün, profil resimleri yuvarlak olsun.
3. İlgi alanları: kategoriye dokununca alt dallar açılsın; giriş ve profil aynı
   seçimi kullansın. Paylaşılacak beceri için mor/lime seviye penceresi açılsın.
4. Eşleşme kutlaması: kalple aynı renkte, uzaklaşırken kaybolan pırıltılar.
5. Keşfet/Profil/Takas: para birimi Token olarak tutarlı görünsün. Token rozetinden
   Premium sayfasına geç; sınırsız eşleşme ve 250 token paketlerini incele.
6. Ekranlar menüsündeki diğer sayfaları da aç: sohbet, topluluk, bildirimler,
   portföy, ayarlar, oturumlar ve destek. Örnek içerikle gezinmeyi dene.
7. Android yazı boyutunu büyüt; küçük ekranda taşma, klavye altında kalan alan ve
   geri düğmesini kontrol et. Animasyonları azaltma ayarıyla da dene.

Hata kaydı: ekran adı → adımlar → beklenen/olan → telefon modeli/Android sürümü →
ekran görüntüsü veya video. İlk takip dosyası: [YAYIN-00](gorevler/00.md).

## Paket kaydı ve yeniden derleme

[İndirilebilir paket dalı](https://github.com/cerentolunay/COETUS-heptapus-app/tree/builds/android-preview)
yalnızca APK, checksum ve derleme kaydını içerir; uygulama kaynak kodu `main`dedir.
Paket dalındaki `SURUM.md` kaynak commit'ini, araçları, boyutu ve SHA-256'yı gösterir.
Dosya doğrulaması: `sha256sum -c SHA256SUMS`.

Flutter 3.41.5, Java 21 ve Android SDK kurulu ortamda, kaynak commit'inden:

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64 --split-per-abi -t lib/main_preview.dart
```

Çıktı: `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`.
`main_preview.dart` yalnızca debug modunda çalışır. Mağaza AAB'si gerçek `main.dart`,
release imzası ve tamamlanmış yayın kapıları gerektirir; [görev 19–22](YAYIN_GOREVLERI.md).

Telefonunda fiziksel test henüz yapılmadı. Otomatik ekran testleri canlı servislerin
yerine geçmez. [Ayrıntılı doğrulama kaydı](doc/22-yayin-hazirligi-dogrulama.md).
