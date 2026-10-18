# Premium ve token paketleri

Kullanıcıya görünen para birimi adı uygulamada “token”dır. Mevcut `credits`
veritabanı alanı ve API isimleri korunur; veri göçü gerekmez.

Profilde TOKEN istatistiğine, hesap profilindeki Token satırına veya ortak token
rozetine (keşfet üst barı dahil) dokununca `/premium` açılır. Geri düğmesi geldiği
ekrana döner; doğrudan açılışta Keşfet'e yönlenir. Rota normal uygulamada oturum ve
profil kontrolüne tabidir; çevrimdışı önizleme galerisinde de kullanılabilir.

İki paket tanıtılır:
- Sınırsız eşleşme: Premium üyelik, token içermez.
- 250 token: tek seferlik bakiye paketi, Premium üyelik içermez.

Fiyat, üyelik süresi ve yenileme koşulu belirlenmemiştir. Düğmeler “Yakında”
olarak pasiftir. Satın alma, kart bilgisi toplama, ödeme sağlayıcısı, Firebase
okuma/yazması, token yükleme veya üyelik yetkisi verme bu sayfada yoktur.
İleride ödeme entegrasyonu ayrı yapılacaktır; bu değişiklik ücretli Firebase
hizmeti gerektirmez ve mevcut eşleşme limitlerini değiştirmez.
