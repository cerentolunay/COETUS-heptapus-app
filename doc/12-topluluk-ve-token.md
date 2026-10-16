# Topluluk akışı ve token işlemleri

Keşfet ekranında eşleşme yuvarlağının altında topluluk akışı bulunur. Fotoğraf/video ve açıklama, yazarın öğrettiği bir yetenekle paylaşılır. Profil açma, kalp, yorum ve birlikte öğrenme teklifi ücretsizdir. Yalnızca hesaplanan eşleşmelerde uyum yüzdesi gösterilir; profil doğrulama rozeti sunucunun koruduğu kullanıcı kaydından okunur.

Token desteği isteğe bağlıdır. Kullanıcı 1, 3 veya 5 token seçer ve açıkça onaylar. Sunucu, kullanılabilir bakiyeden paylaşım sahibine tek bir transaction ile aktarır; aynı istek kimliği yeniden gönderilirse tekrar ücretlendirmez. Kendi paylaşımına destek verilemez.

Öğrenme teklifindeki bedel kullanıcıya gönderim onayında gösterilir. Teklif gönderildiğinde ödeme yapılmaz. Öğretmen kabul edince öğrenci bakiyesinden token kilitlenir. Öğrenci oturumun tamamlandığını ayrıca onaylayınca öğretmene aktarılır. İki taraf iptali onaylarsa token öğrenciye iade edilir. Yetersiz bakiye durumunda kabul ve kilitleme birlikte başarısız olur. Eski, fonlanmamış oturumlar için ödeme varmış gibi gösterilmez.

`communityPosts/{postId}` ve altındaki `likes`/`comments` sunucu tarafından yazılır. Yayımlanmış paylaşımlar giriş yapmış kullanıcılara açıktır. Silme sahibi tarafından yapılır; akıştan kaldırılır ve varsa medya temizlenir. Doğrulama kanıtları otomatik paylaşılmaz; paylaşım medyası ayrı `communityMedia/{uid}/{postId}/{filename}` yoluna yüklenir. Yayımlanmadan önce yalnızca sahibi okuyabilir. Fotoğraf sınırı 10 MB, video sınırı 50 MB'dir.

## Yayınlama

Kod ve kurallar yerelde hazırlanmıştır. Canlı proje için yetkili hesapla kök dizinden:

```powershell
.\functions\node_modules\.bin\firebase.cmd deploy --project coetus-bc9c6 --only functions:verification,firestore:rules,firestore:indexes,storage
```

`verification` bu projedeki Functions codebase adıdır; yeni topluluk ve oturum işlevlerini de içerir. Firestore bileşik indeksi yayımlanıp hazır olmalıdır. Functions ve Storage için projenin uygun faturalandırma planı ve servis kurulumu gerekir.

## Doğrulama

`functions/verification_emulator.test.js` içinde doğrulama özellikleriyle birlikte ücretsiz eylemler, yinelenen destek, bakiye yarışı, kilitleme, tamamlama, karşılıklı iade, özel medya ayrımı ve istemci yetkileri test edilir. Bu testler `demo-coetus` yerel emülatör projesinde çalışır. `test/community_learning_test.dart` teklifin açık onayını ve dar ekran davranışını denetler.
