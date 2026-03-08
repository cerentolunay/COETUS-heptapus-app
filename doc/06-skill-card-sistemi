# Skill Card (Yetenek Kartı) Sistemi

Heptapus platformunda kullanıcıların sahip olduğu ve öğrenmek istediği yetenekler **Skill Card (Yetenek Kartı)** sistemi ile temsil edilir.

Bu sistemin amacı:

- kullanıcıların yeteneklerini açık şekilde tanımlamak
- eşleşme algoritmasını basitleştirmek
- kullanıcıların yeni yetenekleri keşfetmesini sağlamak
- öğrenme ve öğretme süreçlerini düzenlemek

Skill Card sistemi platformun temel veri yapılarından biridir.

---

# 1. Skill Card Kavramı

Skill Card, platformdaki bir yeteneğin kullanıcı profilinde temsil edilme biçimidir.

Her kullanıcı:

- öğretebildiği yetenekleri
- öğrenmek istediği yetenekleri

kartlar aracılığıyla profilinde tanımlar.

Bir kullanıcının profili aslında bir **skill card koleksiyonu** olarak düşünülebilir.

Örnek kullanıcı profili:

## Öğretebildiği Yetenekler

- Guitar (Level 6)
- English (Level 5)

## Öğrenmek İstediği Yetenekler

- Python
- Public Speaking

---

# 2. Skill Card Veri Yapısı

Her skill card aşağıdaki bilgileri içerir.


SkillCard {
skillId
skillName
category
level
teachable
learnable
}


Alan açıklamaları:

skillId  
Yeteneğin sistem içindeki benzersiz kimliği

skillName  
Yeteneğin kullanıcıya görünen adı

category  
Yeteneğin ait olduğu kategori (Music, Language, Programming vb.)

level  
Yeteneğin seviyesi (1 ile 7 arasında)

teachable  
Kullanıcının bu yeteneği öğretebilip öğretemeyeceği

learnable  
Kullanıcının bu yeteneği öğrenmek isteyip istemediği

---

# 3. Kullanıcı Profilinde Skill Card Yapısı

Bir kullanıcı profilinde iki farklı skill kart listesi bulunur.


User {
teachSkills: []
learnSkills: []
}


## Teach Skills

Kullanıcının öğretebildiği yetenekler.

Örnek:


teachSkills = [
{ skill: Guitar, level: 6 },
{ skill: English, level: 5 }
]


## Learn Skills

Kullanıcının öğrenmek istediği yetenekler.

Örnek:


learnSkills = [
{ skill: Python },
{ skill: PublicSpeaking }
]


Bu ayrım eşleşme algoritmasını çok daha basit hale getirir.

---

# 4. Skill Card Tabanlı Eşleşme

Platformdaki eşleşmeler skill card bilgilerine göre oluşturulur.

Temel eşleşme kuralı:


UserA.teachSkills == UserB.learnSkills


Örnek:

User A


teach: Guitar


User B


learn: Guitar


Bu durumda eşleşme önerisi oluşturulur.

---

# 5. Skill Seviyesi Kullanımı

Skill seviyesi eşleşme kalitesini belirlemek için kullanılır.

Platformda seviye aralığı:


1 = başlangıç
7 = uzman


Örnek eşleşme:

Öğretici seviyesi:


Guitar Level 6


Öğrenci seviyesi:


Guitar Level 2


Seviye farkı:


6 - 2 = 4


Bu iyi bir öğretme ilişkisi oluşturur.

Algoritmada minimum seviye farkı şu şekilde tanımlanabilir:


TeacherLevel - StudentLevel >= 2


Bu sayede öğretme kalitesi korunur.

---

# 6. Discovery Sistemi

Skill Card sistemi keşif ekranının temelini oluşturur.

Discovery akışı şu şekilde çalışır:

1. Kullanıcı bir skill seçer
2. Sistem o skill'i öğreten kullanıcıları listeler
3. Kullanıcı profilleri incelenir
4. Teklif gönderilir

Örnek keşif akışı:


Skill Card seçimi → Öğretici listesi → Profil görüntüleme → Teklif gönderme


Örnek skill seçimi:


🎸 Guitar
🐍 Python
🗣 Public Speaking


Bir kart seçildiğinde ilgili öğreticiler listelenir.

---

# 7. Skill Graph Entegrasyonu

Skill Card sistemi Skill Graph yapısı ile birlikte çalışır.

Skill Graph, yetenekler arasındaki ilişkileri temsil eder.

Örnek ilişkiler:


Guitar → Music Theory
Python → Data Science
English → Public Speaking


Bu sayede platform kullanıcıya ilişkili yetenekler önerebilir.

Örnek öneri:

Kullanıcı şu skill'e sahipse:


Python


Sistem şu skillleri önerebilir:


Data Science
Machine Learning
Automation


---

# 8. Skill Card UI Tasarımı

Mobil uygulamada skill card aşağıdaki şekilde görünebilir.


┌─────────────────────┐
🎸 Guitar
Category: Music
Level: 6
Teaching Enabled
└─────────────────────┘


Discovery ekranında ise öğretici kartları şu şekilde gösterilebilir:


┌─────────────────────┐
🎸 Guitar Teacher
Level: 6
Trust Score: 82
Available
[View Profile]
└─────────────────────┘


---

# 9. Skill Card Sisteminin Avantajları

Skill Card sistemi aşağıdaki avantajları sağlar:

- veri modelini basitleştirir
- eşleşme algoritmasını hızlandırır
- kullanıcı arayüzünü sadeleştirir
- yeni skill önerileri üretmeyi kolaylaştırır
- öğrenme yolları oluşturmayı mümkün kılar

Bu sistem sayesinde platformda hem öğretme hem öğrenme süreçleri daha düzenli bir şekilde yönetilebilir.

---

# 10. Gelecek Geliştirmeler

Skill Card sistemi ilerleyen sürümlerde aşağıdaki özelliklerle geliştirilebilir:

- AI tabanlı skill öneri sistemi
- kişisel öğrenme haritası
- skill ilerleme takibi
- kullanıcı öğrenme grafiği
- otomatik öğrenme yolu oluşturma

Bu geliştirmeler platformun daha akıllı ve kişiselleştirilmiş bir öğrenme ekosistemine dönüşmesini sağlamalı.
