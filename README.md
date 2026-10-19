# COETUS — Android telefon test paketleri

Bu dal yalnızca indirilebilir test APK'larını içerir. Uygulama kaynakları ve görevler
[main dalındadır](https://github.com/cerentolunay/COETUS-heptapus-app/tree/main).

- [Normal test APK'sını indir](coetus-test-arm64.apk?raw=true): gerçek giriş/kayıt akışı, depodaki Firebase projesi.
- [Çevrimdışı önizleme APK'sını indir](coetus-preview-arm64.apk?raw=true): örnek hesapla 28 ekran, Firebase'e bağlanmaz.
- [Telefona kurulum ve giriş sorunlarını kontrol etme](https://github.com/cerentolunay/COETUS-heptapus-app/blob/main/TELEFONDA_TEST.md).
- [Sıralı 25 yayın görevi](https://github.com/cerentolunay/COETUS-heptapus-app/blob/main/YAYIN_GOREVLERI.md).
- [Derleme, imza ve checksum kaydı](SURUM.md).

Android arm64-v8a, Android 7/API 24 ve üzeri. İki paket aynı uygulama kimliğini ve
test sertifikasını kullanır; birbirinin yerini alır. Mağaza/release sürümü değildir.
Normal paket profile, önizleme debug modundadır. Google, e-posta, canlı kurallar
ve backend için fiziksel cihaz testi tamamlanmadı.
Gerçek para/Premium satın alma kapalıdır. Ücretli altyapı açılmadı.

Dosya doğrulaması: APK'ları ve `SHA256SUMS` dosyasını aynı klasöre indir,
`sha256sum -c SHA256SUMS` çalıştır. SHA-256 dosya bütünlüğü içindir; sertifika
parmak izleri `SURUM.md` içindedir.
