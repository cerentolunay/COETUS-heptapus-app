# 1. COETUS ürün mimarisi

Bunu sistem mantığı olarak düşün:

## A. Authentication

Kullanıcının sisteme giriş yapması

Alt fonksiyonlar:

giriş yap
kayıt ol
şifre sıfırla
oturum kontrolü
çıkış yap

## B. Onboarding

Kullanıcının ilk kurulum süreci

Alt fonksiyonlar:

ilgi alanı seçme
yetenek ekleme
ihtiyaç alanı seçme
müsait zaman girme
profil başlangıç ayarları

## C. Profile

Kullanıcının kendi kimliği ve yetkinlikleri

Alt fonksiyonlar:

profil görüntüleme
profil düzenleme
yetenek listesi
öğrenmek istedikleri
uygun zamanlar
kredi bakiyesi
geçmiş işlemler

## D. Matching

Kimin kiminle eşleşeceği

Alt fonksiyonlar:

önerilen kişiler
filtreleme
kullanıcı kartı
detay görüntüleme
match isteği gönderme
gelen/giden eşleşme istekleri

## E. Exchange

Asıl iş mantığı burada

Alt fonksiyonlar:

takas isteği oluşturma
zaman kredisi mantığı
kabul / reddetme
aktif exchange
tamamlanan exchange
puan / kredi güncelleme
geçmiş kayıtları

## F. Chat

Eşleşen ya da işlem başlatan kullanıcıların iletişimi

Alt fonksiyonlar:

sohbet listesi
sohbet detay ekranı
mesaj gönderme
mesaj okundu bilgisi
sistem mesajları
exchange bağlantılı konuşmalar

## G. Notifications

Sistem olaylarının kullanıcıya iletilmesi

Alt fonksiyonlar:

yeni eşleşme bildirimi
yeni mesaj bildirimi
exchange kabul / reddedildi bildirimi
sistem duyuruları

Auth
  ↓
Onboarding
  ↓
Profile setup
  ↓
Matching
  ↓
Exchange request
  ↓
Chat
  ↓
Completion + credit update
  ↓
Notifications