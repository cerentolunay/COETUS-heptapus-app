# Kayıt, ilgi alanları ve beceri eşleştirme

- Kayıt ve profil tamamlama ekranlarında lime maskot hafif yükselip alçalır. Sistem hareket azaltma ayarı açıksa animasyon durur.
- Görünen ad dışında profil alanları isteğe bağlıdır. İşlevsiz “Daha sonra atla” kaldırılmıştır. İkinci ve son adımda birden fazla ilgi alanı açılıp alt beceriler seçilir. Hiçbir beceri seçmeden profil tamamlanabilir.
- Seçilen beceriler için “Öğrenmek istiyorum” ve/veya “Bu beceriyi paylaşabilirim” amacı belirlenir; paylaşılacak becerinin seviyesi seçilebilir. İlgi dalını kapatmak mevcut beceri seçimlerini silmez. Aynı beceri farklı dallarda tekrar seçilmez.
- Profilin tamamlanma bayrağı, ilgi alanları ve yeni beceriler tek Firestore batch'inde kaydedilir. Kayıt başarısızsa sayfadaki seçimler korunur. Boş hakkında alanı sonradan profili tekrar eksik duruma düşürmez.
- Büyük/küçük harf, Türkçe/ASCII harfler, birleştirici Türkçe işaretleri ve fazla boşluklar karşılaştırmada normalleştirilir. Python/PYTHON/python ve yazılım/yazilim aynı kabul edilir. Görünür metin değişmez. C++, C# ve Java/JavaScript ayrı kalır. Eski kayıtlara veri göçü gerekmez; eşleştirme okunan adları da normalleştirir. Belirli eski İngilizce adlar için sınırlı eş ad listesi vardır; genel çeviri veya yazım hatası tahmini yapılmaz.
- Konum butona basılınca izin ister. Yalnızca şehir/ülke etiketi profile yazılır. Koordinat veya canlı/arka plan konumu kaydedilmez. İzin reddi, kalıcı ret, kapalı konum servisi ve zaman aşımı halinde elle giriş veya boş bırakma mümkündür. Şehir tespiti Android/iOS içindir; diğer platformlarda elle giriş kullanılır.
- “Onay al” girişleri, kişi onayı ekranı ve onay sayısı rozetleri kaldırılmıştır. Eski istemcilerin `endorseTeaching` çağrısı da artık ödül veya güven puanı vermeyen bir hata döndürür. Geçmiş kayıtlar/bakiyeler silinmez. Oturum tamamlama ve token aktarımı bu özellikten ayrıdır, korunur.
- Toplulukta ve portföyde paylaşma, yorum, kalp ve isteğe bağlı token desteği korunur. Telefon numarası alanı eklenmemiştir.

## Kontroller

Flutter davranış testleri ve Firebase emülatör testleri çalıştırılır; Android ARM64 debug APK derlenir. Gerçek GPS izin penceresi fiziksel Android/iOS cihazda ayrıca kontrol edilmelidir; iOS derlemesi Windows ortamında çalıştırılmamıştır.

Bu dal inceleme içindir. Canlı sunucuya yayımlanmamıştır; PR birleştirilmeden ve yayın yapılmadan eski canlı onay işlevi değişmez.

## Ortak ilgi alanı ekranı

Girişteki keşfet ekranı ve profil tamamlamanın ikinci adımı aynı `InterestTree`
bileşenini kullanır. Ana alanlar iki sütunlu kartlardır; karta dokununca o satırın
altında beceri dalları açılır. Birden fazla alan açılabilir. Dalı kapatmak seçilen
becerileri veya öğrenme/paylaşma amaçlarını silmez. Ekle/öneri ve yönetici onayı
iki girişte de aynı katalog üzerinden çalışır.

Girişteki seçimler, profil henüz tamamlanmamışsa profil formuna `initialSelection`
olarak taşınır; son kayıtta ilgi alanı kimlikleri ve gerçek alt beceriler birlikte
kaydedilir. Örneğin Müzik → Gitar seçiminde genel Müzik adı öğrenme becerisi olarak
kaydedilmez. Profili tamamlanmış kullanıcıda mevcut profil bilgileri korunarak
seçimler kaydedilir. Önizlemede yalnızca yerel örnek beceri kayıtları güncellenir.
