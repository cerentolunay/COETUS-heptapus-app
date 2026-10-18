# Hesabını sil

Profilde “Çıkış Yap” düğmesinin altında “Hesabını sil” bulunur. Kalıcı silme ve kalan tokenların kaybı için açık onay gerekir. E-posta/şifre hesabında şifre yeniden doğrulanır; Google hesabında aynı Google hesabıyla doğrulama yapılır. Sunucu son beş dakika içinde yapılmış doğrulamayı zorunlu tutar ve istemciden hedef kullanıcı kimliği kabul etmez.

Silme isteği önce sunucuda kilitlenir. Kullanıcının taraf olduğu kilitli escrow veya kilitli bakiyesi varsa işlem başlamaz. Silme kilidi sonrasında Firestore/Storage yazmaları ve sunucu işlemleri engellenir; karşı tarafın token göndermesi ya da yeni oturum fonlaması da bu hesap için reddedilir. Eski ID tokenı profilin tekrar oluşturulmasını sağlamaz.

Auth hesabı kapatılır; profil ve alt koleksiyonları, kullanıcının paylaşımları ve portföyü, yazdığı yorumlar/kalpler, kişisel medya yüklemeleri ve bildirimleri temizlenir. Başkalarının paylaşımlarındaki yorum/kalp sayaçları düzeltilir. Ortak sohbetlerde kişinin kendi mesajları kaldırılır, adı “Silinmiş hesap” yapılır; diğer kişinin mesajları korunur. Ortak oturumlar ve token işlem kayıtları, kişisel adlar kaldırılarak tutulur. Geçmiş kayıtlarda ilişkilendirme için anonim/opak kullanıcı kimliği kalabilir; diğer kişinin yazdığı metinler genel olarak silinmez.

Temizleme idempotenttir. Yönetim konsolundan doğrudan Auth silinerek uygulama kilit kontrolü atlanırsa arka plan temizliği de kilitli oturumları kontrol eder ve cüzdan verilerini korur; yönetici bu oturumları sonuçlandırmalıdır. Auth kullanıcısı silindikten sonra veri temizliği yarıda kalırsa `cleanupDeletedAccount` Auth onDelete tetikleyicisi yeniden dener. `accountDeletions/{uid}` tamamlanma kaydı kişisel ad/e-posta/şifre içermez ve eski oturumun yazmalarını engellemek için korunur. Bu koleksiyona istemciler yazamaz. Şifre yalnızca Firebase kimlik doğrulamasına verilir; callable isteğine veya Firestore'a eklenmez.

## Yayın sırası

18 Ekim 2026: Kullanıcının ek ücret doğurabilecek işlemleri durdurma isteği nedeniyle canlı yayın tamamlanmadı. Firestore/Storage kuralları ve gerekli indeksler yayımlandı. Mevcut 13 callable işlevinin güncellemeleri ve `cleanupDeletedAccount` Auth tetikleyicisi Google tarafında tamamlanarak ACTIVE durumuna geçti. `deleteAccount` callable işlevi yayımlanmadı; bu yüzden telefondaki hesap silme düğmesi henüz gerçek silme yapamaz. Gerçek kullanıcı hesabı silinmedi.

Cloud Functions dağıtımı ve kullanımı sıfır maliyet garantisi vermez. Ek ücret riski taşıyan yeni yayın yapılmayacak; geliştirme ve testler yerel emülatörlerde sürdürülecek. Yayın komutunu durdurmak daha önce Google'a gönderilen işlemleri geri almaz ve mevcut bulut kaynaklarını kapatmaz. Fatura tutarı bu kontrol kapsamında doğrulanmadı.

İleride sunucu yayını ayrıca yetkilendirilirse önce collection-group indeksleri, güvenlik kuralları, hesap silme korumaları ve Auth tetikleyicisi doğrulanmalı; `deleteAccount` en son yayımlanmalıdır. Yalnızca APK güncellemek yeterli değildir. PR birleştirilmedi.

## Test

Gerçek hesaba dokunulmadan yerel Auth/Firestore/Storage emülatörleri kullanılır:

```powershell
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --project demo-coetus --config firebase.emulators.json --only firestore,storage,auth "node --test functions/verification_emulator.test.js"
flutter test
```

Açık onay, yeni kimlik doğrulaması, kilitli oturumun engellenmesi, başka kullanıcıyı hedefleyememe, Auth/veri/medya temizliği, tekrar çalıştırma, eski tokenın engellenmesi ve eşzamanlı token kilitleme senaryoları test edilir. Google'ın gerçek hesap seçimi fiziksel cihazda ayrıca denenmelidir.
