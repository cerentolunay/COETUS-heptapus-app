# Yeni hesaplarda 200 başlangıç tokenı

19 Ekim 2026 ürün kararı: yeni hesapların ilk takaslara daha rahat katılabilmesi için başlangıç bakiyesi 200 token olur. Bu değişiklik takasta kilit tutarının hesaplanmasını, başarılı takasta sahibine iade kararını veya mevcut tek yönlü backend'in uygulamasını değiştirmez. İki kişinin de hem öğreten hem öğrenen olduğu karşılıklı modelin geliştirme işleri ayrı kalır.

## Ödül ve eski sürüm uyumluluğu

- Yeni uygulamanın oluşturduğu profil `signupRewardVersion: 2` taşır. Bu alan sonradan istemci tarafından değiştirilemez.
- Bu hesapta değiştirilemeyen `rewards/welcome` makbuzu ve 200 token artışı tek Firestore transaction ile yazılır. Yeniden giriş veya aynı anda gelen istekler ikinci hediye oluşturmaz.
- Yeni hesap ayrıca 20 token ilk eşleşme hediyesi alamaz. Eşleşme kutlaması hediye verilmiş gibi görünmez.
- Önceden 50 başlangıç tokenını almış kişiye 150/200 eklenmez, bakiye sıfırlanmaz. Eski makbuzlar korunur.
- Sürüm alanı olmayan eski profil/eski uygulama 50 başlangıç ve eski ilk eşleşme koşullarına tabi kalır. Bu, eski istemcinin kayıt akışını bozmadan geçiş içindir. Makbuzu olmayan eski hesapların önceki 50 token talep hakkı korunur; bunlara kendiliğinden 200 verilmez.
- Yeni 200 davranışı için yeni normal APK gerekir; eski APK ile açılan hesap otomatik olarak yeni ödül sürümüne taşınmaz. Kullanıcı hesaplarını topluca dönüştüren bir işlem yapılmaz.

Kayıt açıklaması ve çevrimdışı örnek hesap 200 token olarak güncellendi. Örnek bakiye gerçek cüzdan değildir. Mevcut seviye hesabının 100 token üst sınırı bu işte değiştirilmedi.

## Doğrulama ve yayın

175 Flutter testi, 39 yerel Auth/Firestore/Storage emülatör testi geçti; statik analiz temiz. Yeni testler 200 tokenın tek kez verilmesini, eşzamanlı talepleri, eski bakiyenin korunmasını, yanlış miktar/başkasının hesabı/sürüm değiştirme girişimlerini ve ek 20 token talebinin reddini kapsar.

Normal Android APK derlendi. Canlıda yalnızca Firestore kuralları yayımlandı; Functions, Storage ve indeks yayını veya plan değişikliği yapılmadı. Mevcut kurallar `.dart_tool/signup-200-rules-backup/` içine ayrı yedeklendi. Önceki release `f784dc2b-57e2-4dee-af85-03083ebb1b8f` idi. Gerçek kullanıcı cüzdanında ödül denemesi yapılmadı.

- Yeni canlı ruleset: `05f32334-d6ae-4b7b-b9ce-c3c8a1755ce1`.
- SHA-256: `5f2a0af1360b3e4f549dda4ea6bf602fe699a3546bb4f7df23c15106b8b3e09c`.
- 19 Ekim 2026, 20:37 Türkiye saati: sunucudaki içerik yerel kuralla birebir doğrulandı; diğer release’ler ve faturalandırma durumu değişmedi.
- Telefon kurulumu: bağlı Samsung SM-A336E üzerinde normal APK `install -r` ile başarıyla güncellendi ve açılış komutu başarıyla gönderildi. Cihaz testi veya uygulamayı kaldırma komutu çalıştırılmadı. Gerçek yeni hesap kaydı bu işlemde denenmedi; kurallar yerel emülatör ve canlı içerik eşleşmesiyle doğrulandı.
