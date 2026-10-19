# COETUS — telefonda son sürümü kontrol et

İki **Android test paketi** vardır:

| Paket | Ne için? | İndir |
|---|---|---|
| Normal test sürümü | Gerçek giriş/kayıt ve uygulama akışını kendi test hesabınla kontrol etmek; depodaki Firebase projesine bağlanır | [coetus-test-arm64.apk](https://github.com/cerentolunay/COETUS-heptapus-app/raw/refs/heads/builds/android-preview/coetus-test-arm64.apk) |
| Çevrimdışı önizleme | Hesap açmadan 28 ekranı örnek Deniz hesabıyla incelemek; Firebase'e bağlanmaz | [coetus-preview-arm64.apk](https://github.com/cerentolunay/COETUS-heptapus-app/raw/refs/heads/builds/android-preview/coetus-preview-arm64.apk) |

İkisi de debug imzalıdır; mağaza sürümü değildir. Premium satın alma kapalıdır.
Google girişi, e-posta teslimi, canlı kurallar ve backend henüz gerçek cihazda
doğrulanmadı. Normal APK'nın derlenmesi bu servislerin tamamlandığını göstermez.
Önce çevrimdışı pakette tasarımı inceleyebilir, sonra normal paketi kurabilirsin.

## İndir ve kur

1. Telefonda GitHub hesabına giriş yap.
2. Yukarıdaki tablodan istediğin APK dosyasını indir.
   Bağlantı dosyayı açarsa **Download raw file** seçeneğini kullan.
3. İndirilen `.apk` dosyasına dokun. Gerekirse Android ayarlarından yalnızca
   indirme yaptığın tarayıcı/dosya uygulamasına **Bilinmeyen uygulama yükleme** izni ver.
4. **Yükle → Aç**. Çevrimdışı pakette üstte **ÖNİZLEME · ÇEVRİMDIŞI** yazısı vardır;
   sağ üstteki **Ekranlar** düğmesiyle tüm sayfaları tek tek açabilirsin.
5. Normal pakette test hesabınla giriş yap. Canlı hesap/veri işlemleri gerçek
   Firebase projesinde gerçekleşir; silme ve takas işlemlerini ana hesabında deneme.
6. Testten sonra tarayıcıya verdiğin yükleme iznini kapatabilirsin.

Paketler **arm64-v8a** Android telefon içindir (Android 7/API 24 ve üzeri).
iPhone'a kurulmaz. Kurulum başarısızsa telefon modeli,
Android sürümü ve tam hata mesajını kaydet.

**Mevcut kurulum:** Paket adı `com.heptapus.coetus`; farklı anahtarla imzalanmış eski
COETUS kurulumu varsa Android güncellemeyi reddedebilir. Mevcut uygulamayı silmek
yerel verileri silebilir. Verileri korumadan kaldırma; böyle bir durumda önce hata
mesajını paylaş veya başka bir Android cihazda test et. Bu iki yeni paket aynı
imzayı/paket adını kullanır; birini kurduğunda diğerinin yerini alır.

## Normal sürümde giriş çalışmazsa

1. [Paket dalındaki SURUM.md](https://github.com/cerentolunay/COETUS-heptapus-app/blob/builds/android-preview/SURUM.md)
   içinden bu APK'nın **SHA-1/SHA-256 sertifika parmak izlerini** al.
2. Firebase Console → Project settings → Android `com.heptapus.coetus` → SHA
   certificate fingerprints alanına ekle. Bunlar herkese açık sertifika bilgileridir;
   özel imzalama anahtarı veya parola değildir.
3. Authentication → Sign-in method bölümünde Google ve Email/Password ayarlarını,
   Google destek e-postasını ve OAuth consent/test kullanıcılarını kontrol et.
4. Konsol yeni `google-services.json` verirse doğru Android uygulamasının dosyasını
   güncelle ve yeniden derle. iOS dosyasını Android'e kopyalama.
5. E-posta resetinde şablon, spam klasörü, kota ve linki kontrol et. Başarı metni,
   e-postanın gelen kutusuna ulaştığının kanıtı değildir.
6. İzin hatasında canlı Firestore kuralları/indekslerini ayrı kontrol et.
   [Görev 10](gorevler/10.md) ve [giriş rehberi](doc/20-google-giris-ve-sifre-sifirlama.md)
   ayrıntıları içerir. Bu adımlar ücretli Firebase planı açmayı gerektirmez.

Karşılıklı escrow backend dönüşümü tamamlanmadı. Mevcut tek yönlü takas akışını
nihai ürün olarak onaylama; [görev 01 ve 04–09](YAYIN_GOREVLERI.md).

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

Flutter 3.41.5, **tam JDK 21** ve Android SDK kurulu ortamda, kaynak commit'inden:
`java -version` ile birlikte `javac -version` da çalışmalıdır; yalnızca JRE kurulması
Android derlemesi için yeterli değildir. `JAVA_HOME` JDK dizinini göstermelidir.

SDK paketleri (34/35, mevcut Android eklentilerinin derleme hedefleridir):

```bash
sdkmanager 'platform-tools' 'platforms;android-34' 'platforms;android-35' 'platforms;android-36' 'build-tools;35.0.0' 'ndk;28.2.13676358' 'cmake;3.22.1'
```

SDK lisanslarını kullandığın SDK Manager üzerinden tamamladıktan sonra:

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64 --split-per-abi -t lib/main_preview.dart
# Önizleme çıktısını ayrı yere kopyaladıktan sonra normal test paketi:
flutter build apk --debug --target-platform android-arm64 --split-per-abi -t lib/main.dart
```

Her komut aynı çıktıyı yazar: `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`.
`main_preview.dart` yalnızca debug modunda çalışır. Mağaza AAB'si gerçek `main.dart`,
release imzası ve tamamlanmış yayın kapıları gerektirir; [görev 19–22](YAYIN_GOREVLERI.md).

Telefonunda fiziksel test henüz yapılmadı. Otomatik ekran testleri canlı servislerin
yerine geçmez. [Ayrıntılı doğrulama kaydı](doc/22-yayin-hazirligi-dogrulama.md).
