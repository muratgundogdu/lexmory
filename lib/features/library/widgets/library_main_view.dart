import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/room_detail_screen.dart';
import '../provider/library_provider.dart';
import './library_stats_tile.dart';
import './room_card.dart';
import '../../../../data/library_rooms.dart';
import '../provider/library_navigation_provider.dart';
import '../../main/providers/navigation_provider.dart';

class LibraryMainView extends ConsumerStatefulWidget {
  const LibraryMainView({super.key});

  @override
  ConsumerState<LibraryMainView> createState() => _LibraryMainViewState();
}

class _LibraryMainViewState extends ConsumerState<LibraryMainView> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _cardKeys = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    for (var room in libraryRooms) {
      _cardKeys[room['id']] = GlobalKey();
    }
    
    // Initial focus on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkFocus(isEntry: true);
        // Clear any initial focus request as we are handling it now
        ref.read(libraryFocusRequestProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _getActiveRoomId() {
    final libraryState = ref.read(libraryProvider);
    try {
      final activeRoom = libraryRooms.firstWhere((room) {
        final id = room['id'] as String;
        final isUnlocked = libraryState.unlockedRoomIds.contains(id);
        final currentStage = libraryState.roomStages[id] ?? 0;
        final totalStages = room['totalStages'] as int;
        return isUnlocked && currentStage < totalStages;
      });
      return activeRoom['id'] as String;
    } catch (_) {
      return null;
    }
  }

  void _checkFocus({bool isEntry = false}) {
    final libraryState = ref.read(libraryProvider);
    final focusId = libraryState.newlyUnlockedRoomId;
    final activeId = _getActiveRoomId();
    
    // Priority: 1. Newly Unlocked, 2. Active Incomplete
    final targetId = focusId ?? activeId;

    if (targetId != null) {
      final bool isSpecial = focusId != null;
      _scrollToRoom(
        targetId, 
        isSpecialReveal: isSpecial,
        // Normal focus is faster and centered
        duration: isSpecial ? const Duration(milliseconds: 700) : const Duration(milliseconds: 500),
        alignment: 0.5,
      );
    }
  }

  Future<void> _scrollToRoom(String roomId, {
    int retryCount = 0, 
    bool isSpecialReveal = false,
    Duration duration = const Duration(milliseconds: 700),
    double alignment = 0.5,
  }) async {
    if (!mounted) return;

    final key = _cardKeys[roomId];
    final context = key?.currentContext;
    
    if (context == null) {
      if (retryCount < 3) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
           _scrollToRoom(
             roomId, 
             retryCount: retryCount + 1, 
             isSpecialReveal: isSpecialReveal, 
             duration: duration, 
             alignment: alignment,
           );
         });
      }
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
       if (retryCount < 3) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
           _scrollToRoom(
             roomId, 
             retryCount: retryCount + 1, 
             isSpecialReveal: isSpecialReveal, 
             duration: duration, 
             alignment: alignment,
           );
         });
       }
       return;
    }

    // Smooth scroll to the card
    await Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: alignment,
    );

    // After scroll, clear special focus in state so it doesn't repeat
    if (isSpecialReveal && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ref.read(libraryProvider.notifier).clearRoomFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Listen for state changes to trigger scroll if newlyUnlockedRoomId changes (Milestone Presentation)
    ref.listen(libraryProvider.select((s) => s.newlyUnlockedRoomId), (prev, next) {
      if (next != null && prev != next) {
        _scrollToRoom(next, isSpecialReveal: true);
      }
    });

    // Listen for transient focus requests (tab switches, route returns)
    ref.listen(libraryFocusRequestProvider, (prev, next) {
      if (next == true) {
        // Mark as handled immediately to prevent loops
        ref.read(libraryFocusRequestProvider.notifier).state = false;
        _checkFocus(isEntry: true);
      }
    });

    // Listen for main navigation changes (e.g. switching back from Store to Library)
    ref.listen(navigationProvider, (prev, next) {
      if (next == 1 && prev != 1) {
        _checkFocus(isEntry: true);
      }
    });

    final libraryState = ref.watch(libraryProvider);

    // Dynamic active room calculation for highlighting
    String? activeRoomId;
    try {
      final activeRoom = libraryRooms.firstWhere((room) {
        final id = room['id'] as String;
        final isUnlocked = libraryState.unlockedRoomIds.contains(id);
        final currentStage = libraryState.roomStages[id] ?? 0;
        final totalStages = room['totalStages'] as int;
        return isUnlocked && currentStage < totalStages;
      });
      activeRoomId = activeRoom['id'] as String;
    } catch (_) {
      activeRoomId = null;
    }

    final completedRooms = libraryState.roomStages.entries.where((entry) {
      final room = libraryRooms.firstWhere((r) => r['id'] == entry.key, orElse: () => {});
      if (room.isEmpty) return false;
      return entry.value >= (room['totalStages'] as int);
    }).length;

    final totalRooms = libraryRooms.length;

    return CustomScrollView(
      controller: _scrollController,
      cacheExtent: 5000.0,
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
                final bool isUnlocked = libraryState.unlockedRoomIds.contains(roomId);
                final currentStage = libraryState.roomStages[roomId] ?? 0;
                final double progressValue = currentStage / totalStages;
                
                // Highlight logic: Permanent active room OR temporary focus target
                final bool isActive = roomId == activeRoomId;
                final bool isNewlyUnlocked = libraryState.newlyUnlockedRoomId == roomId;
                final bool shouldHighlight = isActive || isNewlyUnlocked;

                final int displayStage = isUnlocked ? currentStage : 0;
                final String prefix = roomId == 'room_03' ? 'room_state' : 'room_stage';
                final String currentAssetPath = 'lib/assets/library/$roomId/${prefix}_$displayStage.webp';

                return RoomCard(
                  key: _cardKeys[roomId],
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
                  highlightGlow: shouldHighlight,
                  isNewlyUnlocked: isNewlyUnlocked,
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
