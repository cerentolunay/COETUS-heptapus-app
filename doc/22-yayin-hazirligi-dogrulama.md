# Yayına hazırlık ve telefon sürümü doğrulama kaydı

**Tarih: 19 Ekim 2026, Türkiye saati.**

Başlangıç ana dalı: `eb6c52a8216886222d7185c5a5033b6f5e9c8524`.
Çalışma dalı: `feat/coetus-release-preparation`.
Bu kayıt, canlıya yayın sertifikası veya gerçek cihaz test tutanağı değildir.

**Ürün modeli düzeltmesi:** Aşağıdaki sonuçlar `e7634a1` geliştirmesindeki mevcut
tek yönlü öğrenme/escrow uygulamasına aittir. Hedef ürün, iki kişinin de öğrendiği
ve paylaştığı karşılıklı takastır. Çift taraflı escrow ve ortak tamamlama henüz
uygulanmadı; bu testler onun hazır olduğunu kanıtlamaz. Güncel hedef ve yapılacaklar
ana yol haritasının bölüm 7'sinde ve cihaz matrisinin E bölümündedir.

## İlk doğrulama turu (`e7634a1`)

| Kontrol | Sonuç | Kapsam |
|---|---|---|
| `flutter analyze --no-pub` | Geçti, No issues found | Tüm depo |
| `flutter test --no-pub` | 115 geçti | Mevcut ve yeni Flutter testleri |
| `npm run check` | Geçti | Functions giriş dosyası sözdizimi |
| Auth/Firestore/Storage emülatörleriyle `npm test` | 34 geçti, 0 başarısız, 0 atlanan | İşlev, kural, hesap silme ve hediye senaryoları |
| `git diff --check` | Geçti | Boşluk/patch biçimi |

Tüm depo analizinde önceden bulunan `avoid_print` uyarısı, profil tamamlama
notifier'ında yalnızca debug modunda hassas veri içermeyen mesaj yazılarak giderildi.
Bu düzenleme finansal veya uygulama yönlendirme davranışını değiştirmez.

Araçlar: Flutter 3.41.5, Node 22.23.3; emülatörler Java 21 ile çalıştırıldı.
`flutter pub get --enforce-lockfile` daha önce bu Flutter sürümüyle doğrulandı;
bağımlılık beyanları ve lockfile bu geliştirmede değiştirilmedi.

## Özellikle doğrulanan davranışlar

- Tek UID için 50 token welcome makbuzu; tekrar/eşzamanlı girişte ikinci ödeme yok.
- Mevcut bakiyenin sıfırlanmaması; keyfi tutar, başka hesap, silinmiş hesap ve
  tek başına makbuz/bakiye yazımının reddi.
- İlk eşleşme için ayrı 20 token, welcome ile toplam 70 ve tekrar ödeme yasağı.
- Önceki eşleşmesi olmayan, ilk 50 tokenı almış hesabın **mevcut tek yönlü**
  30 tokenlık oturumu fonlayabilmesi: 20 kullanılabilir + 30 kilitli bakiye.
  İki kişinin de katkısını kilitleyen karşılıklı takas bu testin kapsamında değildir.
- İlgi önerisi gizliliği, yönetici onayı/ret ve yetkisiz yayınlamanın reddi.
- Mevcut hesap silme, emanet-token, ödeme/iade ve topluluk testlerinin korunması.
- Giriş/profil ortak ilgi kartları, beceri seçimi ve final forma seçim aktarımı.
- Seviye penceresinde kaydetme/iptal davranışı ve küçük ekranda büyük yazı.
- Premium sayfasına token rozetlerinden geçiş, paketlerin pasif olması.
- Maskot, dokunma pırıltıları, kalp ve halkalar; azaltılmış hareket ve kaynak temizliği.
- Şifre resetinde form doğrulama, gerçek servis callback'ini bekleme, tekrar basma
  engeli ve hata sonrası tekrar deneme. Testte gerçek e-posta gönderilmez.
- Google sağlayıcı, Android imza ve giriş sonrası Firestore izin hatalarının ayrılması.

## Bu sonuçların kapsamadıkları

- Fiziksel Android cihazda gerçek Google hesabı, SHA/OAuth yapılandırması.
- Gerçek reset e-postasının gelen kutusuna teslimi ve linkin kullanımı.
- Gerçek hesaplara welcome veya eşleşme tokenı yazılması.
- Canlı Firestore/Storage kuralları, indeks durumu ve Functions endpoint'leri.
- Üretim projesinin etkin kaynakları, fatura tutarı veya Spark/Blaze uygunluğu.
- Gerçek hesaba yönetici claim'i atanması.
- İmzalı Android release AAB/APK üretimi ve Play üzerinden kurulum.
- iOS/Apple imzalama, TestFlight veya App Store; web Firebase kurulumu.
- Gerçek kullanıcıyla hesap silme, medya temizliği ve moderasyon operasyonu.
- Premium ödemesi veya üyelik/token satın alımı.
- Mağazaya yayın; main birleştirme durumu aşağıdaki son tur kaydında izlenir.

Yeni build, kurallar veya sunucu değiştiğinde ilgili testler yeniden çalıştırılır.
Cihaz/üretim kontrolleri `21-yayin-test-matrisi.md` üzerinden kanıtla kapatılır.


## Telefon sürümü hazırlığı — son tur

19 Ekim 2026'da yeniden çalıştırılan kontroller:

| Kontrol | Sonuç |
|---|---|
| `flutter analyze --no-pub` | Geçti, uyarı/hata yok |
| `flutter test --no-pub` | **143 geçti** |
| Yeni küçük ekran testleri | 28 ekran; 320×640, 1.3 yazı ölçeği; Firebase başlatılmadan gezinme |
| `npm run check` | Geçti |
| Auth/Firestore/Storage emülatörleriyle `npm test` | **34 geçti, başarısız/atlanan yok** |

İlk küçük ekran taramasında 8 ekran taşma verdi. Alt menü genişlikleri, keşfet
sıralama alanı, profil beceri satırı/başlığı, hesap profili kaydırması ve topluluk
bağış penceresi düzeltildikten sonra 28 ekran ve tüm Flutter testleri geçti.
Bu tarama ilk açılışı ve ekran galerisine dönüşü kontrol eder; her düğmenin ve
klavyeli akışın fiziksel cihaz testi değildir.

25 ayrıntılı görev `YAYIN_GOREVLERI.md` ve `gorevler/` altında takip edilir.
GitHub Issues API ağ erişimi engelli olduğundan gerçek Issue nesneleri oluşturulmadı;
her görevde önceden doldurulan Issue açma bağlantısı vardır.

Kaynaklar `c80d250` birleştirme commit'iyle `main`e alınıp GitHub'a gönderildi.
Sonraki belge güncellemesi normal APK kurulumu ve sohbet zaman önerisinin henüz
placeholder olmasını da kapsar; uygulama kaynakları test edilen sürümle aynıdır.

Telefon paketleri normal giriş noktası (`lib/main.dart`, **profile**) ve çevrimdışı
önizleme (`lib/main_preview.dart`, **debug**) için ayrı test APK dosyalarıdır. Paket dalındaki
[`SURUM.md`](https://github.com/cerentolunay/COETUS-heptapus-app/blob/builds/android-preview/SURUM.md)
başarılı derleme kaydını, kesin kaynak commit'ini, sertifika ve checksum'u taşır.
Paketin varlığı/sonucu bu kayıttan kontrol edilir. Android SDK 36, eklentiler için
SDK 34/35, build-tools 35.0.0 ve **tam JDK 21 (javac dahil)** gerekir;
ilk denemede ortamdaki yalnızca
JRE kurulumu derlemeyi durdurdu, tam JDK eklendi. Mağaza release imzası ve gerçek
cihaz/servis doğrulaması ayrıca tamamlanmalıdır.

## Hazır Android test paketleri

Uygulama kaynak commit'i: `4186229a47a1467dfa33123b0c7f9ea4a7c4745f`.
Sonraki main değişiklikleri dokümantasyondur; uygulama kaynakları aynı kalmıştır.

| Paket | Mod | Boyut | Derleme |
|---|---|---|---|
| `coetus-test-arm64.apk` | profile, `main.dart` | 39.5 MB / 37.70 MiB | Geçti |
| `coetus-preview-arm64.apk` | debug, `main_preview.dart` | 100.6 MB / 95.94 MiB | Geçti |

İki APK için `apksigner verify` geçti; aynı test sertifikasıyla APK Signature v2
imzası doğrulandı. `aapt dump badging`: `com.heptapus.coetus`, sürüm 1.0.0,
versionCode 2001 (ABI bölme nedeniyle), arm64-v8a, minimum API 24, hedef/derleme
SDK 36. ZIP hizalama (`zipalign -c -P 16 4`) ve SHA-256 kontrolleri de geçti.
Profile paketinde AOT `libapp.so`, önizlemede debug `kernel_blob.bin` bulundu.

Normal debug APK da derlendi; 123.83 MiB olduğu için GitHub'ın 100 MiB dosya sınırını
aşıyordu. İndirilen normal paket bu nedenle daha küçük profile sürümüdür.
Büyük APK dosyaları kaynak main dalına eklenmez;
[`builds/android-preview` indirme dalında](https://github.com/cerentolunay/COETUS-heptapus-app/tree/builds/android-preview)
saklanır. Dosya hash'leri ve Google için sertifika parmak izleri o dalın `SURUM.md`
ve `SHA256SUMS` dosyalarındadır.

Bu statik paket kontrolleri fiziksel Android'de açılış, Google/e-posta teslimi,
canlı token veya çift taraflı escrow için başarı belgesi değildir.
