import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexmory/features/library/widgets/pure_image_card.dart';
import '../../../data/collection_pool.dart';
import '../models/collection_card.dart';
import '../provider/collection_provider.dart';

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
  'Bilge Amca': const AlbumDesign(coverPath: 'lib/assets/cards/bilge_amca/bilge_amca.webp', themeColor: Color(0xFFFFD275), rewardTokens: 1000),
  'Kütüphane Kedisi': const AlbumDesign(coverPath: 'lib/assets/cards/kutuphane_kedisi/kutuphane_kedisi.webp', themeColor: Color(0xFF9D85FF), rewardTokens: 1200),
  'Akademi Baykuşu': const AlbumDesign(coverPath: 'lib/assets/cards/akademi_baykusu/akademi_baykusu.webp', themeColor: Color(0xFF4EA8DE), rewardTokens: 1200),
  'Zaman Bekçisi': const AlbumDesign(coverPath: 'lib/assets/cards/zaman_bekcisi/zaman_bekcisi.webp', themeColor: Color(0xFFE63946), rewardTokens: 1500),
  'Gizemli Koleksiyoncu': const AlbumDesign(coverPath: 'lib/assets/cards/gizemli_koleksiyoncu/gizemli_koleksiyoncu.webp', themeColor: Color(0xFF8338EC), rewardTokens: 1500),
  'Eski Kaşif': const AlbumDesign(coverPath: 'lib/assets/cards/eski_kasif/eski_kasif.webp', themeColor: Color(0xFFFB5607), rewardTokens: 1500),
  'Çılgın Simyacı': const AlbumDesign(coverPath: 'lib/assets/cards/cilgin_simyaci/cilgin_simyaci.webp', themeColor: Color(0xFF06D6A0), rewardTokens: 1800),
  'Usta Sanatçı': const AlbumDesign(coverPath: 'lib/assets/cards/usta_sanatci/usta_sanatci.webp', themeColor: Color(0xFFFF006E), rewardTokens: 1800),
  'Genç Mucit': const AlbumDesign(coverPath: 'lib/assets/cards/genc_mucit/genc_mucit.webp', themeColor: Color(0xFF3A86C8), rewardTokens: 1800),
  'Kraliyet Hazinesi': const AlbumDesign(coverPath: 'lib/assets/cards/kraliyet_hazinesi/kraliyet_hazinesi.webp', themeColor: Color(0xFFFFB703), rewardTokens: 2500),
  'Gizemli Eserler': const AlbumDesign(coverPath: 'lib/assets/cards/gizemli_eserler/gizemli_eserler.webp', themeColor: Color(0xFF7209B7), rewardTokens: 2500),
  'Sonsuz Bilgelik': const AlbumDesign(coverPath: 'lib/assets/cards/sonsuz_bilgelik/sonsuz_bilgelik.webp', themeColor: Color(0xFF4CC9F0), rewardTokens: 3000),
};

class CollectionView extends ConsumerWidget {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionState = ref.watch(collectionProvider);
    final Set<String> ownedCardIds = collectionState.ownedCardIds;
    final List<String> allSets = collectionPool.map((c) => c.setName).toSet().toList();
    final int totalCards = collectionPool.length;
    final int ownedCount = ownedCardIds.length;
    final double generalProgress = totalCards > 0 ? ownedCount / totalCards : 0.0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("HAZİRAN ALBÜMÜ", style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13)),
                      Text("⏳ 12 Gün Kaldı", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      color: const Color(0xFFF2C078),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final setName = allSets[index];
                final setCards = collectionPool.where((c) => c.setName == setName).toList();
                final int setTotal = setCards.length;
                final int setOwned = setCards.where((c) => ownedCardIds.contains(c.id)).length;
                final bool isCompleted = setTotal > 0 && setOwned == setTotal;
                final design = albumDesigns[setName] ?? const AlbumDesign(coverPath: 'lib/assets/album_covers/default_cover.png', themeColor: Color(0xFFF2C078), rewardTokens: 1000);

                return _buildAlbumCover(context, setName, setOwned, setTotal, setTotal > 0 ? setOwned / setTotal : 0.0, isCompleted, setCards, ownedCardIds, design);
              },
              childCount: allSets.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAlbumCover(BuildContext context, String setName, int owned, int total, double progress, bool isCompleted, List<CollectionCard> setCards, Set<String> ownedCardIds, AlbumDesign design) {
    return GestureDetector(
      onTap: () => _showAlbumDetails(context, setName, setCards, ownedCardIds),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D35),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isCompleted ? design.themeColor : Colors.white.withValues(alpha: 0.05), width: isCompleted ? 2.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 65, top: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Image.asset(design.coverPath, fit: BoxFit.contain, errorBuilder: (c, e, s) => Container(color: Colors.white10)),
              ),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(setName.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$owned / $total KART", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                        if (isCompleted) Icon(Icons.verified_rounded, color: design.themeColor, size: 16)
                        else Text("+${design.rewardTokens} T", style: GoogleFonts.outfit(color: design.themeColor, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 5, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress, child: Container(decoration: BoxDecoration(color: design.themeColor, borderRadius: BorderRadius.circular(10)))),
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

  void _showAlbumDetails(BuildContext context, String setName, List<CollectionCard> cards, Set<String> ownedCardIds) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final collectionState = ref.watch(collectionProvider);
          final newlyUnlockedInThisSet = cards.where((c) => collectionState.newlyUnlockedCardIds.contains(c.id)).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
            builder: (context, controller) => Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(setName.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: controller, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 16, childAspectRatio: 0.72),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isOwned = ownedCardIds.contains(card.id);
                      final isNewlyUnlocked = collectionState.newlyUnlockedCardIds.contains(card.id);
                      
                      // Calculate stagger delay based on its position in the newly unlocked list
                      Duration delay = Duration.zero;
                      if (isNewlyUnlocked) {
                        final newIdx = newlyUnlockedInThisSet.indexOf(card);
                        if (newIdx != -1) {
                          delay = Duration(milliseconds: newIdx * 150);
                        }
                      }

                      return PureImageCard(
                        card: card, 
                        isOwned: isOwned, 
                        isNewlyUnlocked: isNewlyUnlocked,
                        isMistikMode: true,
                        staggerDelay: delay,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
