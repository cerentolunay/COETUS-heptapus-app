# Sunucuda karşılıklı takas süreleri

Bu karar, 28 numaralı belgedeki yalnızca ekran açıkken süre kontrolü kısıtını kaldırır. Kullanıcı Blaze üzerinde Functions kullanımına ve gerekli bağlantılı servislere izin verdi. Storage/portföy yayını ve plan değişikliği bu işin kapsamına girmez.

## Davranış

İlk tamamlanma onayı 24/72 saatlik süreyi başlatır; yalnızca eşleşmek süreyi başlatmaz. İki kişi de öğretir ve öğrenir. Örneğin A'nın 60, B'nin 70 tokenı kilitliyse, itirazsız süre dolumunda A'ya 60, B'ye 70 iade edilir. Sessizlik başarılı takas, yetenek onayı veya yeni token ödülü değildir.

`syncMutualExchangeTimeout` oturum değişikliklerinde güncel kaydı tekrar okur ve sunucuya özel `exchangeTimeoutJobs` kuyruğunu günceller. `processMutualExchangeTimeouts` tek Cloud Scheduler göreviyle 15 dakikada bir yalnızca zamanı gelen kuyruk kayıtlarını sorgular. İlk aşamada bir uygulama içi hatırlatma kaydı oluşturur; ikinci aşamada iki cüzdanı ve oturumu tek transaction içinde kapatır. Telefonların açık olması gerekmez. Bildirim uygulama içi kayıttır; arka plan telefon push bildirimi eklenmemiştir.

Normal koşullarda işlem eşikten sonraki ilk 15 dakikalık kontrolde uygulanır; servis hataları, tekrar denemeler ve kuyruk yoğunluğu geciktirebilir. Tam saat garantisi yoktur. Her çalıştırma en çok 500 kayıt işler. Boş kuyrukta tek sorgu vardır; tüm oturumlar periyodik taranmaz.

İtiraz veya tamamlanma sonrası iptal isteği kuyruğu durdurur. İkinci tamamlanma/iptal onayıyla kapanmış oturum yeniden iade edilmez. Eski ve tekrar gelen trigger olayları güncel oturumu okuyarak karara bağlanır. Eşzamanlı telefon ve sunucu işlemleri aynı Firestore transaction çatışma kontrolünden geçer. Bozuk cüzdan veya tutar varsa iki kişiden hiçbirine kısmi iade yapılmaz; hata günlüğe kaydedilir ve iş silinmez.

Eski tek yönlü oturumlar otomatik dönüştürülmez. Kuyruğa istemciden yazılamaz; mevcut varsayılan Firestore reddetme kuralı geçerlidir. İlk yayın öncesinden kalan, ilk onayı verilmiş v2 oturumlar için yalnızca kuyruk kaydı ekleyen geçiş kontrolü gerekir; bakiye değiştirilmez.

## Kullanım ve ücret

İki yeni Functions, tek Scheduler görevi, sıfır sıcak instance ve her işlev için en fazla bir instance yapılandırıldı. Bunlar harcama üst sınırı sağlamaz. Ücretsiz kotalar servis bazındadır; Functions dışında Scheduler, Firestore, Cloud Build ve Artifact Registry de değerlendirilir. Scheduler'ın hesap genelindeki üç ücretsiz görevi başka projelerle paylaşılır. Blaze planında sıfır ücret garantisi yoktur.

Resmî kaynaklar: [Firebase fiyatları](https://firebase.google.com/pricing), [Scheduler açıklaması](https://firebase.google.com/docs/functions/schedule-functions).

## Testler

181 Flutter testi ve 54 Firebase emülatör testi geçti. Yeni testler sunucunun uygulama açılmadan hatırlatması/iade etmesi, eşzamanlı tekrar çağrılarda tek iade, itiraz ve iptal sonrası eski kuyruk kaydının reddi, bozuk cüzdanda atomik geri alma ve istemcilerin kuyruk oluşturamamasını kapsar. İlk tam çalıştırmada eski destek işlemi testinde emülatör transaction hatası görüldü; ikinci tam çalıştırma 54/54 geçti. Statik analiz temiz, normal Android APK derlendi. Telefon USB listesinde görünmediği için bu sürüm cihaza kurulmadı.

İlk geçiş kontrolünde canlıda v2 oturum bulunmadı; kuyruk veya cüzdan değişikliği yapılmadı. Artifact Registry için önerilen yedi günlük temizleme politikası otomatik onay denetimi tarafından eski imajları/geri alma seçeneklerini silebileceği gerekçesiyle reddedildi. Politika değiştirilmedi.

## Canlı yayın

19 Ekim 2026 tarihinde iki yeni işlev `ACTIVE` olarak doğrulandı. Scheduler etkin ve aralığı `every 15 minutes`; her işlevin azami instance sayısı 1. Önceki bütün işlevlerin kod hashleri ve Firestore kural sürümü değişmedi. Storage veya portföy işlevleri yayımlanmadı. Yeni Eventarc servis hesabının ilk kurulumunda izin yayılma hatası alındı; tekrar denemeden sonra işlev etkinleşti.

CLI'nin `--force` ile varsayılan imaj temizleme politikası oluşturabildiği fark edilince yayın istemcisi bu adımdan önce durduruldu. Google tarafında başlamış işlev oluşturma işlemi tamamlandı; canlı işlevler ve Scheduler ayrıca API'den doğrulandı. Mevcut Artifact Registry politikasına yazılmadı.

Scheduler elle bir kez çalıştırıldı; `2026-10-19T19:38:24.820443Z` son denemesi durum kodu 0 ile doğrulandı. Ek HTTP istek günlüğü kontrolü Logging API'nin 429 yanıtı nedeniyle doğrulanamadı; canlıda yapay kullanıcı/oturum veya token işlemi oluşturulmadı.
