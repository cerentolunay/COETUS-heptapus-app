# Düşük yükle canlı yayın — 19 Ekim 2026

Kullanıcı, mevcut planın korunmasını; yalnızca Functions’sız değişiklikler ve Firestore kurallarının yayımlanmasını; fotoğraf/Storage ve Functions yayınının beklemesini seçti.

## Uygulama değişiklikleri

- Sohbet başlığı tüm sohbet koleksiyonunu dinlemek yerine yalnızca açık sohbet belgesini dinler.
- Sohbet başlığı/mesajları ile sohbet listesi dinleyicileri klavye, arama ve sekme değişimlerinde yeniden oluşturulmaz. Hesap/sohbet değişirse ilgili akış yenilenir.
- Sohbet belgelerinde eksik olan katılımcı adları aynı repository ömründe yeniden okunmaz. Hatalı okumalar önbellekten çıkarılır ve yeniden denenebilir. Başka bir kullanıcının e-postası ad yerine gösterilmez.
- Kullanıcı adı ve QR akışları Firestore transaction/kurallarıyla çalışır. Kalp ve animasyonlar ek sunucu isteği oluşturmaz.

Firestore kullanımı sıfırlanmadı. İlk veri yükleme, profil arama, canlı mesajlaşma, kurallardaki belge kontrolleri ve yazmalar hâlâ kota tüketir. Eski uzun sohbetlerin tamamını yükleme davranışı bu değişiklikte değiştirilmedi; mesaj geçmişi ve 100/1000 mesaj kalbi eksiltilmedi.

## Sınır ve yayın kaydı

- Proje: `coetus-bc9c6`.
- Faturalandırma ön kontrolde zaten açıktı. Plan, faturalandırma hesabı ve ücretli hizmet ayarları değiştirilmez. Mevcut Blaze projesinde kota üstü kullanım için sıfır ücret garantisi verilmez.
- Yayımlanan kapsam: yalnızca `firestore:rules`. Index, Storage ve Functions yayını yapılmadı; yeni servis açılmadı.
- Önceki Firestore ruleset: `b2f447b4-653e-468e-83be-3e3ae9ebb65c`. Kaynak ve release metadatası `.dart_tool/live-rules-backup/` içine yedeklendi.
- Yeni kuralların SHA-256 değeri: `8b300c539570e331861c03de05c227b492ef68042c0b2248a23b65577b974150`.
- Canlı release: `projects/coetus-bc9c6/rulesets/f784dc2b-57e2-4dee-af85-03083ebb1b8f`.
- İçerik doğrulama: 19 Ekim 2026, 19:39 Türkiye saati. Sunucudan okunan kural içeriği yerel dosyayla birebir aynı; Firestore dışındaki release'ler ve faturalandırma durumu ön kontrolle aynı.
- Yayın komutu: `firebase deploy --only firestore:rules --project coetus-bc9c6 --account heptapusgroup@gmail.com --non-interactive`.

Fotoğraf yükleme kuralları ve yeni/yenilenmiş Functions kodu canlıya alınmaz. Önceki Functions’a bağlı portföy, topluluk, token ve hesap silme akışlarının tamamlandığı iddia edilmez. Gerçek token/oturum/hesap üzerinde deneme yapılmaz. Yeni QR tanışması ödül veya token aktarımı yapmaz.

## Kontroller

175 Flutter testi ve 37 yerel Auth/Firestore/Storage emülatör testi geçti; statik analiz temiz. Yeni testler, klavye değişiminde aynı mesaj ve başlık dinleyicilerinin korunduğunu, açık sohbet değişiminde doğru akışın açıldığını ve liste arama/sekme değişiminin yeni sorgu başlatmadığını doğrular. Normal `lib/main.dart` Android debug APK derlendi; telefon bağlı görünmediği için bu son paket henüz kurulmadı. Play Store veya uygulama mağazası yayını yapılmadı.
