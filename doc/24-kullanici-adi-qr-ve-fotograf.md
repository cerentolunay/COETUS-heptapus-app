# Kullanıcı adı, QR ve fotoğraf paylaşımı

Kayıtta ad üzerinden kullanıcı adı önerilir. Türkçe karakterler ve büyük/küçük harfler aynı kanonik ada dönüştürülür. Kullanıcı profilinden adını değiştirebilir. Firestore işlemi profil ile kullanıcı adı rezervasyonunu birlikte yazar; eski adlar aynı hesaba ayrılmış olarak pasif kalır. Liste halinde kullanıcı adı dizini okunamaz.

Profilin üstünde QR ve yuvarlak “Birbirinizi bulun” ikonu vardır. Kullanıcı adı araması ve uygulama içi QR okuyucu aynı profil bulma ekranını açar. QR yalnızca sabit profil kimliğini taşır; ödeme komutu içermez. Her iki kişi kendi hesabından tanışmayı onaylayınca bir sohbet açılır. Bu akış token üretmez, transfer etmez ve ilk eşleşme hediyesini talep etmez. Yüz yüze token kazanma tutarı ve sınırı henüz kararlaştırılmadı.

Yeni kullanıcı adı ve QR akışları Cloud Functions kullanmaz; Firestore transaction ve güvenlik kurallarıyla çalışır. Bu değişiklik, uygulamanın mevcut portföy/topluluk/token/hesap silme servislerinin Functions bağımlılığını kaldırmaz. Bunların kapsamı ayrıca netleştirilmelidir; istemciye serbest bakiye yazma izni verilmemiştir.

Sohbette karşılıklı 50’şer metin mesajından sonra dolu, 500’er mesajdan sonra pırıltılı kalp gösterilir. Mesaj göndermeye üst sınır konulmaz ve token harcanmaz. Hesaplama zaten dinlenen mesajlar üzerinden yapılır.

Profil düzenlemeden mevcut ilgi alanı ağacı açılır; mevcut beceriler korunur ve geri dönüldüğünde profil formu açık kalır. Açılan alanlarda “Ekle” ile kişisel beceri eklenebilir. Eşdeğer yazımla yinelenen beceri engellenir.

Çalışmalarım’daki “İlgili yetenek” etiketi seçim kutusunun üzerinde sabittir. Çalışmalarım ve topluluk paylaşımları yalnızca fotoğraf seçer; video seçimi, oynatıcı, oynatıcı bağımlılığı ve iOS mikrofon açıklaması kaldırılmıştır. Yeni yüklemeler JPG/PNG/WebP ve en fazla 10 MB ile sınırlandırılır. Eski video dosyaları silinmez; uygulama bunları açmaz veya oynatmaz.

## Yayın durumu

İlk geliştirme sırasında canlı Firebase yayını yapılmamıştı. 19 Ekim 2026’da kullanıcı onayıyla yalnızca Firestore kuralları yayımlandı; kullanıcı adı/QR işlemlerinin kuralları artık canlıdır. Storage/fotoğraf ve Functions yayını bekliyor. Plan değiştirilmedi ve ücretli hizmet açılmadı. Önizleme ekranları yerel örneklerle çalışır. Ayrıntılı yayın kaydı: [Düşük yükle canlı yayın](26-dusuk-yuklu-canli-yayin.md). İlgili kaynak dalları henüz main ile birleştirilmedi.

## Kontroller

168 Flutter testi ve 37 yerel Auth/Firestore/Storage emülatör testi geçti. İki medya politikası testi geçti; statik analiz temiz. Ekran yerleşimi, normalizasyon, QR, kalp, ilgi alanları, kullanıcı adı yarışları, çift taraflı tanışma onayı, yetkisiz bakiye değişikliği ve video yüklemeyi reddetme kapsanır. Normal Android debug APK derlendi. Canlı kullanıcı hesabında deneme yapılmadı; kontrol sırasında bağlı telefon görünmediği için telefona kurulmadı.
