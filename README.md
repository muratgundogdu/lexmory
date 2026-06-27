# Lexmory - Kelime Bulmacalı Kütüphane Geliştirme Oyunu

Lexmory, oyuncuların kelime bulmacaları çözerek token kazandığı ve bu tokenlar ile kendi antik kütüphanelerini inşa ettikleri premium bir mobil oyundur. "Dark Luxury" tasarım çizgisiyle zenginleştirilmiş, estetik ve bilgi odaklı bir deneyim sunar.

## 🚀 Öne Çıkan Özellikler

### 🏛️ Kütüphane Geliştirme Sistemi (Stager)
- **Dinamik Odalar:** `Küçük Çalışma Odası`, `Doğa Kanadı`, `Antik Galeri` gibi farklı temalarda kütüphane odaları.
- **7 Aşamalı İlerleme:** Her oda, stage 0'dan stage 7'ye kadar gelişir. Her yükseltmede odaya yeni görsel öğeler eklenir.
- **Ekonomi Yönetimi:** Odalar ilerledikçe artan maliyetler ve her odaya özel maliyet çarpanları (`multiplier`).
- **Premium Geçişler:** Odalar gelişirken uygulanan altın parıltılı (Glow) ve ölçekli (Scale) geçiş animasyonları.

### 🧩 Oyun Mekanikleri
- **Hafıza Odaklı Bulmaca:** Kelimeyi kısa süreli görüp, harfler kapandıktan sonra doğru sırayla bulmaya dayalı akış.
- **Joker Sistemi:** `Harf Aç`, `Yanlış Sil` ve `Tekrar Gör` gibi yardımcı oyun araçları.
- **Seri (Streak) Sistemi:** Yanlış yapmadan üst üste kelime çözerek artan ödül çarpanları.
- **Token Ekonomisi:** Kelime başına ödüller, kategori sonu bonusları ve zamanla dolan (Regeneration) token sistemi.

### 🎓 Akıllı Eğitim (Onboarding)
- **Çok Aşamalı Tutorial:** Oyuncuyu adım adım yönlendiren, spotlight efektli ve interaktif eğitim süreci.
- **Bağlamsal İpuçları:** Oyunun ilerleyen aşamalarında ilk kez karşılaşılan özellikler için (Jokerler, Tokenlar) otomatik devreye giren bilgilendirmeler.

## 🛠️ Teknik Mimari

- **Framework:** Flutter (3.41+ uyumlu `withValues` renk yönetimi)
- **State Management:** Riverpod (StateNotifier & StateProvider ile merkezi yönetim)
- **Persistence:** SharedPreferences (Tokenlar, oda seviyeleri ve eğitim durumu kalıcı olarak saklanır)
- **Animations:** Flutter Animate & Custom Transition Widgets
- **Ads:** Google Mobile Ads (x2 Ödül katlama ve token kazanma desteği)

## 📁 Proje Yapısı

```text
lib/
├── core/               # Renkler, temalar, tipografi ve sabitler
├── data/               # Kategori listeleri ve kütüphane oda tanımları
├── features/           # Özellik bazlı klasörleme (Domain-driven)
│   ├── game/           # Oyun motoru, harf gridi, jokerler ve bakiye yönetimi
│   ├── library/        # Kütüphane odaları, gelişim ekranları ve aşama yönetimi
│   ├── tutorial/       # Eğitim sahneleri ve overlay katmanları
│   ├── store/          # Mağaza ve token paketleri
│   └── settings/       # Kullanıcı tercihleri
├── widgets/            # Global shared widget'lar (Overlayler, Butonlar)
└── main.dart           # Uygulama giriş noktası ve SDK başlatıcıları
```

## 💎 Tasarım Dili (Dark Luxury)

- **Arka Plan:** #0F0F10 (Deep Black)
- **Yüzeyler:** #1A1A1C (Slate Gray)
- **Vurgu Renkleri:** #D4A574 (Primary Gold), #F2C078 (Accent Gold)
- **Font:** Outfit (Google Fonts)

## 🛠 Kurulum ve Çalıştırma

1. Projeyi klonlayın.
2. `flutter pub get` komutu ile bağımlılıkları yükleyin.
3. Assets klasöründeki görsellerin `pubspec.yaml` içinde tanımlı olduğundan emin olun.
4. `flutter run` ile uygulamayı başlatın.
