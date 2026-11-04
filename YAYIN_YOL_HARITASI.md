# COETUS — ayrıntılı yayın yol haritası

**Durum tarihi: 19 Ekim 2026 (Türkiye saati).**

**Uygulama sırası:** [25 ayrı yayın görevi](YAYIN_GOREVLERI.md).
Her görev adımlar, bağımlılıklar, sorumlu, kabul ölçütleri ve kanıt alanı içerir.
İlk adım: [telefon test sürümünü incele](TELEFONDA_TEST.md).

Bu belge, mevcut depoda bulunan özellikleri, bu geliştirme turunda tamamlanan
çalışmaları ve gerçek kullanıcıya yayın için kalan işleri birlikte takip eder.
Bir özelliğin kodda veya önizlemede bulunması, üretimde çalıştığının kanıtı değildir.
Bu çalışma sırasında canlı Firebase/mağaza yayını, ücretli plan açılışı veya gerçek
kullanıcı hesabında yönetici ataması yapılmamıştır.

## 1. Hedef, kapsam ve kararlar

En kısa yol: **Android → imzalı sınırlı test → Play Console test kanalı → üretim**.
iOS ve gerçek Premium satışı sonraki aşamaya bırakılabilir. Önizleme APK'sı ürünün
canlı sürümü olarak dağıtılmamalıdır.

### Değiştirilmeyecek kullanıcı kararları

- Ek ücret doğurabilecek Firebase işlemleri kendiliğinden yapılmayacak.
- İlk girişte hesap başına bir kez **50 token** verilecek.
- İlk kabul edilmiş eşleşme için ayrıca bir kez **20 token** verilecek.
- Premium sayfasında iki taslak paket: **Sınırsız eşleşme** ve **250 token**.
- Ödeme altyapısı bu sürümde kurulmayacak; satış düğmeleri pasif kalacak.
- İlgi alanı önerileri yalnızca yetkili yönetici onayından sonra yayınlanacak.
- Ana vurgu paleti mor, lime ve kırmızı; mavi vurgu kullanılmayacak.

### Temel ürün modeli: karşılıklı öğrenen eşleşmiş kişiler

COETUS'ta bir kişi kalıcı olarak öğretmen, diğeri öğrenci değildir. Bir eşleşmede
**iki kişi de bir beceri paylaşır ve karşı taraftan başka bir beceri öğrenir**.
Örnek: A, B'ye Python paylaşır; B, A'ya gitar paylaşır. Aynı ortak takasın iki yönü
vardır. Tokenlar bu karşılıklı taahhüt için escrow'da tutulur; süreç yalnızca tek
kişinin öğrenip diğer kişinin ödeme aldığı ders olarak modellenmemelidir.

**Önemli kod farkı:** Mevcut `functions/learning.js`, teklif/oturum modelleri ve
bazı ekranlar hâlâ tek yönlü `teacherId`/`studentId` akışını kullanıyor. Aşağıdaki
karşılıklı model hedef üründür; yalnızca bu belgenin düzeltilmesiyle kodda çalışır
hâle gelmez. İki yönlü eşleşme ve escrow dönüşümü üretim öncesi P0 iştir.

### İlk sürüm için ürün sahibinin kesinleştireceği kararlar

- [ ] Android'de ilk hedef: özel APK testi mi, Google Play testi mi?
- [ ] Hedef kitle ve yaş grubu; çocukların kullanımına izin verilip verilmeyeceği.
- [ ] İlk sürümde fotoğraf/video, topluluk ve sohbetin hangilerinin açık olacağı.
- [ ] Yüz yüze görüşmenin desteklenip desteklenmediği ve güvenli kullanım kuralları.
- [ ] İlk ücretsiz planda kullanıcı/eşleşme sınırı; Premium satışa açılana kadar davranış.
- [x] Başarılı takasta herkes kendi kilitlediği tokenları geri alır; karşı tarafa
      aktarım yapılmaz. Ürün sahibi kararı: 19 Ekim 2026. Uygulaması henüz tamamlanmadı.
- [ ] İki katkının tutarı, eşit olmak zorunda olup olmadığı ve iki öğrenme yönünün
      tamamlanma/itiraz/zaman aşımı koşulları.
- [ ] Aynı kişinin birden fazla hesapla hediye toplamasına karşı uygulanacak politika.
- [ ] Destek e-postası, gizlilik politikası adresi ve hesap silme talep adresi.

## 2. Mevcut durum: var, doğrulandı, eksik

| Alan | Depodaki durum | Yayın öncesi kalan |
|---|---|---|
| E-posta/şifre kayıt ve giriş | Firebase Auth entegrasyonu var | Sağlayıcı ayarı, gerçek cihaz testi |
| Google girişi | Native Google + Firebase kodu, ayrıntılı hata mesajları var | Android imzası/OAuth ve gerçek cihaz; iOS OAuth ayarı eksik |
| Şifre sıfırlama | Bu turda gerçek Firebase çağrısına bağlandı | Sağlayıcı/şablon ve e-posta teslimatı testi |
| 50 token | Kalıcı makbuz + atomik bakiye artışı var | Yeni kuralları canlıya alma ve gerçek hesap doğrulaması |
| İlk eşleşme 20 token | Ayrı makbuzla, kabul edilmiş eşleşmeye bağlı | Canlı kurallar ve gerçek eşleşme doğrulaması |
| Ortak ilgi alanı ekranı | Giriş/profil aynı kart ve beceri ağacını kullanır | Gerçek hesapta kaydetme ve tekrar açma testi |
| İlgi önerisi/onayı | Bekleyen kayıtlar özel, yönetici onayı var | Yöneticinin UID'sine rol atama, canlı kurallar |
| Beceri seviyesi | Ekle/düzenle/paylaş için ortak mor/lime pencere | Fiziksel cihazda klavye ve büyük yazı kontrolü |
| Eşleşme/emanet token | Mevcut kod/testler tek yönlü ders modelinde | P0: iki kişinin de öğrenip paylaştığı takasa, iki taraflı escrow ve mutabakata dönüşüm; backend kararı ve canlı test |
| Sohbet | Firestore katılımcı erişim kuralları var | Engelleme, spam politikası, iki cihaz ve çevrimdışı test |
| Sohbette zaman önerisi | Onayla/Değiştir düğmeleri yalnızca "yakında" mesajı gösteriyor | Repository, katılımcı yetkisi ve iki kişinin zaman mutabakatı; görev 06 |
| Portföy şikâyeti | UI + `reportPortfolioEntry` + `contentReports` var | Gerçek moderasyon takibi ve işlem akışı |
| Genel moderasyon | İlgi önerisi yönetimi var | Kullanıcı engelleme ve genel sohbet/topluluk şikâyet yönetimi bulunmadı |
| Hesap silme | İstemci, sunucu, temizlik ve testler var | Canlı `deleteAccount` kullanılabilirliği ve gerçek silme testi |
| Premium | Tanıtım sayfası, pasif paketler ve token bağlantıları var | Ödeme özellikle yapılmayacak; satış sonraki sürüm |
| Animasyonlar | Maskot dokunma, boş alan efektleri, eşleşme kalbi, hareketli halkalar var | Düşük donanım, pil ve erişilebilirlik testi |
| Android yayın imzası | Release hâlâ debug imzasını kullanıyor | Gerçek upload anahtarı ve release imzalaması |
| iOS/web | iOS Firebase bilgisi var; web Firebase yapılandırılmamış | iOS OAuth/Apple işlemleri; web ayrı proje aşaması |
| Otomatik CI | Bu taramada `.github` iş akışı bulunmadı | PR'da analiz/test; imzalama sırlarının güvenli yönetimi |

**Canlı durum notu:** `doc/14-hesap-silme.md`, önceki bir çalışmada bazı Functions
kaynaklarının ACTIVE olduğunu ve `deleteAccount` yayınının tamamlanmadığını
bildiriyor. Bu tarihsel not, şu anki konsol durumunun kanıtı değildir. Kaynakların
varlığı, fatura veya işlevlerin başarı durumu bu turda canlıdan doğrulanmadı.

## 3. Öncelik ve çalışma sırası

| Sıra | İş | Sorumlu | Bitiş kanıtı |
|---|---|---|---|
| P0-1 | Firebase maliyet ve backend kararı | Ürün sahibi + geliştirici | Yazılı kapsam, etkin kaynak listesi |
| P0-2 | Auth sağlayıcıları ve Android Google imzası | Hesap sahibi + geliştirici | Gerçek cihazda giriş ve reset |
| P0-3 | Karşılıklı eşleşme, iki taraflı escrow, kurallar/indeksler | Ürün sahibi + geliştirici | İki yönlü beceri uyumu, atomik kilit, iki tarafın tamamlaması; bir kez 50/20 |
| P0-4 | Hesap silme uçtan uca | Geliştirici + testçi | Auth/veri/medya temizlik kanıtı |
| P0-5 | Engelleme, şikâyet, moderasyon | Geliştirici + yönetici | Kullanıcı ve yönetici senaryoları |
| P0-6 | Gizlilik ve mağaza beyanları | Ürün sahibi | Yayındaki erişilebilir sayfalar |
| P0-7 | Release imzası, AAB ve cihaz testi | Geliştirici | İmzalı release ve test tutanağı |
| P1 | Test kanalı ve inceleme | Play hesabı sahibi | Console'un yayın şartlarının tamamlanması |
| P2 | iOS, satış ve gelişmiş otomasyon | İlgili ekip | Ayrı sürüm kabulü |

Süre tahmini yerine bu çıkış ölçütleri kullanılmalıdır. Mağaza hesap doğrulaması,
zorunlu test süresi ve inceleme, kodlama bittiği gün tamamlanmak zorunda değildir.

## 4. Adım 1 — maliyet engelini çöz

### 4.1 Mevcut kaynakları salt okunur kontrol et

- [ ] Firebase proje kimliği `coetus-bc9c6` ve sahibi doğrulansın.
- [ ] Spark/Blaze planı ve bağlı faturalandırma hesabı kontrol edilsin.
- [ ] Functions bölümleri, etkin işlevler ve bölgeler listelensin.
- [ ] Cloud Run/Artifact Registry/Cloud Build gibi Functions ile ilişkili kaynaklar
      ve maliyetleri konsoldan incelensin.
- [ ] Firestore okuma/yazma, Storage saklama/indirme ve Auth kullanımını incele.
- [ ] Bütçe bildiriminin **harcamayı durduran kesin üst limit olmadığı** anlaşılsın.
- [ ] Gereksiz kaynakların kapatılması ayrı değerlendirilip veri ve uygulama
      bağımlılıkları belirlenmeden hiçbir kaynak silinmesin.

### 4.2 Kodun bağlı olduğu sunucu işleri

`functions/index.js` ve modülleri şu grupları içeriyor:

- Öğrenme: `acceptLearningOffer`, `completeLearningSession`, `cancelLearningSession`.
  Bunlar şu an tek yönlü kilit/aktarım içeriyor; karşılıklı takasın hedef davranışı
  olarak kabul edilmez, bölüm 7'deki dönüşüme dahil edilir.
- Topluluk: yayın, silme, kalp, yorum, token desteği.
- Portföy: kanıt/çalışma gönderme, silme ve şikâyet.
- Hesap: `deleteAccount` ve `cleanupDeletedAccount` Auth tetikleyicisi.
- Eski kişi onayı işlevleri korunmuş hata döndürür; yeniden ödül vermemelidir.

50 ve 20 token hediyeleri yeni Functions eklemez. **Bu, tüm uygulamanın Spark'ta
çalıştığı anlamına gelmez.** Dosya yükleme ve mevcut Functions için güncel plan ve
kota koşulları konsol/sağlayıcı belgelerinden ayrıca doğrulanmalıdır.

### 4.3 Seçilecek yol

**Ücretli plan açılmayacaksa:**

- [ ] Functions ve medya bağımlılıkları için ücretsiz sınırları doğrulanmış bir
      sunucu çözümü tasarla veya ilk sürüm kapsamını açıkça azalt.
- [ ] Yetkilendirme, atomik token, iade, medya erişimi ve hesap silme garantilerini
      koruyarak taşıma planı yaz. Finansal işlevleri kuralsız istemci yazısına çevirme.
- [ ] Kapalı bırakılan özellikleri arayüzde ve API'de tutarlı biçimde kapat;
      çalışmayan butonlarla tam sürüm izlenimi verme.
- [ ] Bu işler yapılmadıkça Functions'a bağlı özellikler üretime hazır sayılmasın.

Ürün sahibi sonradan ücretli altyapıyı açıkça seçerse maliyet ve dağıtım planı
ayrı hazırlanır. Bu belge Blaze açma veya yeni Functions dağıtma talimatı değildir.

## 5. Adım 2 — Firebase Auth ve Google girişi

### 5.1 Sağlayıcılar

- [ ] Firebase Console → Authentication → Sign-in method altında Email/Password aç.
- [ ] Google sağlayıcısını aç; destek e-postasını seç ve kaydet.
- [ ] Yasaklı/devre dışı test hesaplarını gerçek kullanıcıdan ayır.
- [ ] Proje ve uygulama kimliklerinin aynı Firebase projesine ait olduğunu doğrula.

### 5.2 Android Google imzası

- [ ] Kullanılan application ID: `com.heptapus.coetus`; yayın öncesi kalıcı olduğuna
      karar ver. Yayınlandıktan sonra aynı uygulamanın kimliği rastgele değiştirilemez.
- [ ] Geliştirme bilgisayarında kullanılan sertifikayı çıkar:

```bash
cd android
./gradlew signingReport
```

Windows PowerShell'de `./gradlew` yerine `.\gradlew.bat` kullanılır.

- [ ] Firebase Project settings → Your apps altında debug sertifikasının SHA-1 ve
      SHA-256 değerlerini ekle.
- [ ] Release/upload sertifikası farklıysa onu da ekle.
- [ ] Play App Signing kullanıldığında **Play uygulama imzalama sertifikası** da
      ayrıca eklenmeli; upload anahtarıyla karıştırılmamalı.
- [ ] Güncel `google-services.json` indir; `android/app/` içine yerleştir.
- [ ] Dosyada doğru package ve OAuth kayıtları olduğunu doğrula; OAuth client ID
      veya sertifika uydurma. Özel anahtar hiçbir JSON'a eklenmez.
- [ ] Uygulamayı yeniden derle/yükle. Native yapılandırma için hot reload yetmez.
- [ ] Hesap seçme, iptal, yanlış imza ve ağ kesintisini fiziksel cihazda dene.

### 5.3 Şifre sıfırlama

- [ ] Authentication → Templates → Password reset şablonunu kontrol et.
- [ ] Uygulama adı, destek adresi ve varsa özelleştirilmiş işlem alan adını doğrula.
- [ ] Gerçek e-posta/şifre hesabında bağlantıyı iste; spam klasörünü de kontrol et.
- [ ] Bağlantıyla yeni şifre belirle; eski şifreyle giriş başarısız, yenisiyle başarılı olsun.
- [ ] Aynı anda tekrar basma, yanlış e-posta, kota ve bağlantı hatalarını dene.
- [ ] Google hesabı olan kullanıcı Google ile girişe yönlendirilsin; reset mesajı
      bir adresin kayıtlı olup olmadığını ifşa etmesin.

### 5.4 Oturum ve 50 token

- [ ] Yeni e-posta kaydı, yeni Google kaydı, mevcut hesap girişi ve yeniden açılan
      oturumun doğru profile bağlandığını doğrula.
- [ ] Giriş başarılı ama Firestore izni reddedilirse OAuth ayarını rastgele değiştirme;
      token kurallarının sürümünü kontrol et.
- [ ] Kayıt sırasında ağ hatasından sonra tekrar giriş, bakiye ve profili sıfırlamasın.
- [ ] Gerçek testte `lib/main.dart` kullan; `ÖNİZLEME · ÇEVRİMDIŞI` gerçek Auth değildir.

## 6. Adım 3 — veri modeli, kurallar, indeksler ve token

### 6.1 Mevcut token kuralları

- Yeni profil güvenli temel bakiyeyle oluşturulur; welcome transaction'ı bakiyeye
  **50 ekler** ve `users/{uid}/rewards/welcome` makbuzu oluşturur.
- Daha önce welcome makbuzu olmayan mevcut hesap da sonraki girişinde bir kez alır.
- Kabul edilmiş gerçek eşleşmenin katılımcısı, ayrı
  `users/{uid}/rewards/first_match` makbuzuyla **20 ek token** alabilir.
- Makbuzlar değiştirilemez/silinemez; tutar ve bakiye aynı işlemde doğrulanır.
- Hesap başına bir kez vermek, aynı insanın farklı hesap açmasını önlemez.

### 6.2 Yapılacaklar

- [ ] `firestore.rules`, `storage.rules` ve `firestore.indexes.json` birlikte incelensin.
- [ ] Test ortamında güncel kurallar, indeksler ve uygulama aynı sürümle denensin.
- [ ] Aktif kullanıcıların yeni uygulama/kurallar geçiş sırası belirlensin; eski
      kurallar yeni welcome işlemini reddeder. Önce uyumlu kurallar, sonra uygulama.
- [ ] Veri içeriği, fotoğraf/mesaj/konum/e-posta görünürlüğü alan alan denetlensin.
      Örneğin `/users` okuması giriş yapmış hesaplara açık; özel tutulması gereken
      alanlar varsa ayrı özel belgeye taşınmalı. Bu bir tam güvenlik denetimi değildir.
- [ ] `chats`, `messages`, `matches`, `sessions` ve katılımcı kuralları için negatif
      testler genişletilsin; kötü niyetli doğrudan istemci istekleri de denensin.
- [ ] İndekslerde topluluk durum/tarih, portföy sahip/durum ve hesap silmedeki
      comments/authorId, likes/userId collection-group sorguları READY olsun.
- [ ] Sonradan eklenecek engelleme/şikâyet sorgularının indeks ihtiyacı belirlenmeli.
- [ ] Gerekirse App Check aşamalı tasarlansın; önce ölçüm, sonra enforcement.
      Gerçek imzalı APK doğrulanmadan kullanıcıları kilitleyecek değişiklik yapılmasın.
- [ ] Hız sınırlama, bot/çoklu hesap, spam ve hediye istismarı politikası uygulansın.
- [ ] Günlükler token, parola, erişim anahtarı veya hassas kişisel veri içermesin.

Canlı proje seçimi, yetki ve maliyet planı açıkça doğrulanmadan aşağıdaki yayın
komutları çalıştırılmaz. Bunlar bu çalışmada **çalıştırılmadı**:

```bash
# Yalnızca daha sonra açıkça yetkilendirilmiş, doğru projeye yapılacak yayın:
functions/node_modules/.bin/firebase deploy --project coetus-bc9c6 --only firestore:rules,firestore:indexes,storage
```

Bu komut Functions yayınlamaz; Storage ve diğer etkin kaynakların kullanım
maliyetini ortadan kaldırmaz. Kuralları yayınlamak indekslerin hemen hazır olduğu
anlamına gelmez; READY durumu beklenir ve gerçek sorgu denenir.

## 7. Adım 4 — karşılıklı eşleşme, çift taraflı escrow ve ortak tamamlama

### 7.1 Kabul edilecek ürün akışı

**Tutar için öne çıkan öneri:** İki kişinin de aynı miktarı kilitlemesi. Ürün sahibi
bunu hatırladığı olası model olarak belirtti; henüz kesinleşmiş karar veya mevcut
kodda bulunan bir kural gibi kabul edilmez. Örneğin A ve B'nin 20'şer token
kilitlemesi ortak taahhüt/teminat işlevi görebilir. “Eşit tutar kilitleme” ile
“tamamlanınca kime döneceği” iki ayrı karardır. Ürün sahibi 19 Ekim 2026’da başarılı
takasta herkesin kendi katkısını geri almasını seçti. Karşı tarafa aktarım yapılmaz.
Tutar ve anlaşmazlık politikası ayrıca kesinleştirilecektir.

1. [ ] A'nın paylaşabileceği beceri B'nin öğrenmek istediğiyle; B'nin paylaşabileceği
       beceri de A'nın öğrenmek istediğiyle uyuşsun. Örneğin Python ↔ gitar.
2. [ ] Keşif önerisi ile iki yönü doğrulanmış takas ayrı durumlar olsun. Yalnızca
       bir yönde uyum varsa sistem bunu tamamlanmış karşılıklı eşleşme gibi sunmasın.
3. [ ] Teklifte iki paylaşım ve iki öğrenme yönü, eşleşmiş kişiler ve escrow şartları
       açıkça gösterilsin. Karşı taraf kabul etmeden token kilitlenmesin.
4. [ ] Her iki kişi kendi katkısını ve karşılıklı şartları onaylasın. Kabul sonrası
       beceri/tutar değişikliği eski onayı geçersiz kılsın; yeniden mutabakat istensin.
5. [ ] Katılımcıların escrow katkıları kullanıcı bazında doğrulansın; iki bakiyenin
       yeterliliği, kilit kayıtları ve oturum geçişi tek atomik işlemde gerçekleşsin.
       Bir kişinin işlemi başarısızsa diğer kişinin tokenı da yarım kilitli kalmasın.
6. [ ] İki kişi ortak takasta hem paylaşan hem öğrenen olarak yer alsın. Ekranda
       “Sen paylaşacaksın / Sen öğreneceksin” ve karşı tarafın karşılıkları görülsün.
7. [ ] Tek kişinin “tamamladım” demesi escrow'u çözmesin. İki tarafın tamamlanma
       onayı ayrı kaydedilsin; tek onayda tokenlar kilitli kalsın.
8. [ ] İki onay geldiğinde, **her katılımcının katkısı kendi hesabına iade edilsin**.
       İki iade tek kez ve atomik uygulansın; karşı tarafa aktarım yapılmasın.
9. [ ] Karşılıklı iptalde herkesin kendi katkısı doğru hesaba yalnızca bir kez iade
       edilsin. Tek taraflı ayrılma, yalnızca bir öğrenme yönünün gerçekleşmesi,
       anlaşmazlık ve yanıt vermeyen kişi için ayrı süreç tanımlansın.
10. [ ] Tekrarlı istek, eşzamanlı iki onay, tamamlama/iptal yarışı ve ağ kesilmesi
        yeni kilit, çift çözüm veya negatif bakiye yaratmasın.

### 7.2 Kodda gerekli dönüşüm — isim değişikliğiyle tamamlanmaz

- [ ] `matching_service.dart`: yalnızca mevcut kişinin öğrenme becerisi ↔ adayın
      paylaşma becerisi karşılaştırması yeterli değil. Ters yön de gerçek beceri
      kayıtlarıyla doğrulansın; `partnerLearnSkills` listesinin bulunması tek başına
      karşılıklı uyumun kanıtı sayılmasın.
- [ ] `MatchCandidate`, `MatchOffer` ve `ExchangeSession`: iki kişi ve iki beceri
      yönünü taşıyacak model tasarlansın. Sabit öğretmen/öğrenci rolüyle ürün anlatılmasın.
- [ ] Teklif oluşturma ve kabul: iki katkı, fiyat/teminat şartı ve mutabakat sürümü
      sunucuda doğrulansın; kullanıcı başkasının katkısını keyfi değiştiremesin.
- [ ] `functions/learning.js`: tek kişinin bakiyesini kilitleyen ve tek kişiye
      aktaran kabul/tamamlama/iade işlemleri karşılıklı modele dönüştürülsün.
- [ ] Emanet kayıtlarında kişi bazında katkı ve çözüm; oturumda iki öğrenme yönü ve
      tamamlanma onayları saklansın. Önerilen kavramlar: `participants`,
      `skillsByParticipant`, `contributions`, `completionApprovals`, `schemaVersion`.
      Bunlar mevcut kodda uygulanmış alanlar değil, şema tasarımının başlangıcıdır.
- [ ] Tutarın iki tarafta aynı olup olmayacağı ve toplam tutarın nasıl hesaplanacağı
      kararlaştırılsın. Örnek sayılar nihai fiyatlandırma kuralı olarak kodlanmasın.
- [ ] Kurallar, indeksler, bildirimler, sohbet özeti, Takaslarım ve kutlama ekranı
      aynı iki taraflı anlaşmayı göstersin. Eski tek yönlü bildirimler değiştirilsin.
- [ ] Hesap silme, iki kişinin de kilitli katkısını korusun; bir kişinin temizliği
      diğer kişinin teminatını veya işlem kanıtını silmesin.
- [ ] Eski tek yönlü belgeler için sürümlü geçiş planı yazılsın. Aktif kilitli
      kayıtlar alan adları değiştirilerek otomatik karşılıklı takasa çevrilmesin;
      mevcut taahhütler güvenli biçimde sonuçlandırılsın veya açıkça taşınsın.
- [ ] Eski tek yönlü testler tarihsel davranışı doğrular; yeni iki yönlü kabul,
      escrow ve mutabakat testleri ayrıca yazılmadan model tamamlandı sayılmasın.

### 7.3 Tokenların korunumu ve örnek kabul testi

- [ ] Hediye dışındaki kilitleme/çözme/iptal toplam token üretmesin veya yok etmesin.
      İki kişinin kullanılabilir + kilitli toplamı işlem öncesi/sonrası tutarlı olsun.
- [ ] 50 token başlangıç ve 20 token eşleşme hediyesi finansal harekete ayrı
      makbuzlarla işlensin; escrow bakiyesine karışan belirsiz bonus oluşmasın.
- [ ] İki ayrı hesap ve iki cihazla A: Python paylaşır/gitar öğrenir; B: gitar
      paylaşır/Python öğrenir senaryosu çalıştırılsın.
- [ ] Yalnızca test örneği olarak, her biri 50 tokenlı iki kişi 30'ar token
      kilitlerse A ve B'de ayrı ayrı 20 kullanılabilir + 30 kilitli görünsün.
      Bu sayı bir fiyat kararı değildir; ilk eşleşme hediyesi testten ayrıştırılsın.
- [ ] A tek başına tamamladığında iki escrow katkısı da kilitli kalsın.
- [ ] B de tamamladığında seçilen politikaya göre iki kayıt tek işlemde çözülsün;
      A'ya veya B'ye tek başına tüm emanet aktarılmasın.
- [ ] Aynı tamamlanma/iptal istekleri yeniden gönderilsin; çözüm tekrarlanmasın.
- [ ] Bir kişinin bakiyesi yetersizse ikisinde de yeni kilit oluşmasın.
- [ ] Sadece bir beceri yönü varsa veya katkı/skill sonradan değiştirilirse teklif
      geçersiz sayılsın ya da yeniden iki tarafın onayını gerektirsin.
- [ ] Üçüncü hesap oturumu okuyamasın/değiştiremesin; silinmekte olan hesap ve
      eski oturum tokenı işlem yapamasın.

Tokenlar gerçek para olarak sunulmamalı; karşılıklı öğrenme, escrow çözümü,
kısmi gerçekleşme, itiraz ve hesap silmede ne olacağı kullanım koşullarında açıkça
anlatılmalıdır. Hedef modelin geliştirilmesi, ücretli altyapı açma yetkisi vermez.

## 8. Adım 5 — moderasyon ve yönetici

### 8.1 İlgi alanı önerileri: kod var, hesap ataması bekliyor

- [ ] Firebase Authentication'dan ürün sahibinin doğru UID'sini doğrula.
- [ ] Güvenilir, yetkili Admin ortamında mevcut claim'leri koruyarak rolü ata:

```bash
cd functions
node grant_interest_moderator.js GERCEK_FIREBASE_UID
```

Bu komut gerçek hesabın yetkisini değiştirir; bu çalışmada çalıştırılmadı. UID
yerine e-posta yazılmaz. Admin anahtarı depoya, uygulamaya veya sohbete konmaz.

- [ ] Çıkış/giriş yap; Profil → İlgi alanlarını keşfet → Önerileri incele açılsın.
- [ ] Normal kullanıcı ve yönetici hesaplarını ayrı test et.
- [ ] Bekleyen öneri yalnızca sahibi/yönetici tarafından görülür; onay herkese açar,
      ret herkese açmaz. Normal kullanıcı kendi önerisini onaylayamaz.
- [ ] Yönetici rolünü kaldırma ve işlem kaydı politikası da belirlensin.

### 8.2 Genel moderasyon: tamamlanması gereken ürün işleri

- [ ] Profil, sohbet mesajı, topluluk paylaşımı ve yorum için şikâyet girişleri tasarla.
- [ ] Mevcut portföy şikâyetini aynı yönetim sürecine dahil et.
- [ ] Şikâyet nedeni, hedef türü/id, gönderen, zaman ve durum alanlarını belirle.
- [ ] Kullanıcı engelleme/engeli kaldırma ekle. Yeni mesaj, teklif, keşif ve mevcut
      sohbetlerin nasıl davranacağına açıkça karar ver.
- [ ] Engeli yalnızca arayüz filtresi olarak uygulama; yetkilendirmede de koru.
- [ ] Şikâyetleri sırala/incele, içerik gizle/kaldır, hesap kısıtla ve çözüm notu ekle.
- [ ] Bu yetkileri ilgi moderatörlüğüyle rastgele birleştirme; en az gerekli rolü ver.
- [ ] Yönetici eylemlerini kaydet; normal hesap yönetim ekranına/API'sine erişemesin.
- [ ] Yanlış şikâyet, seri spam, engelden kaçma ve kötüye kullanım testlerini yaz.
- [ ] Kullanım koşullarına kabul edilmeyen içerik ve itiraz/destek yolunu ekle.
- [ ] Bildirimlere kimin, ne sıklıkla cevap vereceğini ve acil müdahaleyi belirle.

## 9. Adım 6 — hesap silme ve veri yaşam döngüsü

Kaynaklar: `account_deletion_service.dart`, `functions/account_deletion.js`,
`doc/14-hesap-silme.md`. Kodun varlığı canlı `deleteAccount` endpoint'inin varlığına
kanıt değildir. Yeni ücretli Functions yayını maliyet kararı verilmeden yapılmaz.

- [ ] Gerçek çağrının doğru bölge/projeye gittiğini ve endpoint'in kullanılabilirliğini doğrula.
- [ ] E-posta hesabında şifreyle; Google hesabında aynı hesapla yeniden doğrula.
- [ ] Son doğrulama süresi ve açık kullanıcı onayı zorunlu olsun.
- [ ] Kilitli token/aktif emaneti olan hesap önce oturumlarını sonuçlandırsın.
- [ ] Auth hesabı, profil, alt beceriler ve reward makbuzları temizlensin.
- [ ] Kullanıcının paylaşımları, portföyü, medyası, yorum/kalpleri ve bildirimleri temizlensin.
- [ ] İlgi alanı önerileri silinsin; şikâyet ve ortak sohbet verileri politikaya uygun işlenmiş olsun.
- [ ] Kalan tarafın geçmişi, anonimleştirme ve sayaçlar kontrol edilsin.
- [ ] Arka plan temizlik tekrarları idempotent olsun; yarım kalan temizlik izlenebilsin.
- [ ] Silinmiş hesabın eski tokenıyla belge/medya/hediye yeniden oluşturulamasın.
- [ ] Silme sonrası hangi işlem kayıtlarının niçin/ne kadar saklandığı politikalarda açıklansın.
- [ ] Uygulama içi silmeye ek olarak mağazanın istediği hesap silme talep web adresi hazır olsun.

## 10. Adım 7 — Android yayın imzası ve derleme

### 10.1 Araçlar

- [ ] Flutter/Dart sürümünü lockfile ile uyumlu tut. Bu çalışmada Flutter **3.41.5**
      kullanıldı; `flutter pub get --enforce-lockfile` uyumu kontrol edilmeli.
- [ ] Functions için Node **22**; emülatörler için Java gerekir.
- [ ] Android SDK, platform/build-tools, lisanslar ve Gradle/JDK uyumu doğrulansın.
- [ ] `flutter doctor -v` çıktısındaki Android engelleri giderilsin.
- [ ] Android release derlemesi bu bulut çalışmasında doğrulanmış sayılmasın;
      cihaz, SDK ve gerçek imza ile ayrıca çalıştırılmalıdır.

### 10.2 İmza ve anahtarlar

- [ ] `android/app/build.gradle.kts` içindeki debug release imzasını gerçek upload
      signing config ile değiştir; debug imzasıyla Play'e yüklemeye çalışma.
- [ ] Upload keystore üret, güvenli yedeklerini al, parolaları güvenli depoda tut.
- [ ] `key.properties`, `*.jks`, `*.keystore`, Apple sertifikaları, Admin JSON ve
      parolalar için ignore/CI secret politikası ekle; sadece ignore yazmak mevcut
      Git geçmişindeki sırları silmez. Gerekirse anahtar yenilemesi ayrı yapılır.
- [ ] Play App Signing ve upload/app-signing anahtar ayrımını doğrula.
- [ ] Son application ID ve uygulama adını kesinleştir.
- [ ] `pubspec.yaml` sürüm/build numarasını artır; her mağaza yüklemesi benzersiz kod kullansın.

### 10.3 Tekrarlanabilir komutlar

Depo kökünden, uygun SDK ve imza ayarlarından sonra:

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build appbundle --release -t lib/main.dart
# Sınırlı doğrudan cihaz testi için gerekirse:
flutter build apk --release -t lib/main.dart
```

- [ ] AAB/APK'nın kimliği, sürümü ve release sertifikası doğrulansın.
- [ ] `main_preview.dart` yayın komutuna girmesin; önizleme banner'ı ürün sürümünde olmasın.
- [ ] Güncel Play hedef API ve native kütüphane/16 KB bellek sayfası uyumluluğu gibi
      platform gereksinimleri güncel Console uyarılarından doğrulansın.
- [ ] Medya/konum/kamera/mikrofon izinleri yalnızca ihtiyaç anında istensin.
- [ ] Gerekirse küçültme/obfuscation sembolleri güvenli saklansın; hata ayıklama mümkün olsun.

## 11. Adım 8 — cihaz kabul testi

Ayrıntılı senaryolar: [Cihaz test matrisi](doc/21-yayin-test-matrisi.md).

- [ ] En az iki gerçek hesap ve iki fiziksel Android cihazla ana akışlar tamamlanmış olsun.
- [ ] Düşük donanım, küçük ekran, büyük yazı, hareket azaltma, karanlık/sistem görünümü
      ve klavye açılması denensin.
- [ ] Ağ yokken/geri gelirken, uygulama öldürülüp açıldığında ve oturum süresi
      yenilendiğinde veri tutarlılığı kontrol edilsin.
- [ ] Hatalar ekran kapanmasına, sonsuz yüklemeye veya gerçekte yapılmamış başarıya dönüşmesin.
- [ ] Pil, bellek, animasyon ve medya yükleme maliyeti ölçülsün.
- [ ] Sahte/örnek kişilerin gerçek keşif ekranında görünmediği doğrulansın.
- [ ] Açık kritik hata kalmasın; test tutanağında cihaz, sürüm ve commit yazılsın.

## 12. Adım 9 — hukuki metinler ve mağaza hazırlığı

Bu bölüm hukuki görüş yerine yapılacak ürün işlerini listeler. Gerçek veri işleme
ve hedef ülkelere göre metinler ürün sahibi tarafından doğrulanmalıdır.

- [ ] Gizlilik politikası: Auth, ad/e-posta, profil, şehir, fotoğraf/video, mesajlar,
      ilgi/beceriler, işlem kayıtları, hizmet sağlayıcılar ve varsa günlükler.
- [ ] Konumun şehir etiketi için kullanıldığı, arka plan/canlı konum toplanmadığı
      iddiası gerçek uygulama davranışıyla eşleşsin.
- [ ] Kamera/mikrofon/galeri amaçları ve izin reddinde alternatifler açıklansın.
- [ ] Saklama, silme, anonimleştirme, başvuru/destek yolları tanımlansın.
- [ ] Kullanım koşulları: token, oturum, iptal/iade, topluluk ve moderasyon.
- [ ] Öğretme/öğrenme ve yüz yüze buluşmalarda güvenli kullanım rehberi oluştur.
- [ ] Yaş grubu, çocuk güvenliği ve UGC yükümlülükleri kontrol edilsin.
- [ ] Politika ve hesap silme adresleri herkese açık, giriş gerektirmeyen HTTPS sayfalar olsun.
- [ ] Uygulama içinden bu sayfalara erişim ekle; gerçek adresleri test et.
- [ ] Mağaza açıklaması, kısa açıklama, ikon, ekran görüntüleri, grafikler ve destek e-postası hazırla.
- [ ] Data Safety / App Privacy yanıtları kodun ve kullanılan SDK'ların gerçek davranışına uysun.
- [ ] Reklam, içerik derecelendirme, hedef kitle ve varsa sağlık/finans beyanlarını doğru doldur.
- [ ] İnceleme ekibine gerçek test hesabı ve gereken giriş/adım talimatlarını ver;
      üçüncü kişilerin verilerine erişen yönetici hesabı verme.

## 13. Adım 10 — Play Console test ve yayın

- [ ] Geliştirici hesabını aç/doğrula; güncel kayıt ücretini Console'dan kontrol et.
- [ ] Kişisel/kuruluş hesabının gereken belgelerini tamamla.
- [ ] Hesabına uygulanabilen kapalı test, testçi sayısı ve süre koşullarını güncel
      Console'dan kontrol et. Bu belge değişebilen koşullara sabit sayı/süre garantisi vermez.
- [ ] Internal testing'e doğru imzalı AAB yükle; kurulum bağlantısını sınırlı grupla paylaş.
- [ ] Play üzerinden kurulan sürümde Google girişini yeniden dene; Play imzası farklı olabilir.
- [ ] Uygulama erişimi, mağaza içerikleri ve politika formlarını tamamla.
- [ ] Ön lansman raporu/cihaz uyarılarını değerlendir, kritik hataları düzelt.
- [ ] Gerekiyorsa kapalı testi tamamla ve üretim erişimi başvurusu yap.
- [ ] Son test commit'i ile yayınlanan build aynı olsun; arada kontrolsüz kod değişmesin.
- [ ] Uygun olduğunda kademeli dağıtım yap; hata ve destek taleplerini izle.

Sadece GitHub'a push yapmak Play yayını, APK güncellemesi veya Firebase yayını
anlamına gelmez. Test kanalı, mağaza onayı ve gerçek kullanıcı erişimi ayrı adımlardır.

## 14. Sonraki aşama — iOS

- [ ] Mac, uyumlu Xcode, Apple geliştirici hesabı ve App Store Connect erişimi hazırla.
- [ ] Bundle ID, takım, signing/provisioning ve sürüm bilgilerini doğrula.
- [ ] Firebase iOS uygulama ayarlarını güncelle.
- [ ] Mevcut `GoogleService-Info.plist` içinde CLIENT_ID/REVERSED_CLIENT_ID;
      `Info.plist` içinde Google URL dönüş şeması yok. Doğru proje dosyasını indirip
      resmi Google Sign-In kurulumu ile tamamla; Android client ID'sini kullanma.
- [ ] Kamera/mikrofon/galeri/konum izin metinleri gerçek amaçlarla eşleşsin.
- [ ] Privacy manifest ve kullanılan SDK gereksinimleri kontrol edilsin.
- [ ] Üçüncü taraf girişle ilgili güncel Apple kuralları ve Sign in with Apple
      gerekliliği uygulamanın durumuna göre değerlendirilsin.
- [ ] Gerçek iPhone'da giriş, medya, izin ve hesap silme testleri yapılsın.
- [ ] TestFlight, App Privacy, içerik/yaş ve inceleme adımları tamamlansın.

Web yayını ayrıca ele alınır: `lib/firebase_options.dart` web için bilinçli olarak
UnsupportedError döndürür. Mobilin web'de otomatik hazır olduğu varsayılmaz.

## 15. Sonraki aşama — Premium ve 250 token satışı

İlk sürümde ödeme **yok**. Şunlar tamamlanmadan satış düğmeleri açılmaz:

- [ ] Üyelik süresi, fiyat, otomatik yenileme, eşleşme limiti ve paket koşullarını belirle.
- [ ] 250 token tek seferlik tüketilebilir ürün; sınırsız eşleşme uygun üyelik ürünü
      olarak mağaza politikalarına göre modellenmeli.
- [ ] Dijital ürünler için geçerli Play Billing / Apple IAP kurallarını doğrula.
- [ ] Satın alma makbuzu güvenilir sunucuda doğrulansın; istemcide başarı almak
      tek başına token/üyelik vermesin.
- [ ] Aynı satın almanın tekrar bildirimi tek kez işlensin; server notification,
      restore, iptal, yenileme ve iade/chargeback senaryoları test edilsin.
- [ ] Premium üyeliğin token paketini; token paketinin Premium'u kendiliğinden
      vermediği ürün ve veride tutarlı olsun.
- [ ] Ödeme/satıcı/vergi/mağaza sözleşmeleri ve destek süreçleri hazır olsun.
- [ ] Sandbox testleri tamamlanmadan gerçek para işlemi yapılmasın.

## 16. Sürüm operasyonu, otomasyon ve geri dönüş

- [ ] PR'da Flutter analiz/test ve Firebase emülatör kontrollerini çalıştıran CI ekle.
- [ ] CI'da emülatör testlerinin SKIP olmaması için Auth/Firestore/Storage birlikte başlatılsın.
- [ ] Flutter 3.41.5, Node 22 ve uygun Java sürümleri sabitlensin; lockfile korunmalı.
- [ ] İmzalama/dağıtım sırları GitHub Secrets veya uygun güvenli depoda tutulsun.
- [ ] Ücret doğurabilecek deploy işleri onay gerektiren ayrı workflow olsun;
      PR testi otomatik Firebase/mağaza yayını yapmasın.
- [ ] Yedekleme ve geri yükleme gereksinimi, erişim yetkisi ve maliyeti belirlensin.
- [ ] Log/çökme izleme çözümü ve veri/gizlilik/maliyet etkileri kararlaştırılsın.
- [ ] Hata durumunda mağaza dağıtımını durdurma, kullanıcıya iletişim ve düzeltme sürümü planlansın.
- [ ] Kuralları eski, daha geniş izinlere döndürerek token güvenliğini bozma.
- [ ] Yapılmış token transferi/hediyesi silinerek geri alma yapılmasın; finansal
      düzeltme gerekiyorsa denetlenebilir ayrı işlem tasarlansın.
- [ ] Her sürümde commit, AAB sürüm kodu, Firebase kural/işlev sürümü ve test tutanağı ilişkilendirilsin.

## 17. Komutlarla yerel doğrulama

Bu komutlar yerel geliştirme/test içindir; canlıya yayın yapmaz:

```bash
# Depo kökü
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub

# Functions
cd functions
npm ci
npm run check
./node_modules/.bin/firebase emulators:exec \
  --config ../firebase.emulators.json \
  --project demo-coetus --only auth,firestore,storage 'npm test'
```

- Sadece `npm test` çalıştırılırsa emülatör senaryoları atlanabilir; sıfır hata
  görmek tek başına yeterli değildir. Gerçek test sayısı ve SKIP sayısı kaydedilir.
- Bulut ortamında yazılabilir config/cache dizini gerekirse
  `XDG_CONFIG_HOME` ve `FIREBASE_EMULATORS_PATH` açıkça ayarlanır.
- `flutter analyze` sonucunda eski uyarılar varsa yeni sürümün değişikliklerinden
  ayrılmalı; yeni hatalar görmezden gelinmemelidir.
- Nihai çalıştırma sonuçları [doğrulama kaydına](doc/22-yayin-hazirligi-dogrulama.md) yazılır.

## 18. Üretime çıkış kapısı

Aşağıdakilerin tamamı kanıtla kapanmadan uygulama üretime hazır sayılmaz:

- [ ] Maliyet/backend kararı verilmiş, etkin özelliklerin sunucusu kullanılabilir.
- [ ] E-posta/Google girişi ve reset gerçek cihazda çalışıyor.
- [ ] İki yönde beceri uyumu doğrulanıyor; iki kişi de paylaşan ve öğrenen.
- [ ] Kişi bazında escrow atomik; tek onay çözüm yapmıyor, ortak tamamlama/iptal tutarlı.
- [ ] Escrow çözüm politikası kesinleşmiş ve test edilmiş; 50/20 hediyeler tek seferlik.
- [ ] Tek yönlü eski oturumların güvenli geçiş/sonuçlandırma planı uygulanmış.
- [ ] Özel mesajlar ve özel medya yetkisiz hesaba kapalı.
- [ ] Hesap silme gerçekten tamamlanıyor veya izlenen güvenli temizlik süreci var.
- [ ] Engelleme, şikâyet ve yönetim işlemleri çalışıyor; sorumlu kişi belirli.
- [ ] Gizlilik, silme ve kullanım koşulları erişilebilir, mağaza beyanları doğru.
- [ ] Gerçek release imzası, AAB, gerçek cihaz testleri ve mağaza hesabı hazır.
- [ ] İnceleme/test koşulları tamam; yayın build'i test edilen commit'ten üretilmiş.
- [ ] İzleme, destek ve geri dönüş sorumluları belirlenmiş.

## İlgili belgeler

- [Hesap silme ve tarihsel yayın notu](doc/14-hesap-silme.md)
- [Çevrimdışı önizleme](doc/15-ekran-onizleme.md)
- [İlgi alanı önerileri](doc/16-ilgi-alani-onerileri.md)
- [Eşleşme kutlaması](doc/17-eslesme-kutlamasi.md)
- [Premium taslağı](doc/18-premium-token-paketleri.md)
- [Başlangıç tokenı ve tarama](doc/19-yayin-taramasi-ve-baslangic-tokeni.md)
- [Google ve şifre sıfırlama](doc/20-google-giris-ve-sifre-sifirlama.md)
- [Gerçek cihaz test matrisi](doc/21-yayin-test-matrisi.md)
- [Bu dalın doğrulama kaydı](doc/22-yayin-hazirligi-dogrulama.md)

## Resmî başvuru kaynakları

Koşullar ve fiyatlar değişebileceği için uygulama yapılacağı gün konsol ve bu
kaynaklar tekrar kontrol edilmelidir; bağlantı listesi güncel uygunluk onayı değildir.

- [Firebase fiyatlandırma](https://firebase.google.com/pricing)
- [Firebase Storage plan değişiklikleri](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)
- [Flutter Firebase Google girişi](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [Flutter Firebase kullanıcı/şifre yönetimi](https://firebase.google.com/docs/auth/flutter/manage-users)
- [Flutter Android yayınlama](https://docs.flutter.dev/deployment/android)
- [Android hedef API gereksinimleri](https://developer.android.com/google/play/requirements/target-sdk)
- [Yeni kişisel Play hesapları için test gereksinimleri](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Google Play Billing](https://developer.android.com/google/play/billing)
- [Apple inceleme kuralları](https://developer.apple.com/app-store/review/guidelines/)
