<p align="center">
  <img src="assets/icons/app_icon.png" width="180" alt="COETUS'un mor zemin üzerindeki lime renkli maskotu">
</p>

# COETUS

**Bildiğini paylaş, merak ettiğini öğren.**

COETUS, insanların birbirlerine becerilerini öğrettiği bir mobil uygulamadır. Bir kişi sana gitar öğretirken sen de ona Python öğretebilirsin. Her takasta iki kişi de hem öğretir hem öğrenir.

Mor ve lime renkleri, hareketli maskotu ve topluluk odaklı ekranlarıyla COETUS; beceri paylaşımını tanışma, üretme ve birlikte gelişme fırsatına dönüştürmeyi amaçlar.

> Proje geliştirme ve test aşamasındadır. Bu README, bulunduğu daldaki kaynak kodunu anlatır; mağazadaki veya daha önce indirilen bir APK'daki özellikler farklı olabilir.

## Nasıl çalışır?

1. **Profilini oluştur.** Kullanıcı adını belirle; ilgi alanlarını, paylaşabileceğin ve öğrenmek istediğin becerileri ekle.
2. **Eşleşmeni keşfet.** Birbirinizden öğrenebileceğiniz becerilere göre kişileri incele ve karşılıklı takas teklifi gönder.
3. **Birlikte öğren.** Teklif kabul edildiğinde ikinizin de token katkısı kilitlenir. Sohbet ederek öğrenme sürecinizi planlayın.
4. **Takası birlikte tamamlayın.** İkiniz de tamamlanmayı onayladığınızda herkesin kendi kilitlediği tokenlar hesabına geri döner.

## Özellikler

- **Profil ve kullanıcı adı:** Benzersiz kullanıcı adı, galeriden veya kameradan profil fotoğrafı ve düzenlenebilir ilgi alanları.
- **İlgi alanları ağacı:** Ana kategorilerden alt dallara ilerleyerek beceri ve ilgi alanı seçimi.
- **Beceri eşleştirme:** Büyük/küçük harf ve Türkçe karakter farklılıklarını normalleştiren beceri karşılaştırması.
- **Keşfet ve topluluk:** Kişileri ve paylaşımları keşfetme; beğeni, yorum ve “Birlikte öğren” akışı.
- **Sohbet ve bildirimler:** Eşleşmelerle mesajlaşma, etkileşim kalpleri ve uygulama içi bildirimler.
- **QR ile birbirini bulma:** QR kod veya kullanıcı adıyla profil bulma ve karşılıklı bağlantı kurma.
- **Çalışmalarım:** Becerilere bağlı, isteğe bağlı fotoğraf paylaşımları. Portföy paylaşımı kimlik doğrulaması veya otomatik yetenek onayı anlamına gelmez.
- **Takas geçmişi:** Profilde öğretilen ve öğrenilen becerilerin geçmişine erişim.
- **Çevrimdışı önizleme:** Gerçek hesap kullanmadan örnek verilerle ekranları inceleme.

## Token ve karşılıklı takas

Yeni hesaplar **200 başlangıç tokenı** alır. Bir takasta kişinin katkısı, karşı taraftan öğreneceği becerinin seviyesine göre **10–70 token** arasında belirlenir. İki kişinin katkısı eşit olmak zorunda değildir.

Örneğin senin **60**, eşleştiğin kişinin **70** tokenı kilitlendiyse:

| Sonuç | Tokenlara ne olur? |
| --- | --- |
| İkiniz de tamamlanmayı onaylarsanız | Sen 60, diğer kişi 70 tokenını geri alır. |
| İkiniz de iptali onaylarsanız | Herkes kendi kilitli katkısını geri alır. |
| İlk tamamlanma onayına yanıt gelmezse | 24 saat sonra uygulama içi hatırlatma oluşturulur; 72 saat sonunda itiraz yoksa herkesin kendi katkısı iade edilir. |
| Tamamlanma isteğine itiraz edilirse | Otomatik kapanma durur; karşılıklı iptal seçeneği devam eder. |

**24/72 saatlik süre eşleşmeden değil, ilk tamamlanma onayından başlar.** Sunucu 15 dakikada bir zamanı gelen işlemleri kontrol eder; telefonların açık olması gerekmez. Servis gecikmeleri olabilir. Süre dolması başarılı takas veya yetenek onayı sayılmaz.

QR ile bağlantı kurmak tek başına token ödülü oluşturmaz. Eski tek yönlü oturumlar yeni karşılıklı modele otomatik dönüştürülmez.

Ayrıntılar: [Karşılıklı takas kuralları](doc/28-karsilikli-takas-ve-zaman-asimi.md) · [Sunucuda süre kontrolü](doc/29-sunucuda-takas-sureleri.md)

## Ekran görüntüleri

Karşılama, keşfet/eşleşme, profil ve sohbet ekranlarının güncel görüntüleri bu bölüme eklenecek.

<!--
Görselleri doc/ekran-goruntuleri/ klasörüne ekledikten sonra aşağıdaki
tabloyu yorumdan çıkar. Gerçek görseller eklenmeden bağlantıları etkinleştirme.

<table>
  <tr>
    <th>Karşılama</th><th>Keşfet</th><th>Profil</th><th>Sohbet</th>
  </tr>
  <tr>
    <td><img src="doc/ekran-goruntuleri/karsilama.png" width="220" alt="COETUS karşılama ekranı"></td>
    <td><img src="doc/ekran-goruntuleri/kesfet.png" width="220" alt="COETUS keşfet ekranı"></td>
    <td><img src="doc/ekran-goruntuleri/profil.png" width="220" alt="COETUS profil ekranı"></td>
    <td><img src="doc/ekran-goruntuleri/sohbet.png" width="220" alt="COETUS sohbet ekranı"></td>
  </tr>
</table>
-->

## Kullanılan teknolojiler

| Katman | Teknolojiler |
| --- | --- |
| Mobil uygulama | Flutter, Dart |
| Durum yönetimi ve gezinme | Riverpod, GoRouter |
| Kimlik ve veri | Firebase Authentication, Cloud Firestore |
| Fotoğraf depolama | Firebase Storage |
| Sunucu işlemleri | Cloud Functions, Cloud Scheduler, Node.js 22 |
| Cihaz özellikleri | Kamera/galeri, QR tarama, konum izinleri |

Android ve iOS proje dosyaları bulunur. Mevcut cihaz test kayıtları Android içindir.

## Yerelde çalıştırma

### Gereksinimler

- Flutter SDK ve Dart **3.10.4 veya üzeri**, `pubspec.yaml` ile uyumlu sürümler.
- Android için Android SDK, JDK 21 ve bir emülatör veya USB hata ayıklaması açık telefon.
- iOS derlemesi için macOS ve Xcode.
- Sunucu geliştirmesi için Node.js 22.

Önce geliştirme ortamını kontrol et ve bağımlılıkları yükle:

```sh
flutter doctor
flutter pub get
flutter devices
```

### Gerçek uygulama

```sh
flutter run -t lib/main.dart
```

Bu giriş noktası Firebase'e bağlanır. Kendi Firebase projenle çalıştıracaksan platform yapılandırmalarını, oturum açma yöntemlerini ve erişim kurallarını o projeye göre ayarlamalısın. Depodaki yapılandırmalarla yapılan hesap ve veri işlemleri tanımlı Firebase projesini kullanır.

### Hesapsız, çevrimdışı önizleme

```sh
flutter run --debug -t lib/main_preview.dart
```

Bu sürüm Firebase'i başlatmaz; örnek hesap ve yerel veriler kullanır. **Ekranlar** menüsünden sayfaları tek tek açabilirsin. Önizlemedeki bakiyeler, mesajlar ve profiller gerçek hesap verisi değildir. Bu giriş noktası yalnızca debug derlemesinde kullanılabilir.

### Android test APK'sı

```sh
flutter build apk --debug -t lib/main.dart --target-platform android-arm64
```

Çıktı: `build/app/outputs/flutter-apk/app-debug.apk`. Bu komut mağaza yayını için imzalanmış bir dağıtım paketi oluşturmaz.

## Kontroller ve testler

```sh
flutter analyze
flutter test
```

Sunucu bağımlılıklarını yüklemek ve JavaScript sözdizimini kontrol etmek için:

```sh
cd functions
npm ci
npm run check
```

Firebase emülatör testleri; erişim kuralları, token kilitleme/iade, karşılıklı onay ve zaman aşımı senaryolarını kapsar. Emülatör gerektiren testler uygun ortam olmadan atlanabilir; yalnızca `npm test` çalıştırmak bunların doğrulandığı anlamına gelmez. Son kayıtlı test sonuçları ve sınırlar [sunucu süreleri belgesinde](doc/29-sunucuda-takas-sureleri.md) bulunur.

## Proje yapısı

```text
lib/
  app/          Uygulama teması ve yapılandırması
  core/         Ortak yardımcılar ve metin normalleştirme
  features/     Kayıt, profil, eşleşme, takas ve diğer özellikler
  preview/      Çevrimdışı ekran önizlemeleri
  widgets/      Ortak bileşenler ve maskot
functions/      Firebase sunucu işlemleri ve testleri
test/           Flutter testleri
integration_test/ Cihaz üzerinde bütünleşme testleri
doc/            Ürün kararları, teknik açıklamalar ve test kayıtları
gorevler/       Yayına hazırlık görevleri
```

## Proje belgeleri

- [Sıralı yayın görevleri](YAYIN_GOREVLERI.md)
- [Yayın yol haritası](YAYIN_YOL_HARITASI.md)
- [Telefon test ve kurulum rehberi](TELEFONDA_TEST.md)
- [Gerçek cihaz test matrisi](doc/21-yayin-test-matrisi.md)
- [Kullanıcı adı, QR ve fotoğraf akışları](doc/24-kullanici-adi-qr-ve-fotograf.md)
- [200 başlangıç tokenı](doc/27-baslangic-200-token.md)
- [Karşılıklı takas ve yanıt süresi](doc/28-karsilikli-takas-ve-zaman-asimi.md)
- [Sunucuda takas süreleri ve yayın kaydı](doc/29-sunucuda-takas-sureleri.md)

Belgeler geçmiş sürümlere ait kararlar da içerebilir. Takas zamanlaması için güncel karar 29 numaralı belgededir; eski APK bağlantıları en son kaynak kodunu içermeyebilir.
