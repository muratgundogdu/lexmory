# Lexmory - Kelime Bulmacalı Kütüphane Geliştirme Oyunu

Lexmory, oyuncuların kelime bulmacaları çözerek token kazandığı ve bu tokenlar ile kendi antik kütüphanelerini inşa ettikleri premium bir mobil oyundur.

## 🚀 Öne Çıkan Özellikler

### 🏛️ Gelişmiş Kütüphane Sistemi
- **Stage Progression:** Her oda (room_01, room_02 vb.) 7 farklı aşamadan oluşur. Her aşamada odaya yeni eşyalar (raf, masa, lamba, halı vb.) eklenir.
- **Premium Animasyonlar:** `AnimatedSwitcher`, `ScaleTransition` ve `FadeTransition` ile zenginleştirilmiş akıcı oda geliştirme deneyimi.
- **Kalıcı Kayıt (Persistence):** `SharedPreferences` entegrasyonu sayesinde oda gelişimleri ve aşamalar uygulama kapatılsa bile korunur.

### 🧩 Oyun Mekanikleri
- **Kelime Bulmaca:** Karışık harfler içinden doğru kelimeleri bulma.
- **Dinamik Kategori Sistemi:** Farklı zorluk seviyelerinde ve temalarda kategoriler.
- **Token Ekonomisi:** Çözülen her kelime için 45 token, kategori tamamlama için 150 token ödül.
- **Ödül Katlama (x2):** Reklam izleyerek kazanılan tokenları ikiye katlama özelliği.

### 💰 Ekonomi ve İlerleme
- **Artan Maliyetler:** Odalar ilerledikçe maliyetler oda çarpanı (`multiplier`) ile artar.
- **Merkezi State Yönetimi:** `Riverpod` kullanılarak bakiye (tokens) ve oda gelişimleri tüm ekranlarda senkronize çalışır.
- **Token Otomasyonu:** Tokenlar azaldığında zamanla otomatik yenilenme (Regeneration) sistemi.

### 💎 Kullanıcı Deneyimi (UX/UI)
- **Luxury Dark Tema:** Altın sarısı (#D4A574, #F2C078) ve koyu gri tonlarında premium tasarım.
- **Dinamik Header:** Token takibi, kategori ismi ve streak durumunu gösteren gelişmiş oyun üst barı.
- **Haptic Feedback:** Geliştirme ve kelime çözüm anlarında dokunsal geri bildirim.

## 🛠️ Teknik Mimari

- **Framework:** Flutter
- **State Management:** Riverpod (StateNotifier & StateProvider)
- **Local Storage:** SharedPreferences
- **Animations:** Flutter Animate & Standart Animation Controllers
- **Font:** Google Fonts (Outfit)

## 📁 Proje Yapısı
