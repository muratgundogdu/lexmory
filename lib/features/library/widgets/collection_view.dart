import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexmory/features/library/widgets/pure_image_card.dart';
import '../../../data/collection_pool.dart';
import '../models/collection_card.dart';
import '../provider/collection_provider.dart';

// 🎨 ALBÜM KAPAKLARININ ÖZEL AYARLARI (Görsel ve Tema Renkleri)
// Buradaki isimlerin collectionPool'daki setName'ler ile birebir aynı olması gerekir.
class AlbumDesign {
  final String coverPath;
  final Color themeColor;
  final int rewardTokens;

  const AlbumDesign({
    required this.coverPath,
    required this.themeColor,
    required this.rewardTokens,
  });
}

final Map<String, AlbumDesign> albumDesigns = {
  'Bilge Amca': const AlbumDesign(coverPath: 'lib/assets/album_covers/bilge_amca_cover.png', themeColor: Color(0xFFFFD275), rewardTokens: 1000),
  'Kütüphane Kedisi': const AlbumDesign(coverPath: 'lib/assets/album_covers/kutuphane_kedisi_cover.png', themeColor: Color(0xFF9D85FF), rewardTokens: 1200),
  'Akademi Baykuşu': const AlbumDesign(coverPath: 'lib/assets/album_covers/akademi_baykusu_cover.png', themeColor: Color(0xFF4EA8DE), rewardTokens: 1200),
  'Zaman Bekçisi': const AlbumDesign(coverPath: 'lib/assets/album_covers/zaman_bekcisi_cover.png', themeColor: Color(0xFFE63946), rewardTokens: 1500),
  'Gizemli Koleksiyoncu': const AlbumDesign(coverPath: 'lib/assets/album_covers/gizemli_koleksiyoncu_cover.png', themeColor: Color(0xFF8338EC), rewardTokens: 1500),
  'Eski Kaşif': const AlbumDesign(coverPath: 'lib/assets/album_covers/eski_kasif_cover.png', themeColor: Color(0xFFFB5607), rewardTokens: 1500),
  'Çılgın Simyaci': const AlbumDesign(coverPath: 'lib/assets/album_covers/cilgin_simyaci_cover.png', themeColor: Color(0xFF06D6A0), rewardTokens: 1800),
  'Usta Sanatçı': const AlbumDesign(coverPath: 'lib/assets/album_covers/usta_sanatci_cover.png', themeColor: Color(0xFFFF006E), rewardTokens: 1800),
  'Genç Mucit': const AlbumDesign(coverPath: 'lib/assets/album_covers/genc_mucit_cover.png', themeColor: Color(0xFF3A86C8), rewardTokens: 1800),
  'Kraliyet Hazinesi': const AlbumDesign(coverPath: 'lib/assets/album_covers/kraliyet_hazinesi_cover.png', themeColor: Color(0xFFFFB703), rewardTokens: 2500),
  'Gizemli Eserler': const AlbumDesign(coverPath: 'lib/assets/album_covers/gizemli_eserler_cover.png', themeColor: Color(0xFF7209B7), rewardTokens: 2500),
  'Sonsuz Bilgelik': const AlbumDesign(coverPath: 'lib/assets/album_covers/sonsuz_bilgelik_cover.png', themeColor: Color(0xFF4CC9F0), rewardTokens: 3000),
};

class CollectionView extends ConsumerWidget {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionState = ref.watch(collectionProvider);
    final List<String> ownedCardIds = collectionState.ownedCardIds;

    // Tüm benzersiz set isimlerini (albüm başlıklarını) ayıklıyoruz
    final List<String> allSets = collectionPool.map((c) => c.setName).toSet().toList();

    final int totalCards = collectionPool.length;
    final int ownedCount = ownedCardIds.length;
    final double generalProgress = totalCards > 0 ? ownedCount / totalCards : 0.0;

    return CustomScrollView(
      slivers: [
        // SEZON GENEL ÖZET KARTI
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E22), Color(0xFF121214)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "HAZİRAN ALBÜMÜ",
                        style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
                      ),
                      Text(
                        "⏳ 12 Gün Kaldı",
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Genel İlerleme", style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text("$ownedCount / $totalCards", style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: generalProgress,
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      color: const Color(0xFFF2C078),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ALBÜM KAPAKLARI GRİDİ (Görsel Destekli Yeni Tasarım)
        SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85, // Kartın dik dikey dengesi
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final setName = allSets[index];

                // Bu albüme ait kartları bul ve ilerlemeyi hesapla
                final setCards = collectionPool.where((c) => c.setName == setName).toList();
                final int setTotal = setCards.length;
                final int setOwned = setCards.where((c) => ownedCardIds.contains(c.id)).length;
                final double setProgress = setTotal > 0 ? setOwned / setTotal : 0.0;
                final bool isCompleted = setTotal > 0 && setOwned == setTotal;

                // Tasarımsal eşleşmeyi al (Yoksa fallback olarak varsayılan renk atar)
                final design = albumDesigns[setName] ?? const AlbumDesign(
                  coverPath: 'lib/assets/album_covers/default_cover.png',
                  themeColor: Color(0xFFF2C078),
                  rewardTokens: 1000,
                );

                return _buildAlbumCover(
                  context: context,
                  setName: setName,
                  owned: setOwned,
                  total: setTotal,
                  progress: setProgress,
                  isCompleted: isCompleted,
                  setCards: setCards,
                  ownedCardIds: ownedCardIds,
                  design: design,
                );
              },
              childCount: allSets.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // Navigation bar yüksekliğine göre rahat bir pay
        ),
      ],
    );
  }

  // 📂 GÜNCELLENMİŞ GÖRSEL DESTEKLİ ALBÜM KAPAĞI WIDGET'I
  Widget _buildAlbumCover({
    required BuildContext context,
    required String setName,
    required int owned,
    required int total,
    required double progress,
    required bool isCompleted,
    required List<CollectionCard> setCards,
    required List<String> ownedCardIds,
    required AlbumDesign design,
  }) {
    return GestureDetector(
      onTap: () => _showAlbumDetails(context, setName, setCards, ownedCardIds),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? design.themeColor : Colors.white.withOpacity(0.08),
            width: isCompleted ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted ? design.themeColor.withOpacity(0.15) : Colors.black38,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Görsel kenarlardan taşmasın
        child: Stack(
          children: [
            // 1. KATMAN: Canva Albüm Kapağı Görseli
            Positioned.fill(
              child: Image.asset(
                design.coverPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Görsel henüz asset'e eklenmediyse hata vermesin, gri kutu göstersin
                  return Container(color: const Color(0xFF222225));
                },
              ),
            ),

            // 2. KATMAN: Yazıların okunması için alt kısma doğru koyulaşan karartma (Gradient)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

            // 3. KATMAN: Ön Plandaki Metinler ve İlerleme Barları
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Albüm Başlığı
                    Text(
                      setName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Kart Sayısı ve Ödül/Check Durumu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$owned / $total Kart",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isCompleted)
                          Icon(Icons.check_circle_rounded, color: design.themeColor, size: 16)
                        else
                          Text(
                            "+${design.rewardTokens} T",
                            style: GoogleFonts.outfit(
                              color: design.themeColor.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Renkli İlerleme Çubuğu
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [design.themeColor.withOpacity(0.6), design.themeColor],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📜 TIKLANINCA AÇILAN DETAY PENCERESİ (BottomSheet)
  void _showAlbumDetails(BuildContext context, String setName, List<CollectionCard> cards, List<String> ownedCardIds) {

    // 🔥 PERFORMANS DÜZELTMESİ: Açılacak albümdeki kart görsellerini önden RAM'e yükle
    for (var card in cards) {
      precacheImage(AssetImage(card.imagePath), context);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Başlık Alanı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          setName.toUpperCase(),
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 20),

                // Kartların Grid Listesi
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final bool isOwned = ownedCardIds.contains(card.id);
                      return PureImageCard(
                        card: card,
                        isOwned: isOwned,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}