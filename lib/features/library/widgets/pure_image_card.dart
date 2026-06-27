import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/collection_card.dart';

class PureImageCard extends StatelessWidget {
  final CollectionCard card;
  final bool isOwned;

  const PureImageCard({
    super.key,
    required this.card,
    required this.isOwned,
  });

  @override
  Widget build(BuildContext context) {
    // Nadirlik seviyelerine göre Premium Renk Paletleri
    final cardTheme = _getCardTheme(card.stars, isOwned);

    return AspectRatio(
      aspectRatio: 0.72, // Altın kart oranı
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141416), // Çok koyu şık bir kart tabanı
          borderRadius: BorderRadius.circular(18),

          // 1. Çerçeve: Nadirlik rengine göre dinamik parlayan ince şerit
          border: Border.all(
            color: cardTheme.borderColor,
            width: isOwned ? 2.0 : 1.0,
          ),

          // 2. Neon Işıma (Glow Efekti): Kartın arkasından dışarı taşan büyülü gölge
          boxShadow: [
            BoxShadow(
              color: cardTheme.glowColor,
              blurRadius: isOwned ? 14 : 4,
              spreadRadius: isOwned ? 1 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [

            // 3. Arka Plan: Kartın içinden dışarı doğru patlayan mistik radyal ışık
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      cardTheme.bgGlowColor,
                      const Color(0xFF101012),
                    ],
                    radius: 0.75,
                  ),
                ),
              ),
            ),

            // 4. Kartın Esas Görseli Alanı
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 28), // Alt kısımda yazı için yer bırakıyoruz
                child: isOwned
                    ? Image.asset(
                  card.imagePath,
                  fit: BoxFit.contain,
                )
                    : Image.asset(
                  // 🔥 YENİ: Kart açılmadıysa görünecek o gizemli ortak placeholder görseli
                  'lib/assets/cards/locked_card_placeholder.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Eğer yeni kilitli kart görselini henüz asset'e eklemediysen proje çökmez, eski kilit ikonunu tam ortada basar.
                    return Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 36,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 5. Kart İsmi Panel Gölgeliği ve Yazısı
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  isOwned ? card.name : '???', // Kilitliyse gizem katmak için ??? yazmaya devam
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: isOwned ? Colors.white : Colors.white38,
                    fontSize: 11,
                    fontWeight: isOwned ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // 6. Üst Kısımdaki Şık Yıldız Kapsülü
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    card.stars,
                        (index) => Padding(
                      padding: const EdgeInsets.only(right: 1.0),
                      child: Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: isOwned ? const Color(0xFFFFD275) : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 7. Kilitli Kartlar İçin Sağ Üst Köşedeki Zarif Küçük Kilit İkonu
            if (!isOwned)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.white24,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Temayı dinamik olarak besleyen yardımcı fonksiyonumuz
  _CardThemeColors _getCardTheme(int stars, bool owned) {
    if (!owned) {
      // Kilitli kartların tamamı mat ve gizemli temada görünür
      return _CardThemeColors(
        borderColor: Colors.white.withOpacity(0.08),
        glowColor: Colors.transparent,
        bgGlowColor: Colors.white.withOpacity(0.03),
      );
    }

    // Açılmış kartların nadirlik seviyelerine göre canlı temaları:
    if (stars == 3) {
      // 3 Yıldız: Efsanevi Canlı Altın
      return _CardThemeColors(
        borderColor: const Color(0xFFFFD275),
        glowColor: const Color(0xFFFFD275).withOpacity(0.22),
        bgGlowColor: const Color(0xFFFFD275).withOpacity(0.14),
      );
    } else if (stars == 2) {
      // 2 Yıldız: Epik Gece Mavisi / Neon Mor
      return _CardThemeColors(
        borderColor: const Color(0xFF9D85FF),
        glowColor: const Color(0xFF9D85FF).withOpacity(0.2),
        bgGlowColor: const Color(0xFF4C3BA8).withOpacity(0.25),
      );
    } else {
      // 1 Yıldız: Klasik Şık Bronz / Gümüş
      return _CardThemeColors(
        borderColor: const Color(0xFFCD7F32).withOpacity(0.7),
        glowColor: Colors.black26,
        bgGlowColor: Colors.white10,
      );
    }
  }
}

class _CardThemeColors {
  final Color borderColor;
  final Color glowColor;
  final Color bgGlowColor;

  _CardThemeColors({
    required this.borderColor,
    required this.glowColor,
    required this.bgGlowColor,
  });
}