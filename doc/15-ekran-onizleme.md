# Çevrimdışı ekran menüsü

Bu özellik `feat/debug-screen-gallery` dalında, önceki kayıt/profil değişikliklerinin üzerine hazırlanmıştır. Normal giriş noktası `lib/main.dart` değişmez.

Telefon bağlıyken test sürümünü aç:

```powershell
flutter run --debug --target lib/main_preview.dart
```

27 ekranın listesi açılır. Arama kutusuyla ekran bulabilir, başlığına dokunarak açabilir ve üstteki **Ekranlar** düğmesiyle menüye dönebilirsin. Kayıt veya tamamlanmış profil gerekmez. Beceri ağacına **Profili tamamla ve beceri ağacı** ekranındaki ilk adımı geçerek ulaşılır. Oturumlar ekranında aktif, bekleyen ve geçmiş sekmeleri bulunur.

Önizleme gerçek sayfa bileşenlerini, ayrı bir yönlendirici ve bellek içi veri kaynaklarıyla çalıştırır. Örnek kişiler, sohbetler, teklifler, oturumlar, bildirimler ve çalışmalar gösterilir. Kalpler ve yorumlar ekran belleğinde, sohbet mesajları süreç belleğinde tutulur. Uygulama yeniden başlatıldığında örnek değişiklikler sıfırlanır. Fotoğraf/video alanlarında açıkça etiketlenmiş yerel çizimler bulunur; gerçek video indirilmez veya oynatılmaz. Konum düğmesi örnek şehir döndürür; GPS izni istenmez.

Bu giriş noktası Firebase'i başlatmaz, üretim yönlendiricisini kullanmaz, Google Fonts veya uzak profil fotoğrafı indirmez. Depo fabrikaları önizlemede yerel kaynakları seçer. Sunucu çağrıları, medya yüklemesi ve gerçek hesap silme engellenir. Google giriş düğmesi yerel örnek hesabı kullanır. Gerçek hesapların verileri veya mevcut giriş/onboarding tercihleri değiştirilmez. Bu, daha önce oluşturulmuş bulut kaynaklarını kapatmaz ve mevcut Firebase projesinin faturalandırma durumunu değiştirmez.

Normal uygulamaya dönmek için:

```powershell
flutter run --target lib/main.dart
```

Yayın derlemesinde standart giriş noktası kullanılmalıdır. `PreviewMode.enabled` yalnızca `kDebugMode` açıkken etkinleşebilir; ayrı önizleme giriş noktası profile/release modunda çalışmayı reddeder. Normal debug sürümünde de menü kendiliğinden açılmaz.

Özelliği tamamen kaldırmak için bu dalın önizleme değişikliğini geri almak yeterlidir. Sunucu veya Firebase yapılandırma değişikliği içermez. PR birleştirmesi ayrıca kullanıcı onayı gerektirir.

## Doğrulama

```powershell
flutter test --no-pub
```

93 test geçti: 27 ekranın 360×800 boyutunda Firebase uygulaması olmadan açılması ve menüye dönüşü, menü araması, yerel mesaj/yorum gönderimi, sunucu işlemlerinin engellenmesi ve hesap silme onayının gerçek silme yapamaması dahil. Önceki uygulama testleri de korunur. Telefon boyutunda bulunan üç taşma hatası aynı dalda giderildi.
