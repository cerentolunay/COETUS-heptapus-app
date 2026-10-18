# Gerçek cihaz yayın test matrisi

Bu dosyadaki testler **fiziksel cihazda yapılmış sayılmaz**. Yerel Flutter/Firebase
sonuçları `22-yayin-hazirligi-dogrulama.md` içindedir. Her satır gerçek sürümle
denenerek sonuç, tarih ve kanıt bağlantısıyla kapatılmalıdır.

## Test kaydı

- Commit / dal:
- APK/AAB sürümü ve build numarası:
- Firebase proje ve kural/işlev sürümü:
- Cihaz 1 / Android / model:
- Cihaz 2 / Android / model:
- Test hesapları A/B/C (kişisel bilgi yerine takma ad):
- Testçi / tarih:
- Ağ koşulları:
- Açık hata kayıtları:

Sonuç seçenekleri: **Geçti / Başarısız / Bloke / Kapsam dışı**. Boş kutu veya
"Bekliyor" geçilmiş test değildir. Kapsam dışı için ürün kararı yazılır. Test
hesaplarında gerçek kişilerin özel mesajları/medyası kullanılmaz.

## A. Kurulum, giriş ve oturum

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| A01 | Yeni release APK kur | Doğru ad/ikon; önizleme banner'ı yok | Bekliyor |
| A02 | İlk açılış/yönlendirme | Açılış → onboarding/login doğru akış | Bekliyor |
| A03 | E-posta ile yeni kayıt | Tek Auth hesabı ve doğru profil oluşur | Bekliyor |
| A04 | Mevcut e-postayla kayıt | Anlaşılır hata; eski bakiye/profil değişmez | Bekliyor |
| A05 | Yanlış/boş parola ve e-posta | Doğrulama veya anlaşılır hata | Bekliyor |
| A06 | Doğru e-posta/şifreyle giriş | Aynı hesaba girilir; profil korunur | Bekliyor |
| A07 | Yeni Google hesabı | Hesap seçilir, doğru Firebase kullanıcısı/profili | Bekliyor |
| A08 | Mevcut Google hesabı | Yeni kopya profil oluşmaz, bakiye sıfırlanmaz | Bekliyor |
| A09 | Google seçimini iptal et | Başarı gösterilmez, yeniden giriş mümkün | Bekliyor |
| A10 | Google seçiminde 15 sn'den uzun bekle | Sırf seçim süresi yüzünden giriş kesilmez | Bekliyor |
| A11 | Debug/upload/Play imzası | Dağıtılacak sertifikaların her birinde Google giriş | Bekliyor |
| A12 | Ağ kesintisi / servis izni hatası | Doğru hata; sahte başarı/sonsuz yükleme yok | Bekliyor |
| A13 | Çıkış, yeniden giriş ve uygulamayı öldür/aç | Doğru hesap ve oturum; hediye tekrarı yok | Bekliyor |
| A14 | Google/e-posta yöntem çakışması | Mevcut hesabı kaybetmeden anlaşılır yönlendirme | Bekliyor |

## B. Şifre sıfırlama

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| B01 | Geçerli şifreli hesabın e-postası | Gerçek posta teslim edilir; spam da kontrol | Bekliyor |
| B02 | Reset bağlantısını aç/yeni parola belirle | Eski parola reddedilir, yeni parola çalışır | Bekliyor |
| B03 | Boş/bozuk e-posta | Gönderim yapılmaz, alan hatası | Bekliyor |
| B04 | Seri dokunma | Eşzamanlı ikinci gönderim yok | Bekliyor |
| B05 | Gönderimde ağ/kota hatası | Başarı ekranı yok, hata ve tekrar deneme | Bekliyor |
| B06 | Kayıtsız veya Google-only adres | Hesap varlığı ifşa edilmez; Google yönlendirmesi | Bekliyor |
| B07 | Süresi geçmiş/kullanılmış reset bağlantısı | Güvenli hata; yeni bağlantı istenebilir | Bekliyor |
| B08 | Çevrimdışı önizleme | Gerçek e-posta gönderilmez, açık uyarı | Bekliyor |

## C. Profil, ilgi alanı ve seviye

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| C01 | Giriş ve profil tamamlamada ilgi alanları | Aynı kartlar ve katalog | Bekliyor |
| C02 | Müzik kartına dokun | Hemen ilgili satır altında Gitar/Piyano vb. açılır | Bekliyor |
| C03 | Birden fazla dal aç/kapat | Diğer seçimler kaybolmaz | Bekliyor |
| C04 | Gitar seç → öğren/paylaş | Gerçek alt beceri ve doğru amaç kaydedilir | Bekliyor |
| C05 | Paylaş işaretle | Ortak mor/lime seviye penceresi açılır | Bekliyor |
| C06 | Kaydırıcıyı değiştir → Kaydet | Tam sayı 1–7; seçilen seviye korunur | Bekliyor |
| C07 | Pencerede değiştir → Vazgeç/geri | Önceki seçim/seviye değişmez | Bekliyor |
| C08 | Girişten profil formuna ilerle | Seçilen beceriler/amaç/seviye taşınır | Bekliyor |
| C09 | Son kayıtta ağ hatası | Profil yanlışlıkla tamamlanmış sayılmaz, seçimler kalır | Bekliyor |
| C10 | İsimsiz/geçersiz profil | Gerekli alan kontrolü; opsiyoneller boş kalabilir | Bekliyor |
| C11 | Konum iznini reddet/kalıcı reddet/servisi kapat | Elle giriş veya boş bırakma mümkün | Bekliyor |
| C12 | Konuma izin ver | Şehir/ülke; sürekli koordinat takibi yok | Bekliyor |
| C13 | Profil/öğretilecek/öğrenilecek beceri düzenle | Yeni bilgiler yeniden girişte korunur | Bekliyor |
| C14 | Aynı becerinin farklı harf/yazımları | Türkçe normalizasyon doğru, gereksiz kopya yok | Bekliyor |

## D. İlgi önerisi ve yönetici

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| D01 | Ekle ile yeni öneri | Bekleyen kayıt, gönderim sonucu | Bekliyor |
| D02 | Başka normal hesap bekleyen öneriyi oku | Erişim reddi; genel katalogda görünmez | Bekliyor |
| D03 | Normal hesap kendi önerisini onayla | Reddedilir | Bekliyor |
| D04 | Yönetici öneriyi onayla | İki ilgi ekranında da görünür | Bekliyor |
| D05 | Yönetici reddet | Diğer kullanıcılara yayınlanmaz | Bekliyor |
| D06 | Aynı öneriyi tekrar gönder | Kontrolsüz kopya/çoklu yayın oluşmaz | Bekliyor |
| D07 | Yönetici rolünü kaldır/çıkış-giriş | Yetkisiz işlem ve yönetim erişimi kapanır | Bekliyor |

## E. Token, eşleşme ve emanet

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| E01 | Yeni hesap ilk giriş | Welcome makbuzu + tam 50 token | Bekliyor |
| E02 | Eski 37 tokenlı hesap, welcome makbuzu yok | 87 olur; bakiye sıfırlanmaz | Bekliyor |
| E03 | Yeniden giriş/aynı anda iki cihaz | Welcome bir kez; toplam tekrar artmaz | Bekliyor |
| E04 | İstemciden bakiye/tutar/makbuz değiştir | Reddedilir | Bekliyor |
| E05 | İlk 50 ile 30 tokenlık teklif kabulü | 20 kullanılabilir, 30 kilitli; önceki eşleşme gerekmez | Bekliyor |
| E06 | Teklif oluştur | Kabul öncesi token düşmez | Bekliyor |
| E07 | Yanlış kişi/kendi teklifi kabul etsin | Reddedilir | Bekliyor |
| E08 | Yetersiz bakiye veya yarışan kabuller | Negatif bakiye/çift kilit oluşmaz | Bekliyor |
| E09 | İlk eşleşme kutlaması | Kabul eden ve bildirimden gelen kişi erişebilir | Bekliyor |
| E10 | İlk eşleşme hediyesi | Uygun hesapta ayrı bir kez 20 token | Bekliyor |
| E11 | Kutlamayı tekrar aç/aynı anda talep et | İkinci 20 verilmez | Bekliyor |
| E12 | Oturumu yetkili öğrenci tamamlasın | Kilit çözülür, öğretmene bir kez aktarılır | Bekliyor |
| E13 | Yetkisiz kişi tamamlasın | Reddedilir | Bekliyor |
| E14 | Tek taraf iade isteği | Hemen token aktarılmaz | Bekliyor |
| E15 | İki taraf iade onayı | Bir kez iade, çift ödeme yok | Bekliyor |
| E16 | Aynı oturuma tamamlama/iade yarışması | Tek, tutarlı finansal sonuç | Bekliyor |
| E17 | Önizleme kutlaması | Örnek hediye açıkça belirtilir; gerçek bakiye değişmez | Bekliyor |

## F. Sohbet, topluluk, medya ve moderasyon

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| F01 | A/B sohbeti, C hesabıyla okuma/yazma | C reddedilir | Bekliyor |
| F02 | A/B mesajlaşma ve yeniden açma | Mesaj/sıralama/okundu durumu tutarlı | Bekliyor |
| F03 | Ağ yokken mesaj ve tekrar bağlantı | Kayıp/yanlış başarı/çift gönderim anlaşılır yönetilir | Bekliyor |
| F04 | Fotoğraf/video seç/yükle | İzin, tür ve boyut kontrolleri | Bekliyor |
| F05 | Özel/yayınlanmamış medya URL erişimi | Yetkisiz hesaba kapalı | Bekliyor |
| F06 | Topluluk paylaşımı, kalp ve yorum | Doğru sayaç, tekrarda çift kayıt yok | Bekliyor |
| F07 | Token desteği tekrarı/yarışı | Bir kez borç/alacak, negatif bakiye yok | Bekliyor |
| F08 | Sahibi içeriği silsin, başkası silmeye çalışsın | Sahibi kaldırabilir, yetkisiz kişi reddedilir | Bekliyor |
| F09 | Portföy şikâyeti | Yönetilebilir şikâyet kaydı oluşur | Bekliyor |
| F10 | Kullanıcı/mesaj/paylaşım şikâyeti | Geliştirme tamamlandıktan sonra gerçek yönetim akışı | Bloke: eksik geliştirme |
| F11 | Engelle/engeli kaldır | Mesaj/teklif/keşif davranışı ve sunucu koruması | Bloke: eksik geliştirme |
| F12 | Yönetici şikâyeti çözsün | Yetki, kayıt ve içerik/hesap sonucu doğrulanır | Bloke: eksik geliştirme |

## G. Hesap silme

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| G01 | Silme penceresini iptal et | Hiçbir veri değişmez | Bekliyor |
| G02 | E-posta/Google yeniden doğrulaması | Doğru hesap ve güncel doğrulama gerekir | Bekliyor |
| G03 | Kilitli token varken sil | Önce oturumu sonuçlandırma mesajı; para korunur | Bekliyor |
| G04 | Uygun hesabı sil | Auth + profil + kişisel veriler/medya temizlenir | Bekliyor |
| G05 | Silme sırasında ağ kes/yinele | Tekrarlanabilir temizlik; durum izlenebilir | Bekliyor |
| G06 | Silinen kişinin katkıları | Sayaçlar düzelir, ortak geçmiş politikaya uygun | Bekliyor |
| G07 | Eski tokenla tekrar yaz/hediye al | Reddedilir | Bekliyor |
| G08 | Başkasının UID'sini silme isteğine ekle | Başkasının hesabı etkilenmez | Bekliyor |
| G09 | Web hesap silme talep yolu | Erişilebilir, destek süreci gerçekten işler | Bekliyor |

## H. Premium, görsellik ve yayın paketi

| ID | Senaryo | Beklenen davranış | Durum |
|---|---|---|---|
| H01 | Profil/keşfet token göstergesine dokun | Aynı Premium sayfası; geri doğru ekrana | Bekliyor |
| H02 | Sınırsız eşleşme / 250 token | İki ayrı teklif; fiyat uydurulmaz | Bekliyor |
| H03 | Yakında düğmeleri | Pasif; ödeme/üyelik/bakiye değişikliği yok | Bekliyor |
| H04 | Maskota dokun | Zıplar; normal açılış yönlendirmesi korunur | Bekliyor |
| H05 | Açılış boş alanlarına dokun | Kırmızı kalp/pırıltı; seri dokunmada kaynaklar sınırlı | Bekliyor |
| H06 | Eşleşme kalbi ve halkalar | Akıcı animasyon; profiller yuvarlak ve dokunulabilir | Bekliyor |
| H07 | Hareket azaltma | Dekoratif hareketler durur/azalır | Bekliyor |
| H08 | Küçük ekran/büyük yazı/klavye | Taşma yok; önemli düğmeler erişilebilir | Bekliyor |
| H09 | Politika ve destek bağlantıları | Gerçek, erişilebilir HTTPS içerik | Bekliyor |
| H10 | Play'den kurulan son AAB | Doğru sertifika, API/izinler, gerçek Google girişi | Bekliyor |
| H11 | Ön lansman raporu / soğuk başlangıç | Kritik çökme/uyumsuzluk yok | Bekliyor |

## Hata kaydı şablonu

- Test ID:
- Beklenen / gerçekleşen:
- Tekrarlama adımları:
- Cihaz/Android/build/commit:
- Ağ ve izin durumu:
- Gizlilikten arındırılmış ekran görüntüsü veya hata kodu:
- Önem: kritik / yüksek / orta / düşük:
- Sorumlu / düzeltme commit'i:
- Yeniden test sonucu:

Parola, Google erişim tokenı, Admin anahtarı veya başka kullanıcının özel verisi
hata kaydına eklenmez. Üretimden alınmış veriler gerekiyorsa izin ve gizlilik
süreci belirlenmeden GitHub'a konmaz.
