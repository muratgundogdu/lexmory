# 🧩 Lexmory - Premium Casual Memory Puzzle

Lexmory, oyuncuların hafızasını test eden, harfleri doğru sırayla bularak kelimeleri tamamlamaya çalıştığı profesyonel bir mobil bulmaca oyunudur. Bu proje, temiz kod (clean code) prensipleri ve modern Flutter mimarisi (Feature-First) kullanılarak geliştirilmiştir.

## 🚀 Mimari Yapı (Feature-First Architecture)

Proje, sürdürülebilirlik ve yüksek performans için katmanlı bir mimari üzerine kurulmuştur:

### 1. 📂 Core (Temel Katman)
Uygulamanın genel ayarlarını ve tasarım dilini yönetir.
- `app_colors.dart`: Oyunun "Premium Dark" temasına uygun renk paleti.
- `app_theme.dart`: Yazı tipleri (Google Baloo 2), Material 3 yapılandırması ve görsel şablonlar.

### 2. 📂 Features (Özellikler - Oyun Alanı)
Kullanıcıyla etkileşime geçen ana modülleri içerir.
- `game_screen.dart`: Diğer tüm parçaları birleştiren ana iskelet.
- `game_header.dart`: Kategori bilgisi, token yönetimi ve ceza animasyonları.
- `word_reveal_area.dart`: Hedef kelimenin dinamik boyutlandırılması ve harf uçma efektleri.
- `letter_grid.dart`: 4x4 harf ızgarası ve etkileşim yönetimi.
- `joker_bar.dart`: Jokerlerin kilitlenme ve kullanım mantığı.

### 3. 📂 Providers & Models (Durum Yönetimi)
Riverpod kullanılarak oyunun "beyni" ve veri yapısı ayrılmıştır.
- `game_provider.dart`: Oyunun tüm iş mantığı (business logic), harf seçimi ve seviye geçişleri.
- `game_state.dart`: Oyunun anlık durumunu (token, streak, wrongCount vb.) tutan immutable yapı.

### 4. 📂 Services (Hesaplama Merkezi)
Saf mantık (logic) işlemlerini UI'dan ayırır.
- `reward_calculator.dart`: Oyuncunun performansına göre ödül, bonus ve seri çarpanını (streak multiplier) hesaplayan motor.

### 5. 📂 Widgets (Global Bileşenler)
Tekrar kullanılabilir şık arayüz elemanları.
- `letter_tile.dart`: 3D kart çevirme animasyonlu harf kutucukları.
- `victory_overlay.dart`: Bölüm sonu kazanç paneli (Premium Reward UI).
- `reward_overlay.dart`: Token kazanıldığında ekrana saçılan para efekti.
- `joker_button.dart`: Gradient ve gölge detaylı joker buton tasarımı.

## 🎮 Oyun Ekonomisi & Kurallar
- **Base Reward:** +25 Token.
- **Memory Bonus:** Yanlış yapılmazsa +10 Token.
- **Master Bonus:** Joker kullanılmazsa +15 Token.
- **Streak System:** Üst üste temiz bitirilen her bölüm için çarpan artar (max x1.5).
- **Penalties:** Her yanlış seçimde -5 Token ve streak sıfırlanır.

## 🛠️ Kullanılan Teknolojiler
- **Flutter & Dart**
- **Riverpod:** State Management.
- **Flutter Animate:** Akıcı ve premium animasyonlar.
- **Google Fonts:** Tipografi.
- **Haptic Feedback:** Fiziksel geri bildirim.

## 📦 Kurulum
1. Flutter SDK'nın yüklü olduğundan emin olun.
2. `flutter pub get` komutu ile paketleri yükleyin.
3. `flutter run` ile uygulamayı başlatın.
