# Hesabını sil

Profilde “Çıkış Yap” düğmesinin altında “Hesabını sil” bulunur. Kalıcı silme ve kalan tokenların kaybı için açık onay gerekir. E-posta/şifre hesabında şifre yeniden doğrulanır; Google hesabında aynı Google hesabıyla doğrulama yapılır. Sunucu son beş dakika içinde yapılmış doğrulamayı zorunlu tutar ve istemciden hedef kullanıcı kimliği kabul etmez.

Silme isteği önce sunucuda kilitlenir. Kullanıcının taraf olduğu kilitli escrow veya kilitli bakiyesi varsa işlem başlamaz. Silme kilidi sonrasında Firestore/Storage yazmaları ve sunucu işlemleri engellenir; karşı tarafın token göndermesi ya da yeni oturum fonlaması da bu hesap için reddedilir. Eski ID tokenı profilin tekrar oluşturulmasını sağlamaz.

Auth hesabı kapatılır; profil ve alt koleksiyonları, kullanıcının paylaşımları ve portföyü, yazdığı yorumlar/kalpler, kişisel medya yüklemeleri ve bildirimleri temizlenir. Başkalarının paylaşımlarındaki yorum/kalp sayaçları düzeltilir. Ortak sohbetlerde kişinin kendi mesajları kaldırılır, adı “Silinmiş hesap” yapılır; diğer kişinin mesajları korunur. Ortak oturumlar ve token işlem kayıtları, kişisel adlar kaldırılarak tutulur. Geçmiş kayıtlarda ilişkilendirme için anonim/opak kullanıcı kimliği kalabilir; diğer kişinin yazdığı metinler genel olarak silinmez.

Temizleme idempotenttir. Yönetim konsolundan doğrudan Auth silinerek uygulama kilit kontrolü atlanırsa arka plan temizliği de kilitli oturumları kontrol eder ve cüzdan verilerini korur; yönetici bu oturumları sonuçlandırmalıdır. Auth kullanıcısı silindikten sonra veri temizliği yarıda kalırsa `cleanupDeletedAccount` Auth onDelete tetikleyicisi yeniden dener. `accountDeletions/{uid}` tamamlanma kaydı kişisel ad/e-posta/şifre içermez ve eski oturumun yazmalarını engellemek için korunur. Bu koleksiyona istemciler yazamaz. Şifre yalnızca Firebase kimlik doğrulamasına verilir; callable isteğine veya Firestore'a eklenmez.

## Yayın sırası

Bu değişiklik mevcut PR'ın parçasıdır ve canlıya yayımlanmamıştır. Profildeki düğmenin gerçekten işlem yapabilmesi için sunucu yayını gerekir. Önce `firestore.indexes.json` içindeki yorum/kalp collection-group indekslerinin hazır olduğundan emin olun; ardından kurallar ve yeni `deleteAccount`/`cleanupDeletedAccount` işlevleri ile hesap silme korumaları birlikte yayımlanmalıdır. Yalnızca istemci APK'sını güncellemek yeterli değildir. Auth silme tetikleyicisi v1, callable v2 işlevdir; mevcut Node.js 22 codebase içinde tanımlıdır.

## Test

Gerçek hesaba dokunulmadan yerel Auth/Firestore/Storage emülatörleri kullanılır:

```powershell
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --project demo-coetus --config firebase.emulators.json --only firestore,storage,auth "node --test functions/verification_emulator.test.js"
flutter test
```

Açık onay, yeni kimlik doğrulaması, kilitli oturumun engellenmesi, başka kullanıcıyı hedefleyememe, Auth/veri/medya temizliği, tekrar çalıştırma, eski tokenın engellenmesi ve eşzamanlı token kilitleme senaryoları test edilir. Google'ın gerçek hesap seçimi fiziksel cihazda ayrıca denenmelidir.
