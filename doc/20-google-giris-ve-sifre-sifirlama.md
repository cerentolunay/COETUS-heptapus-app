# Google girişi ve şifre sıfırlama

## Yapılan düzeltmeler

- Şifre sıfırlama formu gerçek `FirebaseAuth.sendPasswordResetEmail` çağırır.
  Türkçe e-posta dili ayarlanır; gönderim sürerken tekrar basılamaz. Hatalar formda
  kalır. Başarı metni hesabın varlığını açıklamayan koşullu bir mesajdır.
- Önizleme modunda gerçek e-posta gönderilmez; açık bir uyarı gösterilir.
- Google girişindeki native hesap seçimi kullanıcı beklerken 15 saniyede kesilmez.
  Ağ/kimlik bilgisi işlemlerindeki mevcut süre sınırları korunur.
- Android `ApiException: 10`, kapalı sağlayıcı, iptal, ağ ve giriş sonrasındaki
  Firestore izin hataları ayrı mesajlarla gösterilir. Sağlayıcı ve sertifika
  ayarlarının doğru olduğu bu kod değişikliğinden çıkarılamaz.

## Firebase Console: kullanıcı tarafından yapılacaklar

1. `coetus-bc9c6` projesi → Authentication → Sign-in method / giriş sağlayıcıları.
   Email/Password ve Google sağlayıcılarını etkinleştirip kaydedin. Google için
   proje destek e-postasını seçin.
2. Android uygulaması `com.heptapus.coetus` için telefondaki APK'yı imzalayan
   sertifikanın SHA-1 ve SHA-256 değerlerini Project settings → Your apps altında
   ekleyin. Geliştirme bilgisayarında `cd android` ardından `./gradlew signingReport`
   (Windows: `.\gradlew.bat signingReport`) ile kullanılan anahtarı kontrol edin.
   Play dağıtımında Play Console'un app signing sertifikası da ayrıca gerekir.
3. Güncel `google-services.json` dosyasını indirip `android/app/` altındaki dosyayla
   değiştirin. Uygulamayı normal `lib/main.dart` girişinden yeniden derleyin;
   sadece hot reload yeni yerel OAuth yapılandırmasını uygulamaz.
4. iOS için mevcut Firebase plist dosyasında CLIENT_ID / REVERSED_CLIENT_ID ve
   Info.plist'te Google dönüş URL şeması yok. Sağlayıcı ayarlarından sonra güncel
   iOS yapılandırmasını indirin; Google Sign-In iOS kurulumuna göre CLIENT_ID ve
   ters client ID URL şemasını ekleyin. Başka platformun client ID'sini uydurmayın.
5. Authentication → Templates bölümünde şifre sıfırlama şablonunu inceleyin;
   gerekiyorsa uygulama adı/destek e-postasını düzenleyin. Adres ve proje eşleşmeli.
6. Yeni 50 token akışı için güncel `firestore.rules` da etkin olmalı. Google hesabı
   doğrulandığı hâlde profil/token izni reddedilirse sorun OAuth'tan farklıdır.

ÖNİZLEME · ÇEVRİMDIŞI etiketi olan sürüm gerçek Google hesabına bağlanmaz;
önizlemenin yerel örnek hesabı gerçek giriş testi değildir. Bu iki Auth özelliği
Cloud Functions eklenmesini gerektirmez; Auth hizmetinin kendi kotaları geçerlidir.
Bu çalışmada sağlayıcı ayarları, SHA kayıtları ve canlı kurallar değiştirilmedi;
gerçek e-posta gönderilmedi, gerçek Google hesabıyla oturum açılmadı.

## Doğrulama

Flutter testleri gerçek e-posta göndermeden form doğrulamasını, bekleme ve tekrar
basma engelini, gönderim hatasında yeniden denemeyi ve Google hata ayrımını kontrol
eder. Fiziksel cihazda hem e-posta hesabı hem Google hesabı ayrıca denenmelidir.
