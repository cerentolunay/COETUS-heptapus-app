# Karşılıklı takas ve yanıt süresi

İki kişi de öğretir ve öğrenir. Yeni teklifler iki yöndeki becerilerin eşleşmesini gerektirir. Öğrenilen becerinin seviyesi 1–7 için kişinin katkısı 10–70 tokendır; iki katkının eşit olması gerekmez. Teklifteki beceriler ve tutarlar sabitlenir. Kabul sırasında iki kişinin katkısı tek atomik işlemle kilitlenir; yetersiz bakiye varsa ikisinden de kesilmez.

## Tamamlanma, iptal ve itiraz

- İki ayrı tamamlanma onayı: başarılı takas; herkes kendi kilitli katkısını geri alır.
- İki ayrı iptal onayı: iptal; herkes kendi kilitli katkısını geri alır.
- İlk tamamlanma onayından 24 saat sonra tek hatırlatma kaydı oluşturulur.
- İlk tamamlanma onayından 72 saat sonra itiraz yoksa durum **Yanıt süresi doldu** olur. Herkesin kendi katkısı iade edilir. Bu durum başarılı takas, öğretme/öğrenme geçmişi veya yetenek onayı sayılmaz.
- Diğer kişi süre dolmadan **Takas tamamlanmadı** diyerek gerekçe yazabilir. İtiraz ve tamamlanma isteğinden sonraki iptal talebi otomatik kapanmayı durdurur. Karşılıklı iptal hâlâ mümkündür. Tek taraflı itiraz çözümü veya yönetici karar mekanizması bu sürüme dahil değildir.

Örnek: A'nın 60, B'nin 40 tokenı kilitlendiyse kapanışta A'ya 60, B'ye 40 döner. Yeni token üretilmez ve kişiler arasında aktarılmaz. Terminal oturum kaydı ve sabit katkı haritası işlem kaydıdır; tekrar çağrılar ikinci iade oluşturmaz.

## Zamanlama ve güvenlik

Functions, zamanlayıcı ve arka plan push eklenmedi. Süreler Takaslarım ekranındaki mevcut veri akışıyla, ekran açıkken ve uygulama yeniden öne geldiğinde kontrol edilir. İki uygulama da kapalıysa 24/72. saatte işlem yapılacağı garanti edilmez; bir sonraki ekran kontrolünde uygulanır. Firestore kuralları sunucu saatini doğrular; telefon saatini ileri almak erken iade sağlamaz.

Yeni oturumlar `schemaVersion: 2` kullanır. Eski tek yönlü Functions kabul/tamamlama/iptal işlemleri yeni oturumları işleyemez. Önceden fonlanmış eski oturumlar otomatik taşınmaz veya iade edilmez; yeni arayüz eski mali işlemleri çalıştırmaz. Eski kayıtlar için ayrı geçiş planı gerekir.

## Doğrulama

- 181 Flutter testi başarılı.
- 49 Firebase emülatör testi başarılı: karşılıklı katkı, yetersiz bakiye, iki onay, 24/72 saat sınırları, itiraz, tekrar çağrılar, yetkisiz/tek taraflı cüzdan değişiklikleri ve eski Functions izolasyonu.
- Canlı yayın kapsamı yalnızca Firestore kurallarıdır; Functions/Storage yayını ve plan değişikliği yapılmaz.
- Statik analiz temiz; normal Android debug APK derlendi. Kontrol sırasında USB cihazı bulunmadığından telefona kurulmadı.
- Firestore kuralları 19 Ekim 2026 tarihinde yayımlandı ve içerik eşitliği doğrulandı: `807b05be-8f99-4d92-a9a9-b621582ab8f1`. Diğer kural yayınları ve mevcut faturalandırma durumu değişmedi.
