import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_typography.dart';
import '../../../core/debug_config.dart';
import '../../../data/library_rooms.dart';
import '../models/room_completion_reward_result.dart';
import '../models/card_reward_result.dart';
import '../provider/library_provider.dart';
import '../widgets/celebration/room_live_background.dart';
import '../widgets/celebration/bilge_amca_dialog.dart';
import '../widgets/celebration/celebration_reward_chest.dart';
import '../../game/widgets/category_complete_overlay.dart'; // For CategoryRewardCard

enum CelebrationPhase {
  roomTitle,
  dialogIntro,
  chestOpening,
  rewardSummary
}

class RoomCompletionCelebrationScreen extends ConsumerStatefulWidget {
  final RoomCompletionRewardResult result;

  const RoomCompletionCelebrationScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<RoomCompletionCelebrationScreen> createState() => _RoomCompletionCelebrationScreenState();
}

class _RoomCompletionCelebrationScreenState extends ConsumerState<RoomCompletionCelebrationScreen> {
  CelebrationPhase _phase = CelebrationPhase.roomTitle;
  bool _chestOpened = false;
  bool _canSkipPhase = false;

  bool get _isFinalRoom => !libraryRooms.any((r) => r['unlockRequirement'] == widget.result.roomId);

  @override
  void initState() {
    super.initState();
    debugPrint('CELEBRATION: initState for ${widget.result.roomId}');
    _startSequence();
  }

  @override
  void dispose() {
    debugPrint('CELEBRATION: dispose for ${widget.result.roomId}');
    super.dispose();
  }

  void _startSequence() async {
    // 1. Title (1s)
    await Future.delayed(1200.ms);
    if (!mounted) return;
    setState(() {
      _phase = CelebrationPhase.dialogIntro;
      _canSkipPhase = true;
    });

    // 2. Dialog Intro (Auto transition after 2.5s)
    await Future.delayed(3000.ms);
    if (!mounted || _phase != CelebrationPhase.dialogIntro) return;
    _goToChestOpening();
  }

  void _goToChestOpening() {
    setState(() {
      _phase = CelebrationPhase.chestOpening;
      _canSkipPhase = true;
    });
    
    // Auto-open chest
    Future.delayed(1000.ms, () {
      if (mounted && _phase == CelebrationPhase.chestOpening) {
        setState(() => _chestOpened = true);
        Future.delayed(1200.ms, () {
           if (mounted && _phase == CelebrationPhase.chestOpening) {
             setState(() => _phase = CelebrationPhase.rewardSummary);
           }
        });
      }
    });
  }

  void _onScreenTap() {
    if (!_canSkipPhase) return;

    if (_phase == CelebrationPhase.dialogIntro) {
      _goToChestOpening();
    } else if (_phase == CelebrationPhase.chestOpening) {
      if (!_chestOpened) {
        setState(() => _chestOpened = true);
      } else {
        setState(() => _phase = CelebrationPhase.rewardSummary);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onScreenTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // BACKGROUND: Room
            RoomLiveBackground(
              roomId: widget.result.roomId,
              stageCount: 7, 
            ),

            // BLUR OVERLAY
            if (_phase != CelebrationPhase.roomTitle)
              Positioned.fill(
                child: DebugConfig.enableBackdropBlurs 
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(color: Colors.black.withValues(alpha: 0.5)),
                    )
                  : Container(color: Colors.black.withValues(alpha: 0.7)),
              ).animate().fadeIn(),

            // PHASE CONTENT
            _buildPhaseContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case CelebrationPhase.roomTitle:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🏛", style: TextStyle(fontSize: 48))
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                "ODA TAMAMLANDI",
                style: AppTypography.pageTitle.copyWith(color: AppColors.primary, letterSpacing: 4),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                widget.result.roomName,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        );

      case CelebrationPhase.dialogIntro:
        return const BilgeAmcaDialog(
          message: "Bu odayı büyük bir emekle tamamladın.\nYeni odanda sana yardımcı olacak birkaç hediye hazırladım.",
        );

      case CelebrationPhase.chestOpening:
        return CelebrationRewardChest(
          chestTypeId: widget.result.chestTypeId,
          isOpened: _chestOpened,
        );

      case CelebrationPhase.rewardSummary:
        return _buildRewardSummary();
    }
  }

  Widget _buildRewardSummary() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Text(
                "TEBRİKLER!",
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 14,
                ),
              ).animate().fadeIn().slideY(begin: -0.2),
              
              const SizedBox(height: 8),
              
              Text(
                _isFinalRoom ? "TÜM ODALARI TAMAMLADIN" : "YENİ ODA KEŞFEDİLDİ",
                style: AppTypography.pageTitle.copyWith(fontSize: 20, color: Colors.white),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 32),

              // ECONOMY REWARDS
              _buildEconomyRow().animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 24),

              // COLLECTION REWARDS
              _buildCollectionGrid(widget.result.chestResult.rewards),

              const SizedBox(height: 48),

              // FINAL BUTTONS
              _buildFinalButtons().animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEconomyRow() {
    final List<Widget> items = [
      _SmallRewardItem(label: "Token", value: "+${widget.result.tokenReward}", icon: "🪙"),
      if (widget.result.hintReward > 0)
        _SmallRewardItem(label: "Harf Aç", value: "+${widget.result.hintReward}", icon: "⭐"),
      if (widget.result.removeWrongReward > 0)
        _SmallRewardItem(label: "Yanlış Sil", value: "+${widget.result.removeWrongReward}", icon: "⭐"),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: items,
    );
  }

  Widget _buildCollectionGrid(List<CardRewardResult> rewards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final int count = rewards.length;

        if (count == 1) {
          return Center(
            child: SizedBox(
              width: 160,
              height: 220,
              child: CategoryRewardCard(reward: rewards[0]),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
        }

        if (count == 2) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: rewards.map((r) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: CategoryRewardCard(reward: r),
                ),
              ),
            )).toList(),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
        }

        // For 3 or more, use a Wrap or Scrollable
        if (availableWidth < 360 && count >= 3) {
           // Scrollable for very narrow screens with many rewards
           return SizedBox(
             height: 180,
             child: ListView.separated(
               scrollDirection: Axis.horizontal,
               itemCount: count,
               separatorBuilder: (context, index) => const SizedBox(width: 12),
               itemBuilder: (context, index) => SizedBox(
                 width: 130,
                 child: CategoryRewardCard(reward: rewards[index]),
               ),
             ),
           ).animate().fadeIn(delay: 300.ms);
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: rewards.map((r) => SizedBox(
            width: count == 3 ? (availableWidth - 48) / 3 : 130,
            child: AspectRatio(
              aspectRatio: 0.72,
              child: CategoryRewardCard(reward: r),
            ),
          )).toList(),
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }

  Widget _buildFinalButtons() {
    final String mainActionLabel = _isFinalRoom ? "KÜTÜPHANEYE DÖN" : "YENİ ODAYI AÇ";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            ref.read(libraryProvider.notifier).consumeCelebration();
            // Return true if we want to focus the next room
            Navigator.pop(context, !_isFinalRoom);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          child: Text(mainActionLabel, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ],
    );
  }
}

class _SmallRewardItem extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _SmallRewardItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
