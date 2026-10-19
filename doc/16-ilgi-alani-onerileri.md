# İlgi alanı önerileri

Keşfet ve profil tamamlama ekranları ortak katalog kullanır. Profil ekranındaki
“İlgi alanlarını keşfet” düğmesiyle kayıt sonrasında da erişilebilir. Hayvan bakımı, tarih,
strateji ve bilgisayar oyunları, seyahat, doğa, kamp, bahçecilik, DIY, dijital içerik
üreticiliği, finans/yatırım ve astroloji eklendi; anime ve psikoloji korundu,
mutfak gastronomi ve yemek yapımı olarak genişletildi.

Ekle → öneriyi gönder → yönetici incelemesi → onay veya ret.
`interestSuggestions` kayıtları beklerken yalnızca sahibine ve moderatöre görünür.
Onaylananlar iki ekranda da canlı listeye eklenir. Kullanıcı kendi önerisini
onaylayamaz, güncelleyemez; aynı adla tekrar gönderim aynı belgeye gider ve reddedilir.
Önizleme gerçek Firebase'e öneri göndermez.

Onay yetkisi ayrı `interestModerator` custom claim'i ile korunur. Güvenilir bir
Firebase Admin ortamında, doğru hesap UID'siyle:

```
cd functions
node grant_interest_moderator.js <firebase-user-uid>
```

Bu işlem Application Default Credentials gerektirir. Anahtarları uygulamaya veya
depoya koymayın. Yetki verildikten sonra çıkış/giriş yapın. İki ilgi alanı ekranındaki
“Önerileri incele” düğmesi bekleyen önerileri ve Onayla/Reddet işlemlerini açar.
Yetki hiçbir kullanıcıya otomatik verilmez. Firebase rules yayını ayrıca gerekir;
bu çalışma canlıya yayın yapmaz.

Hesap silme sahibin önerilerini de temizler. Başka kullanıcıların seçtiği beceriler
silinmez. Emülatör testleri bekleyen önerilerin gizliliğini, yetkisiz yayınlamayı,
onayı, reddi ve sonradan değiştirme yasağını doğrular.
