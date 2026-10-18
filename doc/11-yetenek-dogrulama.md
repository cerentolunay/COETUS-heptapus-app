> Güncel dalda “Onay al” kaldırılmıştır. Bu belgedeki kişi onayı/ödül açıklamaları önceki sürümü anlatır; güncel davranış için `13-kayit-ilgi-alanlari.md` belgesine bakın.

# Çalışmalar ve eşleşme onayları

Güncel akışta kimlik doğrulama hizmeti ve manuel kanıt inceleme kuyruğu yoktur. Portföy ve kişi onayları kimlik doğrulaması sayılmaz.

- Bir yetenek eklemek, eşleşmek veya onay almak için fotoğraf/video yüklemek gerekmez.
- Çalışma örneği ilgili yeteneğe bağlanır. Açıklama tek başına yeterlidir; en fazla 3 fotoğraf/video isteğe bağlı eklenebilir. Çalışmalar inceleme beklemeden, giriş yapmış kullanıcılara görünür biçimde yayımlanır. Keşfet'e kendiliğinden gönderilmez.
- Medya içeren farklı yetenekler +2 güven katkısı sağlar; portföy toplamı en fazla +6'dır. Aynı yeteneğe çok sayıda dosya eklemek katkıyı artırmaz. Son medya örneği kaldırılınca katkı yeniden hesaplanır. Medya eklememek ceza doğurmaz. Yazı veya medya paylaşmak token kazandırmaz.
- Eşleştiği kişi, yalnızca sunucuda fonlanmış ve tamamlanmış gerçek oturumdan sonra “Bu kişi bana öğretti” onayı verebilir. Aynı kişi aynı yeteneği ikinci kez onaylayamaz. Profilde yetenek başına “Eşleştiği 5 kişiden onay” gibi gösterilir.
- Her farklı kişi/yetenek onayı +5 güven katkısı sağlar; bu katkı en fazla +30'dur. Mevcut token politikası ilk üç farklı yeteneğin ilk kişi onayında 10'ar token verir; aynı yeteneğin diğer onaylarında token verilmez.
- Portföy sahibi çalışmasını silebilir. Başkaları uygunsuz/çalıntı içerik için gerekçeli şikâyet gönderebilir. Şikâyetler özel `contentReports` koleksiyonunda tutulur; kullanıcıların çalışma yayımlaması bu şikâyetlerin incelenmesini beklemez. Şikâyet çözümleme paneli bu sürümde yoktur; proje yöneticisi Firebase Console üzerinden kayıtları görebilir.

## Sunucu ve güvenlik

`functions/index.js`: portföy yayımlama/silme/şikâyet ve gerçek eşleşme sonrası onay. `verification_policy.js`: ödül ve güven sınırları. Eski `reviewSkillEvidence` işlevi, eski istemciler için manuel incelemenin kaldırıldığı hatasını döndürür; onay veremez.

`skillVerifications` koleksiyonunda `type: portfolio, status: published` çalışma örneğidir; `type: peer, status: approved` kişi onayıdır. İstemciler kayıtları, puanları, bakiyeleri veya onay sayılarını doğrudan değiştiremez. Yeni medya ayrı `portfolioMedia/{uid}/{entryId}/{filename}` yolundadır. Önceki özel kanıt dosyaları otomatik olarak yayımlanmaz.

Kimlik rozeti gösterilmez ve kişi onayı `users.verified` alanını değiştirmez. `grant_reviewer.js` önceki inceleme sistemi için yazılmıştır; güncel akış için kullanılmaz.

## Dağıtım

Proje: `coetus-bc9c6`, Functions codebase: `verification`, bölge: `europe-west1`.

```powershell
.\functions\node_modules\.bin\firebase.cmd login
.\functions\node_modules\.bin\firebase.cmd deploy --project coetus-bc9c6 --only functions:verification,firestore:rules,firestore:indexes,storage
```

Cloud Functions, Cloud Build, Artifact Registry ve ilgili servislerin etkin olması; hesabın bunları açma/dağıtma yetkisi ve projenin gerekli faturalandırma kurulumu bulunması gerekir. Canlı oturum kabulü sunucuya bağlı olduğundan işlevler hazır olmadan yalnızca yeni katı oturum kurallarını yayımlamayın.

Yerel kontroller:

```powershell
node --test functions/verification_policy.test.js
.\functions\node_modules\.bin\firebase.cmd emulators:exec --project demo-coetus --config firebase.emulators.json --only firestore,storage "node --test functions/verification_emulator.test.js"
flutter test
```


Dağıtım notu: Node.js 22 ortamında npm 10 ile üretilen kilit dosyası kullanılmalıdır. Windows'taki npm 11 ile üretilen dosya, bulut derlemesinde eksik `picomatch` kaydı nedeniyle başarısız olmuş; npm 10 ile düzeltilmiştir. Callable işlevlerde `invoker: public` yalnızca HTTP taşıma erişimidir; her işlev ilk adımda Firebase oturumunu doğrular ve uygulama yetkilerini denetler. Başarısız ilk oluşturma sonrası Cloud Run çağrı izinleri ayrıca tamamlanmıştır.
