import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexmory/features/library/screens/room_detail_screen.dart';
import '../provider/library_provider.dart';
import '../widgets/library_stats_tile.dart';
import '../widgets/room_card.dart';
import '../../../data/library_rooms.dart';

class LibraryOverviewScreen extends ConsumerWidget {
  const LibraryOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    // 1. TAMAMLANAN ODA SAYISINI HESAPLA (Stage 7 olanlar)
    final completedRooms = libraryState.roomStages.entries.where((entry) {
      return entry.value >= 7;
    }).length;

    final totalRooms = libraryRooms.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0F0F10),
            floating: true,
            elevation: 0,
            title: Text(
              "Kütüphanem",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // İstatistikler Alanı
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: LibraryStatsTile(
                      label: "TAMAMLANAN ODA",
                      value: "$completedRooms / $totalRooms",
                      icon: Icons.meeting_room_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LibraryStatsTile(
                      label: "TOPLANAN KİTAP",
                      value: "12", // Kelime sayısına göre dinamikleştirilebilir
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Oda Kartları Listesi
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final room = libraryRooms[index];
                  final roomId = room['id'] as String;
                  final bool isUnlocked = roomId == 'room_01'
                      ? true
                      : libraryState.unlockedRoomIds.contains(roomId);

                  // 2. MEVCUT STAGE VERİSİ
                  final currentStage = libraryState.roomStages[roomId] ?? 0;

                  // 3. PROGRESS HESAPLAMA (0.0 - 1.0 arası)
                  final double progressValue = currentStage / 7;

                  // 4. DİNAMİK GÖRSEL YOLU
                  // Oyuncu geliştikçe karttaki görsel otomatik değişir
                  String currentAssetPath = 'lib/assets/library/$roomId/room_stage_$currentStage.png';

                  // Kilitli odalar için varsayılan boş halini göster
                  if (!isUnlocked) {
                    currentAssetPath = 'lib/assets/library/$roomId/room_stage_0.png';
                  }

                  return RoomCard(
                    name: room['name'] as String,
                    description: isUnlocked
                        ? (currentStage == 7 ? "Tüm eşyalar yerleştirildi" : room['description'] as String)
                        : "Kilidi Açmak İçin Önceki Odayı Tamamla",
                    progress: progressValue,
                    isLocked: !isUnlocked,
                    lockRequirement: room['unlockRequirement'] as String?,
                    imagePath: currentAssetPath, // Canlı stage görseli
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailScreen(roomId: roomId),
                        ),
                      );
                    },
                  );
                },
                childCount: libraryRooms.length,
              ),
            ),
          ),

          // Bottom Navigation Bar için boşluk
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}