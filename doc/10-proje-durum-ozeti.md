# 10. Proje Durum Özeti (Repo Summary)

> Bu dosya, repo'nun 2026-08-11 tarihli anlık durumunu özetler (origin/main
> `762ab38` — `git pull` ile senkronize edildi). Bundan sonraki geliştirme
> planlaması bu dosyadaki tablo ve boşluk listesi üzerinden şekillendirilecektir.
> Kod ilerledikçe bu dosya güncellenmelidir.

## 1. Proje Kimliği

- Paket adı: `coetus` (pubspec.yaml). README ve doc/01'de ürün adı **Heptapus**
  olarak geçiyor; doc/01'de ayrıca "isim bulamadık hala fikirlerinizi
  iletebilirsiniz" notu var → **isimlendirme henüz netleşmemiş** (Coetus/Heptapus
  arada kalmış durumda, karar bekliyor).
- Ekip: 8 kişilik öğrenci ekibi, 45 günlük MVP süreci (doc/03).
- İş modeli: "Öğret → Kredi Kazan → Öğren" — peer-to-peer yetenek takası,
  zaman/kredi bazlı ekonomi, kurs ücretlerine alternatif.

## 2. Teknik Yığın

- **Flutter** (SDK `^3.10.4`), state management: `flutter_riverpod ^2.5.1`
- Routing: `go_router ^14.2.0`
- Backend: `firebase_core`, `firebase_auth`, `cloud_firestore` (^5.x), `google_sign_in`
- Yerel depolama / fallback: `shared_preferences`
- Test: `flutter_test` + `flutter_lints` (kapsam çok sınırlı, bkz. §6)
- Uygulama ikonu üretimi: `flutter_launcher_icons ^0.14.4` (dev dependency) —
  `assets/icons/app_icon.png` kaynağından android/ios/macos/windows/web için
  ikon setleri üretiliyor (commit `762ab38`).

## 3. Mimari

- Feature-based klasörleme: `lib/features/<feature>/{data,domain,presentation}`
- **Repository Factory Pattern**: her feature'da `XRepositoryFactory.create()`
  Firebase başlatılmışsa (`Firebase.apps.isNotEmpty`) `FirebaseXRepository`,
  değilse `LocalXRepository` döndürüyor. Bu, Firebase olmadan da (mock/offline)
  geliştirme ve test yapılabilmesini sağlıyor — auth, chat, exchange,
  notifications, profile modüllerinin hepsinde tekrarlanan bir desen.
- Routing guard'ları `app_router.dart` içinde: auth durumu ve profil tamamlanma
  durumu birlikte dinlenip (`_CombinedNotifier`) korumalı rotalara yönlendirme
  yapılıyor (`publicRoutes` / `protectedRoutes` / `complete-profile` akışı).

## 4. Modül Bazlı Durum

| Modül | Doküman referansı | Kod durumu | Not |
|---|---|---|---|
| Auth | doc/07-A | `login/register/forgot_password/auth_profile` sayfaları, Firebase+Local repo | Tamamlanmış görünüyor |
| Onboarding | doc/07-B | `splash/welcome/onboarding_intro/discovery_test` | Splash & welcome üzerinde şu an commit edilmemiş değişiklik var (§7) |
| Profile & Skill Card | doc/06 | `skill_profile/edit_profile/complete_profile/advanced_skill_profile/other_user_profile`, `skill_model.dart`, `profile_completion_service` | Skill card veri yapısı (teachable/learnable/level) uygulanmış. `SkillProfilePage`'e öğrenme hedefleri (learning goals) için düzenle/sil diyalogları eklendi (`762ab38`) — artık learn skill'ler için tam CRUD var |
| Matching | doc/05 §1, doc/08 §1 | `matching_service.dart`, `matching_score_calculator.dart`, `match_candidate/match_explanation` modelleri | Ağırlıklı skor formülü (0.4/0.3/0.2/0.1) ve `explanation` alanı dokümanla birebir örtüşüyor |
| Exchange (Session) | doc/07-E | `exchange_session.dart`, `match_offer.dart`, repo + `exchange_page.dart` | UI ve model var |
| Chat | doc/07-F | `firebase_chat_repository.dart` (gerçek zamanlı Firestore, commit `2463bf4`), local fallback, `chat_list_page` katılımcıya göre dedup ediyor | Arama kutusu eklendi (`1bcae65`) — sohbet listesi artık isimle filtrelenebiliyor. Aktif geliştirme alanı |
| Credit & Escrow | doc/05 §2, doc/08 §4 | `credit_calculator.dart`, `escrow_service.dart`, `escrow_record/escrow_status` | **`escrow_service.dart` sadece in-memory bir durum makinesi** (`pending→locked→completed/refunded/cancelled`); gerçek Firestore transaction, bakiye düşme/aktarma işlemi kodda YOK. doc/09 bunu zaten "UI mock" olarak işaretlemiş — doğrulandı. |
| Trust Score | doc/05 §3, doc/08 §3 | `trust_score_calculator.dart`, `trust_score_service.dart`, `trust_activity_summary.dart` | Formül uygulanmış; gerçek session/verification verisinden otomatik güncelleme henüz backend'e bağlı değil (doc notu) |
| Skill Graph | doc/05 §4, doc/08 §5 | `skill_graph_service.dart`, `skill_graph_edge.dart`, `skill_recommendation.dart` | Matching için opsiyonel katman; graph verilmezse sistem exact-match'e düşüyor |
| Notifications | doc/07-G | Firebase + Local repo, `notifications_page.dart` | Var |

## 5. Firestore Güvenlik Kuralları

- Kökte `firestore.rules` mevcut.
- doc/09'a göre bu dosya "taslağın çalışan ilk hali" — production öncesi hedef:
  `credits/trustScore/verified` gibi alanların client tarafından yazılamaması,
  `transactions`/`escrows` koleksiyonlarında client write'ın tamamen kapalı
  olması. **Bu dosyanın güncel içeriği bu oturumda satır satır doğrulanmadı** —
  bir sonraki teknik incelemede öncelik olarak ele alınmalı.

## 6. Test Kapsamı

- Sadece iki test dosyası var: `test/widget_test.dart`, `test/matching_algorithm_test.dart`.
- Auth, escrow/credit, trust score, chat, exchange için birim/entegrasyon testi yok.

## 7. Git Durumu (bu oturumdaki anlık görüntü)

- `main` branch, `git pull` ile origin/main (`762ab38`) ile senkronize edildi.
  İlk özet yazılırken local, origin'in **3 commit gerisindeydi** — bu dosyanın
  ilk taslağı bu 3 commit çekilmeden yazılmıştı, sonradan fark edilip
  düzeltildi (bkz. §9 not).
- Pull ile gelen son 3 commit:
  - `762ab38` — kod okunabilirliği için refactor + `flutter_launcher_icons`
    entegrasyonu (uygulama ikonları tüm platformlar için üretildi)
  - `1bcae65` — `ChatListPage`'e arama işlevi, `meta` paket versiyonu güncellendi
  - `b186635` — `SkillProfilePage`'de öğrenme hedefleri için düzenle/sil
- Öncesindeki aktif geliştirme alanı: matching/discovery/profile/escrow
  özelliği (PR #18–20), gerçek zamanlı Firestore chat (PR #12–15, `2463bf4`)
  ve bildirimler.
- Commit edilmemiş değişiklikler (pull sonrası da korunuyor, stash ile taşındı):
  `splash_page.dart` ve `welcome_page.dart` artık placeholder ikon yerine
  `assets/images/logo.png` kullanıyor; `pubspec.yaml`'a bu asset kaydedilmiş.
  `assets/images/logo.png` hâlâ untracked. Bu, `flutter_launcher_icons` ile
  gelen `assets/icons/app_icon.png`'den **ayrı** bir logo entegrasyonu —
  ikisi çakışmıyor ama aynı görsel kaynağın iki farklı asset klasöründe
  (`assets/icons/` vs `assets/images/`) yönetildiği görülüyor, ileride
  tekilleştirme değerlendirilebilir.
- `doc/10-proje-durum-ozeti.md` (bu dosya) de henüz commit edilmedi.

## 8. Bilinen Boşluklar ve Riskler

Aşağıdakiler **doğrulanmış gözlemlerdir** (varsayım değildir):

1. **Kredi/escrow gerçek para hareketi yok.** `EscrowService` sadece durum
   geçişlerini simüle ediyor; gerçek bakiye güncellemesi, kilitleme, transfer
   yok. Doc/09'un işaret ettiği gibi bu, backend (Cloud Functions veya
   Firestore transaction) ile çözülmesi gereken en kritik boşluk —
   dolandırıcılık/çift harcama riski MVP açısından burada yoğunlaşıyor.
2. **Trust score otomatik güncellenmiyor** — hesaplama formülü var ama gerçek
   session/doğrulama olaylarına bağlı tetikleme yok.
3. **Test kapsamı çok düşük** — kritik iş mantığı (escrow, credit, trust score)
   için otomatik test yok, regresyon riski var.
4. **Ürün adı netleşmemiş** (Heptapus/Coetus) — bu bir teknik risk değil ama
   marka/dokümantasyon tutarlılığı için karar bekliyor.
5. **Security rules'un production hazırlığı doğrulanmadı** (§5).

## 9. Bundan Sonraki Planlama İçin Kullanım

Bu dosya, projeye dair sonraki tüm çalışma planının referans noktası olacak:

- Yeni bir istek geldiğinde önce §4'teki tabloya bakılıp hangi modülü
  etkilediği belirlenecek.
- §8'deki boşluklar, öncelik sırasına göre plan kalemlerine dönüştürülecek
  (özellikle kredi/escrow backend'i, en yüksek risk kalemi olarak önerilir).
- Kod tabanında önemli bir özellik tamamlandığında veya birleştiğinde, bu
  dosyanın ilgili bölümü güncellenmelidir.
- **Süreç notu:** Bu dosyanın ilk taslağı yazılırken `origin/main` fetch
  edilmemişti ve local'in 3 commit geride olduğu fark edilmemişti. Bundan
  sonra bu tür bir özet/analiz talebinde önce `git fetch` + durum kontrolü
  yapılacak, gerekirse `git pull` ile güncellenip sonra dosya yazılacak.
