# Firestore Rules ve Index Taslagi

Bu not, chats, sessions, matches ve notifications akislari icin gereken ilk indexleri ve security rules yaklasimini toplar. Query'ler degistikce Firebase konsolundaki "requires an index" linkleriyle birebir dogrulanmali.

## Composite Indexler

### chats

Chat listesi icin:

```json
{
  "collectionGroup": "chats",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "participants", "arrayConfig": "CONTAINS" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

Fallback siralama lastMessageAt ile yapilirsa:

```json
{
  "collectionGroup": "chats",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "participants", "arrayConfig": "CONTAINS" },
    { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
  ]
}
```

Mesaj listesi subcollection icin tek alan index yeterli olur:

```text
chats/{chatId}/messages: orderBy(createdAt ASC)
```

### sessions

Kullanicinin ogrenci oldugu session listesi:

```json
{
  "collectionGroup": "sessions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

Kullanicinin ogretmen oldugu session listesi:

```json
{
  "collectionGroup": "sessions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "teacherId", "order": "ASCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

Status filtreli session listesi:

```json
{
  "collectionGroup": "sessions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "studentId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

```json
{
  "collectionGroup": "sessions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "teacherId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

### matches

Kullanicinin dahil oldugu match teklifleri:

```json
{
  "collectionGroup": "matches",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "participants", "arrayConfig": "CONTAINS" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

Pending teklif kutusu:

```json
{
  "collectionGroup": "matches",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "participants", "arrayConfig": "CONTAINS" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

Receiver bazli pending teklifler:

```json
{
  "collectionGroup": "matches",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "receiverId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

### notifications

Bildirim listesi:

```json
{
  "collectionGroup": "notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

Okunmamis bildirimler:

```json
{
  "collectionGroup": "notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "read", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

Tip filtreli bildirimler:

```json
{
  "collectionGroup": "notifications",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

## Security Rules Taslagi

Mevcut `firestore.rules` dosyasi bu taslagin calisan ilk hali olarak dusunulebilir. Uretim oncesi hedef durum:

- `users/{userId}`: Her signed-in kullanici profil okuyabilir. Kullanici kendi profilini create/update edebilir, ama `credits`, `trustScore`, `verified`, `email`, `id` gibi alanlari client update edemez.
- `users/{userId}/teachSkills` ve `learnSkills`: Signed-in kullanicilar okuyabilir. Sadece owner yazabilir.
- `matches/{matchId}`: Sadece `participants` icindeki kullanicilar okuyup update edebilir. Create ederken request auth uid participants icinde olmali. Delete kapali kalmali.
- `sessions/{sessionId}`: Sadece `teacherId` veya `studentId` okuyup update edebilir. Create icin auth uid iki taraftan biri olmali.
- `chats/{chatId}`: Sadece participants okuyabilir. Create icin auth uid participants icinde olmali. Update sadece chat metadata alanlariyla sinirli kalmali.
- `chats/{chatId}/messages/{messageId}`: Sadece chat participant okuyabilir. Create sadece senderId auth uid ise yapilabilir. Update sadece `readBy` gibi okundu bilgisine izin vermeli.
- `notifications/{notificationId}`: Bildirimin sahibi okuyup update/delete edebilir. Create, sender veya receiver tarafindan tetiklenebilir; cloud function'a gecildiginde client create kapatilabilir.
- `transactions` ve `escrows`: Client write kapali olmali. Okuma sadece ilgili taraflara acilmali. Kredi hareketleri cloud function veya guvenilir backend tarafinda transaction ile yapilmali.

## Dikkat Edilecek Alanlar

- `allow update` kontrollerinde status transition dogrulamasi eklenmeli: `pending -> accepted/rejected`, `requested -> scheduled/locked`, `locked -> completed/refunded`.
- Escrow release/refund client butonlari su an UI mock durumunda kalmali; gercek kredi hareketi server kontrollu olunca baglanmali.
- `participantNames`, `skillName`, `credits` gibi denormalize alanlar kolay okuma saglar ama rules icinde tutarlilik kontrolu sinirlidir.
- Bildirim create islemleri ileride Cloud Functions'a tasinirsa `notifications` client create kapatilabilir.
