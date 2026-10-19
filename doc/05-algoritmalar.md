# Heptapus Algoritmalar Dokümanı

Bu doküman, Heptapus platformunda kullanılan temel algoritmaları açıklamaktadır.

Platformun ana amacı, kullanıcıların sahip oldukları yetenekleri paylaşarak kredi kazanmasını ve bu kredileri kullanarak yeni yetenekler öğrenmesini sağlamaktır.

Bu hedef doğrultusunda sistem üç temel algoritma üzerine kurulmuştur:

1. Kullanıcı Eşleşme Algoritması (Matching Algorithm)
2. Kredi Hesaplama Algoritması (Credit Calculation)
3. Güven Skoru Algoritması (Trust Score)

Bu algoritmalar platformun adil, güvenli ve sürdürülebilir çalışmasını sağlar.

---

# 1. Matching Algoritması

Matching algoritmasının amacı, kullanıcıların sahip olduğu yetenekler ile öğrenmek istedikleri yetenekler arasında en uygun eşleşmeleri oluşturmaktır.

Algoritma aşağıdaki kriterleri kullanır:

- Skill uyumu
- Skill seviyesi farkı
- Kullanıcı güven skoru
- Müsaitlik uyumu
- Profil tamamlanma oranı

Bu kriterler belirli ağırlıklarla birleştirilerek toplam eşleşme skoru hesaplanır.

---

## 1.1 Skill Uyumu

Eşleşmenin oluşabilmesi için bir kullanıcının öğretmek istediği skill ile diğer kullanıcının öğrenmek istediği skill aynı olmalıdır.

Örnek:

Kullanıcı A  
öğretiyor: Guitar

Kullanıcı B  
öğrenmek istiyor: Guitar

Bu durumda skill uyumu sağlanır.

Skill uyumu eşleşme algoritmasının en temel kriteridir.

- yapay zeka tabanlı öneri sistemi
- öğrenme geçmişi analizi
- kullanıcı öğrenme grafiği
- skill ilerleme takibi
- kişisel öğrenme haritası

SkillMatch = 1 (uyum varsa)
SkillMatch = 0 (uyum yoksa)


---

## 1.2 Skill Seviyesi Uyumu

Platformda skill seviyeleri 1 ile 7 arasında tanımlanır.


1 = başlangıç
7 = uzman


Eğitimin verimli olabilmesi için öğretici ile öğrenci arasında belirli bir seviye farkı olması gerekir.

Örnek:

Öğretici seviyesi: 6  
Öğrenci seviyesi: 2

Seviye farkı: 4

Seviye farkı çok küçükse öğretme değeri düşer.  
Seviye farkı çok büyükse öğrenme verimliliği azalabilir.

Bu nedenle aşağıdaki formül kullanılır:


SkillScore = min((TeacherLevel - StudentLevel) / 5 , 1)


---

## 1.3 Güven Skoru

Platform güvenilir kullanıcıların daha fazla eşleşmesini teşvik eder.

Bu nedenle kullanıcıların TrustScore değeri eşleşme algoritmasına dahil edilir.

İki kullanıcının güven skoru ortalaması alınır.


TrustScore = (UserTrust + PartnerTrust) / 2


---

## 1.4 Müsaitlik Uyumu

Kullanıcıların uygun zamanlarının örtüşmesi gerekir.

Örnek:

User A  
Pazartesi akşam müsait

User B  
Pazartesi akşam müsait

Bu durumda AvailabilityScore = 1

Eğer uygun zaman çakışmıyorsa:


AvailabilityScore = 0


---

## 1.5 Profil Tamamlanma Oranı

Profil bilgileri eksik olan kullanıcıların eşleşme önceliği düşürülür.

Profil tamamlanma oranı aşağıdaki kriterlere göre hesaplanır:

- profil fotoğrafı
- biyografi
- skill bilgileri
- doğrulama


ProfileCompleteness = 0 - 1 arası değer


---

## 1.6 Toplam Eşleşme Skoru

Tüm kriterler ağırlıklı olarak birleştirilir.


MatchScore =
0.4 × SkillScore

0.3 × TrustScore

0.2 × AvailabilityScore

0.1 × ProfileCompleteness


En yüksek MatchScore değerine sahip kullanıcılar önerilir.

---

# 2. Kredi Hesaplama Algoritması

Platformda kullanıcılar ders vererek kredi kazanır.

Her skill için bir **temel kredi değeri (BaseCredit)** bulunur.

Örnek:


Guitar dersi = 30 kredi
English konuşma = 20 kredi
Coding dersi = 40 kredi


---

## 2.1 Usta Çırak Katsayısı

Skill seviyesi yüksek olan kullanıcıların daha fazla kredi kazanması hedeflenir.

Bu nedenle kredi hesaplamasında bir katsayı uygulanır.


EarnedCredits = BaseCredit × (SkillLevel / 3)


Örnek:


BaseCredit = 30
SkillLevel = 6

EarnedCredits = 30 × (6 / 3)
EarnedCredits = 60


---

## 2.2 Session Tamamlama Süreci

> 19 Ekim 2026 ürün düzeltmesi: Bu bölüm eski tek yönlü öğretici/öğrenci modelini
> anlatır. Güncel hedef, iki kişinin de hem paylaşıp hem öğrendiği karşılıklı
> takas ve katılımcı bazlı escrow'dur. Mevcut kod da dönüşüm gerektirir.
> [Güncel dönüşüm planı](../YAYIN_YOL_HARITASI.md).


Kredi transferi yalnızca ders tamamlandıktan sonra gerçekleşir.

Session akışı:

1. Öğrenci ders talebi gönderir
2. Öğretici talebi kabul eder
3. Kredi escrow sistemine kilitlenir
4. Ders tamamlanır
5. Kredi öğreticiye aktarılır

Bu sistem dolandırıcılığı önlemek için kullanılır.

---

# 3. Trust Score Algoritması

Trust Score, kullanıcıların platformdaki güvenilirliğini ölçen bir metriktir.

Trust Score değeri 0 ile 100 arasında hesaplanır.

---

## 3.1 Tamamlanan Session Sayısı

Kullanıcı tamamladığı ders sayısına göre güven kazanır.


SessionScore = min(SessionCount × 2 , 40)


Maksimum katkı: 40 puan

---

## 3.2 Kullanıcı Doğrulaması

Kimliği doğrulanmış kullanıcılar daha güvenilir kabul edilir.

Doğrulama türleri:

- video doğrulama
- portfolyo doğrulama
- sosyal medya doğrulama

Her doğrulama:


+10 puan


Maksimum doğrulama katkısı:


30 puan


---

## 3.3 İptal Oranı

Kullanıcı tarafından iptal edilen sessionlar güven skorunu düşürür.


CancellationPenalty = CancelledSessions × 5


---

## 3.4 Final Trust Score

Son güven skoru aşağıdaki şekilde hesaplanır.


TrustScore =
SessionScore

VerificationScore

CancellationPenalty


Sonuç değeri 0 ile 100 arasında normalize edilir.

---

# 4. Skill Graph Sistemi

Heptapus platformunda yetenekler birbirinden tamamen bağımsız değildir.

Birçok yetenek başka yeteneklerle ilişkilidir.

Örnek:


Guitar → Music Theory
Python → Data Science
English → Public Speaking


Bu nedenle platformda yetenekler arasında bir **Skill Graph (Yetenek Ağı)** oluşturulmaktadır.

---

## 4.1 Skill Node Yapısı

Her skill bir node olarak temsil edilir.


Skill {
id
name
category
difficulty
}


---

## 4.2 Skill Edge Yapısı

Skilller arasındaki bağlantılar edge olarak tutulur.


SkillEdge {
fromSkill
toSkill
relationStrength
}


Örnek:


Python → DataScience (0.9)
Guitar → MusicTheory (0.8)
English → PublicSpeaking (0.6)


relationStrength değeri 0 ile 1 arasındadır.

---

## 4.3 Skill Graph Kullanım Alanları

Skill graph üç farklı amaç için kullanılır.

### Skill Öneri Sistemi

Kullanıcı bir skill öğrendiğinde ilişkili skilller önerilir.


RecommendedSkillScore =
UserSkillLevel × relationStrength


---

### Öğrenme Yolu Oluşturma

Platform kullanıcıya önerilen öğrenme sırasını gösterebilir.

Örnek:


Python
Data Analysis
Machine Learning
Deep Learning


---

### Eşleşme Algoritmasını Güçlendirme

Kullanıcılar sadece aynı skill üzerinden değil ilişkili skilller üzerinden de eşleşebilir.

Örnek:

User A öğretiyor: Guitar  
User B öğrenmek istiyor: Music Theory

Graph bağlantısı olduğu için sistem eşleşme önerebilir.

---

# 5. Gelecek Geliştirmeler

Algoritma sistemi ilerleyen sürümlerde aşağıdaki özelliklerle geliştirilebilir:

- yapay zeka tabanlı öneri sistemi
- öğrenme geçmişi analizi
- kullanıcı öğrenme grafiği
- skill ilerleme takibi
- kişisel öğrenme haritası
