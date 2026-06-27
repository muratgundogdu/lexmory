import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/room_detail_screen.dart';
import '../provider/library_provider.dart';
import './library_stats_tile.dart';
import './room_card.dart';
import '../../../../data/library_rooms.dart';

class LibraryMainView extends ConsumerWidget {
  const LibraryMainView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State'i watch ederek kütüphane gelişimini anlık takip ediyoruz
    final libraryState = ref.watch(libraryProvider);

    // 1. TAMAMLANAN ODA SAYISINI HESAPLA (Maksimum stage'e ulaşanlar)
    final completedRooms = libraryState.roomStages.entries.where((entry) {
      final room = libraryRooms.firstWhere((r) => r['id'] == entry.key, orElse: () => {});
      if (room.isEmpty) return false;
      return entry.value >= (room['totalStages'] as int);
    }).length;

    final totalRooms = libraryRooms.length;

    return CustomScrollView(
      slivers: [
        // İstatistik Kartları
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: LibraryStatsTile(
              label: "TAMAMLANAN ODA",
              value: "$completedRooms / $totalRooms",
              icon: Icons.meeting_room_rounded,
            ),
          ),
        ),

        // Dinamik Oda Listesi
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final room = libraryRooms[index];
                final roomId = room['id'] as String;
                final totalStages = room['totalStages'] as int;

                // Kilidi provider verisinden kontrol et
                final bool isUnlocked = libraryState.unlockedRoomIds.contains(roomId);

                // Mevcut stage verisi (Tek Gerçek Değer)
                final currentStage = libraryState.roomStages[roomId] ?? 0;

                // Progress Hesaplama
                final double progressValue = currentStage / totalStages;

                // Dinamik Görsel Yolu (Stage-PNG Sistemi)
                // Kilitli odalarda stage 0 gösterilir
                final int displayStage = isUnlocked ? currentStage : 0;
                final String currentAssetPath = 'lib/assets/library/$roomId/room_stage_$displayStage.webp';

                return RoomCard(
                  name: room['name'] as String,
                  description: isUnlocked
                      ? (currentStage >= totalStages
                      ? "✓ Oda Tamamlandı"
                      : room['description'] as String)
                      : "Kilidi Açmak İçin Önceki Odayı Bitir",
                  progress: progressValue,
                  isLocked: !isUnlocked,
                  lockRequirement: room['unlockRequirement'] as String?,
                  imagePath: currentAssetPath,
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

        // Alt boşluk
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}