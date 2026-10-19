# COETUS telefon test sürümü

Kayıt zamanı: 2026-10-19T10:52:56+00:00.

Kaynak commit: [`4186229a47a1467dfa33123b0c7f9ea4a7c4745f`](https://github.com/cerentolunay/COETUS-heptapus-app/commit/4186229a47a1467dfa33123b0c7f9ea4a7c4745f).
Sonraki main güncellemeleri dokümantasyondur; derlenen uygulama kaynakları değişmedi.

## Paketler

- `coetus-test-arm64.apk`: `lib/main.dart`, **profile**; gerçek Firebase yapılandırması.
- `coetus-preview-arm64.apk`: `lib/main_preview.dart`, **debug**; örnek verili ekran galerisi.
- Paket adı: `com.heptapus.coetus`; etiket: Coetus.
- Sürüm adı: **1.0.0**, APK versionCode: **2001** (ABI bölme + kaynak build numarası 1).
- ABI: **arm64-v8a**, minimum Android API **24**, hedef/derleme SDK **36**.
- İki APK aynı Android Debug test sertifikasıyla imzalıdır; birbirinin yerini alır.
- Play Store AAB'si veya üretim imzası değildir. Premium satın alma kapalıdır.

| Dosya | Boyut | Dosyanın SHA-256 değeri |
|---|---|---|
| `coetus-test-arm64.apk` | 39,535,700 byte (37.70 MiB) | `897f6961a11642429a439962bb20a1321ed925a855eb0aec2fb5254b3e2e7e95` |
| `coetus-preview-arm64.apk` | 100,598,667 byte (95.94 MiB) | `fc67e774436ab671cd105ef5c30a71692921aea399beaa7f78c8270ef286c8f2` |

`SHA256SUMS` ile doğrula: `sha256sum -c SHA256SUMS`.

## Google giriş kurulumu için sertifika

Bunlar **APK dosya checksum'u değil**, imzalayan herkese açık sertifikanın
parmak izleridir. Firebase Console'da Android uygulamasının SHA alanına eklenir.
Özel anahtar/keystore bu dalda bulunmaz.

**SHA-1**

```text
86:57:EE:5B:80:76:BF:C4:9D:FE:2B:46:27:14:54:FD:EF:B7:5F:4E
```

**SHA-256**

```text
B9:1F:A5:33:3B:64:53:D3:A7:74:17:17:7A:50:3B:8F:7B:D3:F4:5B:B6:58:B8:90:38:C8:8D:11:B4:83:62:F5
```

## Derleme ve doğrulama

Araçlar: Flutter **3.41.5**, Dart **3.11.3**, Temurin JDK **21.0.12.1+1**,
Gradle **8.14**, AGP **8.11.1**, Android Build Tools **35.0.0**, SDK **34/35/36**,
NDK **28.2.13676358**, CMake **3.22.1**.

```bash
flutter build apk --debug --no-pub --target-platform android-arm64 --split-per-abi -t lib/main_preview.dart
flutter build apk --profile --no-pub --target-platform android-arm64 --split-per-abi --no-tree-shake-icons -t lib/main.dart
```

- İki derleme başarıyla tamamlandı; eski API/SDK XML uyarıları başarısızlık oluşturmadı.
- `apksigner verify --verbose --print-certs`: ikisi de geçerli, APK Signature v2.
- `aapt dump badging`: paket, 2001 sürüm kodu, API 24/36 ve arm64 doğrulandı.
- `zipalign -c -P 16 4`: ikisi de geçti. Fiziksel 16 KiB cihaz testi yapılmadı.
- Normal pakette AOT `libapp.so`, önizlemede debug `kernel_blob.bin` doğrulandı.
- Kaynak için `flutter analyze --no-pub`: hata/uyarı yok; **143 Flutter testi** geçti.
- Functions sözdizimi ve Auth/Firestore/Storage emülatör testleri: **34 geçti**.
- Fiziksel telefonda açılış, gerçek Google/e-posta, canlı kurallar ve backend henüz doğrulanmadı.
- Karşılıklı escrow dönüşümü hâlâ yayın görevidir; testler mevcut tek yönlü backend'e aittir.
- Ücretli Firebase planı/gerçek ödeme veya mağaza yayını açılmadı.

[Kurulum ve test adımları](https://github.com/cerentolunay/COETUS-heptapus-app/blob/main/TELEFONDA_TEST.md) ·
[25 sıralı yayın görevi](https://github.com/cerentolunay/COETUS-heptapus-app/blob/main/YAYIN_GOREVLERI.md).
