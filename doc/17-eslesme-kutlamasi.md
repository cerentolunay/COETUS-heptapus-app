# Eşleşme kutlaması ve ilk eşleşme hediyesi

Kalbin çevresinden kırmızı/pembe pırıltı ve küçük kalpler farklı boyutlarda doğar;
uzaklaştıkça solup kaybolur. Kalp hafifçe atar. Sistem hareket azaltma ayarında
pırıltılar ve kalp hareketi durur; kalp görünmeye devam eder. Animasyon ekran
kapatılınca temizlenir.

Başlangıç hediyesi kişi başına bir kez 20 tokendır. Önizleme kartı bunu örnek
olarak gösterir ve gerçek bakiyeye yazmaz. Gerçek ekranda başarı mesajı yalnızca
Firestore işlemi başarıyla tamamlandıktan sonra görünür. Kontrol başarısızsa
tekrar deneme sunulur; daha önce alan kişiye tekrar hediye verilmez.

`users/{uid}/rewards/first_match` kaydı ve `users/{uid}.credits` artışı tek
transaction'da yazılır. Kurallar yalnızca gerçek kabul edilmiş, farklı iki kişi
arasındaki eşleşmenin katılımcısına tam 20 token verir. Ödül kaydı değiştirilemez
ve silinemez. Yalnızca bakiye yazmak, farklı miktar istemek, eşleşme uydurmak,
başkasının eşleşmesini kullanmak veya güven puanını değiştirmek reddedilir.
Tutar değiştirilecekse Dart sabiti ve Firestore kuralları birlikte güncellenmelidir.

Teklif kabulünden sonra kutlama açılır. Teklifi gönderen taraf kabul bildiriminden
kutlamaya ulaşır. Bu ödül kayıt/yetkilendirme işlemleri yeni Cloud Functions
kullanmaz; Firestore Spark kotasına tabidir. Ücretli plan etkinleştirilmez ve
canlı yayın bu değişikliğin parçası değildir.

Mevcut projenin `acceptLearningOffer` kabul/emanet-token akışı hâlâ Cloud Functions
çağırır. Dolayısıyla bu değişiklik bütün eşleşme altyapısını Spark uyumlu hâle
getirmez. Spark'ta uçtan uca canlı kullanım için o mevcut akışın ayrıca ele
alınması gerekir. Yerel doğrulama Firebase emülatörlerinde yapılır.
