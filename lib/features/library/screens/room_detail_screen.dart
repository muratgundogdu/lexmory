import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/providers/game_provider.dart';
import '../provider/library_provider.dart';
import '../widgets/room_stage_reveal.dart';
import '../../../data/library_rooms.dart';
import 'room_completion_celebration_screen.dart';

import '../provider/library_navigation_provider.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  bool isUpgrading = false;
  String upgradeStatusText = "";
  int? _revealFromStage;
  int? _targetStageIndex;

  late final AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    debugPrint('ROOM_DETAIL: initState for ${widget.roomId}');
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    debugPrint('ROOM_DETAIL: dispose for ${widget.roomId}');
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _handleUpgrade(int currentStage) async {
    if (isUpgrading) return;

    final libraryNotifier = ref.read(libraryProvider.notifier);
    final cost = libraryNotifier.getUpgradeCost(widget.roomId, currentStage);
    final gameState = ref.read(gameProvider);

    if (gameState.tokens < cost) return;

    // 1. Prepare Target Data
    final int targetStage = currentStage + 1;
    final roomData = libraryRooms.firstWhere((r) => r['id'] == widget.roomId);
    final List<String> stageTitles = List<String>.from(roomData['stageTitles']);
    final String nextStepTitle = currentStage < stageTitles.length
        ? stageTitles[currentStage]
        : "Geliştiriliyor";

    // 2. Precache Next Stage Image
    final String prefix = widget.roomId == 'room_03' ? 'room_state' : 'room_stage';
    final String nextAssetPath = 'lib/assets/library/${widget.roomId}/${prefix}_$targetStage.webp';
    
    setState(() {
      isUpgrading = true;
      _targetStageIndex = targetStage;
      upgradeStatusText = "$nextStepTitle...".toUpperCase();
    });

    try {
      await precacheImage(AssetImage(nextAssetPath), context);
    } catch (e) {
      debugPrint('Failed to precache room image: $e');
      // Continue anyway, it will just load on the fly
    }

    if (!mounted) return;

    // 3. Start Presentation Sequence
    HapticFeedback.mediumImpact();
    
    // Initial delay for status text to be readable
    await Future.delayed(500.ms);
    if (!mounted) return;

    setState(() {
      _revealFromStage = currentStage;
      upgradeStatusText = "TAMAMLANDI!";
    });

    HapticFeedback.lightImpact();

    // 4. Play Animation
    // We update the persistent state ONLY after the animation has made visual contact
    // to keep the RoomStageReveal logic simple.
    
    // We'll listen to the controller to commit the state at the right moment (Contact Point)
    void onAnimationUpdate() {
      if (_revealController.value >= 0.65 && isUpgrading && _revealFromStage != null) {
        _revealController.removeListener(onAnimationUpdate);
        // COMMIT STATE: This will update currentStageIndex in build()
        libraryNotifier.upgradeRoom(widget.roomId);
      }
    }
    _revealController.addListener(onAnimationUpdate);

    await _revealController.forward(from: 0);
    
    if (!mounted) return;

    // Final cooldown
    await Future.delayed(300.ms);
    if (!mounted) return;

    setState(() {
      isUpgrading = false;
      _revealFromStage = null;
      _targetStageIndex = null;
      upgradeStatusText = "";
    });
    _revealController.reset();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(libraryProvider.select((s) => s.pendingCelebration), (prev, next) async {
      debugPrint('ROOM_DETAIL: pendingCelebration listener. Prev: ${prev != null}, Next: ${next != null}');
      if (next != null && prev == null) {
        final navigator = Navigator.of(context);
        await Future.delayed(800.ms);
        if (!mounted) return;

        debugPrint('ROOM_DETAIL: pushing RoomCompletionCelebrationScreen');
        final bool? shouldFocusNext = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (context) => RoomCompletionCelebrationScreen(result: next),
            settings: const RouteSettings(name: 'Celebration'),
          ),
        );

        debugPrint('ROOM_DETAIL: Celebration returned, shouldFocusNext: $shouldFocusNext');
        if (mounted) {
          debugPrint('ROOM_DETAIL: popping RoomDetailScreen');
          navigator.pop();

          if (shouldFocusNext == true) {
            final nextRoom = libraryRooms.firstWhere(
              (r) => r['unlockRequirement'] == widget.roomId,
              orElse: () => {},
            );
            
            if (nextRoom.isNotEmpty) {
              final nextId = nextRoom['id'] as String;
              debugPrint('ROOM_DETAIL: focusing next room: $nextId');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(libraryProvider.notifier).focusUnlockedRoom(nextId);
                }
              });
            }
          }
        }
      }
    });

    final libraryState = ref.watch(libraryProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);
    final gameState = ref.watch(gameProvider);

    final roomData = libraryRooms.firstWhere((r) => r['id'] == widget.roomId);
    final int totalStages = roomData['totalStages'] as int;
    final int currentStageIndex = libraryState.roomStages[widget.roomId] ?? 0;
    final bool isMaxStage = currentStageIndex >= totalStages;

    int nextUpgradeCost = 0;
    bool canAfford = false;

    if (!isMaxStage) {
      nextUpgradeCost = libraryNotifier.getUpgradeCost(widget.roomId, currentStageIndex);
      canAfford = gameState.tokens >= nextUpgradeCost;
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Request focus when returning to library list
          ref.read(libraryFocusRequestProvider.notifier).state = true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        children: [
          Positioned.fill(
            child: RoomStageReveal(
              roomId: widget.roomId,
              stageIndex: currentStageIndex,
              targetStageIndex: _targetStageIndex,
              revealFromStage: _revealFromStage,
              revealAnimation: _revealController,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha:0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha:0.8),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildCompactHeader(roomData['name'] as String),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildRefinedProgress(currentStageIndex, totalStages),
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: isMaxStage
                    ? _buildCompletedArea()
                    : _buildUpgradePanel(currentStageIndex, canAfford, nextUpgradeCost),
              ),
            ),
          ),

          if (isUpgrading) _buildGlowOverlay(),
          if (isUpgrading) Center(child: _buildStatusPopup()),
        ],
      ),
    ),
    );
  }

  Widget _buildRefinedProgress(int current, int total) {
    double progress = (current / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ODA GELİŞİMİ",
                style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
            Text("%${(progress * 100).toInt()}",
                style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 6,
            color: Colors.white10,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: 1.seconds,
                  width: (MediaQuery.of(context).size.width - 48) * progress,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFD4A574), Color(0xFFF2C078)]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradePanel(int currentStage, bool canAfford, int cost) {
    final roomData = libraryRooms.firstWhere((r) => r['id'] == widget.roomId);
    final List<String> stageTitles = List<String>.from(roomData['stageTitles']);

    String nextStepTitle = (currentStage < stageTitles.length)
        ? stageTitles[currentStage]
        : "SON DOKUNUŞLAR";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C).withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("SIRADAKİ ADIM",
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(
            nextStepTitle.toUpperCase(),
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildUpgradeButton(currentStage, canAfford, cost),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(int currentStage, bool canAfford, int cost) {
    final bool isButtonDisabled = !canAfford || isUpgrading;
    return Opacity(
      opacity: isButtonDisabled ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: isButtonDisabled ? null : () => _handleUpgrade(currentStage),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: canAfford
                ? const LinearGradient(colors: [Color(0xFFD4A574), Color(0xFFF2C078)])
                : LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade900]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isUpgrading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(canAfford ? "GELİŞTİR" : "YETERSİZ TOKEN",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: canAfford ? Colors.black : Colors.white24)),
                const SizedBox(width: 10),
                Text("🪙 $cost", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: canAfford ? Colors.black : Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(String title) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            Text(title.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPopup() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4A574), width: 1.5),
      ),
      child: Text(
        upgradeStatusText.toUpperCase(),
        style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
      ),
    ).animate().scale(curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildGlowOverlay() => IgnorePointer(
    child: Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [const Color(0xFFCEA14F).withValues(alpha:0.3), Colors.transparent],
        ),
      ),
    ).animate().fadeIn().fadeOut(delay: 700.ms),
  );

  Widget _buildCompletedArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C).withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4A574).withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          _buildEmojiEventsIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ODA TAMAMLANDI", style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.bold, fontSize: 12)),
                Text("Kütüphanenizin bu parçası artık hazır.", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiEventsIcon() {
    final icon = const Icon(Icons.emoji_events, color: Color(0xFFF2C078), size: 32);
    if (ref.read(gameProvider).showVictoryPanel) return icon; // Don't animate if overlay active

    final animatedIcon = icon.animate(onPlay: (c) => c.repeat());
    return animatedIcon.shimmer();
  }
}
