# Profil fotoğrafı seçimi

Profili düzenle ekranındaki bağlantı alanı kaldırıldı. “Profil fotoğrafı ekle” bölümünden galeriden fotoğraf seçilebilir veya kamera açılabilir. Seçim önizlenir; iptal etmek mevcut fotoğrafı değiştirmez. Yükleme yalnızca “Profili Güncelle” ile başlar. Kendi profilinin baş harf alanı da kaydedilen fotoğrafı gösterir.

Görseller seçim sırasında en fazla 1024×1024 boyutuna ve yüzde 80 kaliteye indirilir. JPG/PNG/WebP ve 5 MB sınırı uygulanır. Kamera/galeri izni veya yükleme hatasında mevcut profil fotoğrafı korunur. Profil kaydı başarısız olup tekrar denendiğinde başarılı yükleme tekrar kullanılabilir. Android'in kamera sırasında uygulamayı kapatması durumunda, düzenleme ekranı tekrar açılınca ImagePicker'ın kurtarılabilir seçimi alınır.

Önizlemede fotoğraf yalnızca bellek içindeki örnek profil için data URI olarak tutulur. Normal uygulamada dosya `profilePhotos/{uid}/{benzersiz-dosya}` alanına yüklenir ve profil belgesine indirme adresi kaydedilir. Eski, bu kullanıcıya ait profil fotoğrafı yeni profil başarıyla kaydedildikten sonra en iyi çabayla temizlenir; başka depodaki veya başka kullanıcıya ait dosyalar silinmez.

## Canlı durum

Ek ücret doğurabilecek işlem yapılmaması isteği nedeniyle **canlı Firebase yayını yapılmadı**. Yeni Storage yolu için kurallar ve hesap silme sırasında `profilePhotos/{uid}/` temizliği kodda hazırdır, yerel emülatörde doğrulanmıştır. Canlı Storage kuralları profil fotoğrafını henüz kabul etmez; gerçek yükleme izin hatası verebilir. Bu durumda uygulama fotoğrafın kaydedilmediğini açıkça gösterir. Fotoğraf seçme/önizleme ve diğer profil alanlarını fotoğraf seçimi iptal edildikten sonra kaydetme kullanılabilir.

Kalıcı yüklemeyi etkinleştirmek için mevcut ücret kısıtı gözetilerek Firebase depolama ve yayın kapsamı ayrıca netleştirilmelidir. Sunucu yayını ile satın alma veya plan yükseltme otomatik yapılmaz. iOS izin açıklamaları güncellenmiştir; Windows ortamında iOS derlemesi yapılmamıştır.

## Doğrulama

- 155 Flutter testi geçti: galeri/kamera kaynağı, iptal, izin reddi, yükleme hatası, aynı yüklemeyle kayıt tekrarı ve önceki ekran testleri.
- 33 yerel Auth/Firestore/Storage emülatör testi geçti: sahiplik, anonim erişim reddi, boyut/tür sınırı, üzerine yazma yasağı ve hesap silmede yalnızca ilgili kullanıcının medyasının temizlenmesi dahil.
- Canlı kullanıcı fotoğrafı yüklenmedi veya silinmedi.
