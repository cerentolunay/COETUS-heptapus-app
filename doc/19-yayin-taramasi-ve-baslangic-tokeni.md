# Depo taraması ve başlangıç tokenı

## Mevcut kod ile canlı doğrulamanın ayrımı

- E-posta/şifre ve Google girişi: `firebase_auth_repository.dart` gerçek Firebase
  Auth kullanır. Gerçek cihazdaki OAuth, sertifika ve sağlayıcı ayarları ayrıca
  doğrulanmalıdır.
- Şifre sıfırlama: `forgot_password_page.dart` yalnızca `_sent` durumunu değiştirir;
  Firebase `sendPasswordResetEmail` çağrısı yoktu. Sonraki düzeltmede gerçek
  gönderim eklendi; güncel kurulum için `20-google-giris-ve-sifre-sifirlama.md` dosyasına bakın.
- Hesap silme: istemci `account_deletion_service.dart`, sunucu
  `functions/account_deletion.js` ve emülatör testleri vardır. `14-hesap-silme.md`
  canlı `deleteAccount` yayınının tamamlanmadığını bildirir; bu bir depo notudur,
  güncel canlı durumun kanıtı değildir.
- Bakiye değişiklikleri, özel sohbet erişimi, silinmekte olan hesapların yazmaları
  ve hediye tekrarları için `firestore.rules` ve emülatör testleri vardır. Bu,
  tüm üretim güvenliğinin denetlendiği anlamına gelmez; canlı kural/indeks sürümü
  ve gerçek cihaz davranışı ayrıca doğrulanmalıdır.
- Portföy şikâyeti `reportPortfolioEntry`, `contentReports` kaydı ve arayüzü vardır.
  Genel kullanıcı engelleme, sohbet/topluluk şikâyeti ve genel şikâyet yönetim
  ekranı bu taramada bulunmadı. İlgi alanı önerilerinin onay ekranı ayrıdır.
- Yönetici hesabına `interestModerator` yetkisi veren araç vardır; herhangi bir
  gerçek hesaba bu çalışma sırasında yetki atanmaz.

## Hesap başına bir kez 50 token

`WelcomeGiftService` giriş/kayıt akışında ve mevcut oturum geri yüklendiğinde
çalışır. E-posta ve Google hesapları aynı mekanizmayı kullanır. Profil önce güvenli
başlangıç bakiyesiyle oluşturulur; ardından bakiye artışı ve
`users/{uid}/rewards/welcome` makbuzu tek Firestore transaction'ında yazılır.

- Bakiyeye tam 50 eklenir; mevcut bakiye sıfırlanmaz.
- Daha önce makbuzu olmayan mevcut hesaplar da sonraki girişlerinde bir kez alır.
- Yeniden giriş, oturumun yenilenmesi ve eşzamanlı istekler ikinci ödeme yapmaz.
- Makbuz istemciden değiştirilemez/silinemez. Başka hesaba veya başka miktarda
  ödeme, makbuzsuz bakiye artışı, tek başına makbuz yazımı reddedilir.
- Kayıt sonrasında ağ hatası yaşanırsa başarıyla oluşturulmuş Auth hesabı silinmez;
  giriş tekrarı güvenli biçimde eksik işlemi tamamlayabilir.
- İlk eşleşme hediyesi ayrı bir makbuzla 20 token olarak korunur.
- Her UID için bir defalık ödüldür; aynı kişinin birden fazla hesap açmasını
  engelleyen bir kimlik/anti-abuse sistemi değildir.
- Hediye için Cloud Functions eklenmez. Canlıya yayın yapılmaz; güncel Firestore
  kuralları etkinleştirilmeden eski kurallar bu yeni hediyeyi reddeder.

Emülatör testleri bakiye korumayı, eşzamanlı girişleri, kötüye kullanımları,
silinmiş hesapları ve ilk eşleşme hediyesiyle toplamı kontrol eder. İlk 50 tokenın
30 tokenlık ilk oturumu fonlayabildiği ayrıca test edilir. Önizleme verileri gerçek
kullanıcı bakiyesinin kanıtı değildir.
