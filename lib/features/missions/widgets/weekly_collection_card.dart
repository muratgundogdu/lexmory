import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_colors.dart';
import '../../../../data/chest_configs.dart';

enum MilestoneState { locked, next, ready, claimed }

class WeeklyCollectionCard extends ConsumerStatefulWidget {
  final int current;
  final Set<int> claimedChests;
  final Function(int chestValue)? onClaimChest;
  
  // Static key for the animation target
  static final GlobalKey progressTargetKey = GlobalKey();

  const WeeklyCollectionCard({
    super.key,
    required this.current,
    required this.claimedChests,
    this.onClaimChest,
  });

  @override
  ConsumerState<WeeklyCollectionCard> createState() => WeeklyCollectionCardState();
}

class WeeklyCollectionCardState extends ConsumerState<WeeklyCollectionCard> with SingleTickerProviderStateMixin {
  final int maxTarget = 21;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void pulse() {
    if (mounted) {
      _pulseController.forward(from: 0.0);
    }
  }

  MilestoneState _getState(int target) {
    if (widget.claimedChests.contains(target)) return MilestoneState.claimed;
    if (widget.current >= target) return MilestoneState.ready;
    
    if (target == 7 && widget.current < 7) return MilestoneState.next;
    if (target == 14 && widget.current >= 7 && widget.current < 14) return MilestoneState.next;
    if (target == 21 && widget.current >= 14 && widget.current < 21) return MilestoneState.next;
    
    return MilestoneState.locked;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildProgressArea(context),
          const SizedBox(height: 32),
          _buildFooterStatus(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Haftalık Koleksiyon",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Kart topla, ödülleri kazan!",
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            key: WeeklyCollectionCard.progressTargetKey,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${widget.current} / $maxTarget",
                style: GoogleFonts.outfit(
                  color: AppColors.primaryLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "Toplanan Kartlar",
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressArea(BuildContext context) {
    const double milestoneWidth = 64.0;
    const double horizontalPadding = 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth - horizontalPadding * 2;
        
        return Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Rail Background
              Positioned(
                left: 0,
                right: 0,
                top: 48,
                child: _WeeklyProgressTrack(current: widget.current, maxTarget: maxTarget),
              ),

              // 2. Milestone 7 (33.33%)
              Positioned(
                left: (trackWidth * (7 / 21)) - (milestoneWidth / 2),
                top: 0,
                child: SizedBox(
                  width: milestoneWidth,
                  child: _WeeklyMilestoneReward(
                    target: 7,
                    assetPath: chestConfigs['wooden_chest']?.imagePath ?? '',
                    state: _getState(7),
                    accentColor: const Color(0xFFCD7F32),
                    onTap: () => widget.onClaimChest?.call(7),
                  ),
                ),
              ),

              // 3. Milestone 14 (66.66%)
              Positioned(
                left: (trackWidth * (14 / 21)) - (milestoneWidth / 2),
                top: 0,
                child: SizedBox(
                  width: milestoneWidth,
                  child: _WeeklyMilestoneReward(
                    target: 14,
                    assetPath: chestConfigs['silver_chest']?.imagePath ?? '',
                    state: _getState(14),
                    accentColor: const Color(0xFFC0C0C0),
                    onTap: () => widget.onClaimChest?.call(14),
                  ),
                ),
              ),

              // 4. Milestone 21 (100%)
              Positioned(
                left: trackWidth - (milestoneWidth / 2),
                top: 0,
                child: SizedBox(
                  width: milestoneWidth,
                  child: _WeeklyMilestoneReward(
                    target: 21,
                    assetPath: chestConfigs['golden_chest']?.imagePath ?? '',
                    state: _getState(21),
                    accentColor: AppColors.primaryLight,
                    onTap: () => widget.onClaimChest?.call(21),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterStatus() {
    String mainText = "Sonraki Ödül";
    String targetName = "";
    Color targetColor = AppColors.primary;
    int remaining = 0;
    
    if (widget.current < 7) {
      targetName = "Bronz Sandık";
      targetColor = const Color(0xFFCD7F32);
      remaining = 7 - widget.current;
    } else if (widget.current < 14) {
      targetName = "Gümüş Sandık";
      targetColor = const Color(0xFFC0C0C0);
      remaining = 14 - widget.current;
    } else if (widget.current < 21) {
      targetName = "Altın Sandık";
      targetColor = AppColors.primaryLight;
      remaining = 21 - widget.current;
    } else {
      mainText = "Haftalık koleksiyon tamamlandı!";
      targetName = "Tüm ödülleri topladın";
      targetColor = AppColors.success;
      remaining = 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text("📦", style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainText,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  targetName,
                  style: GoogleFonts.outfit(
                    color: targetColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (remaining > 0)
            Text(
              "$remaining kart kaldı",
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _WeeklyMilestoneReward extends StatelessWidget {
  final int target;
  final String assetPath;
  final MilestoneState state;
  final Color accentColor;
  final VoidCallback onTap;

  const _WeeklyMilestoneReward({
    required this.target,
    required this.assetPath,
    required this.state,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocked = state == MilestoneState.locked;
    final bool isNext = state == MilestoneState.next;
    final bool isReady = state == MilestoneState.ready;
    final bool isClaimed = state == MilestoneState.claimed;

    double baseOpacity = 1.0;
    if (isLocked) baseOpacity = 0.45;
    if (isClaimed) baseOpacity = 0.65;

    double baseScale = 1.0;
    if (isNext) baseScale = 1.08;
    if (isReady) baseScale = 1.1;

    final Color numberColor = isLocked ? Colors.white24 : (isNext || isReady ? AppColors.primaryLight : accentColor);

    return GestureDetector(
      onTap: isReady ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Glow Effect (Only when ready)
              if (isReady)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.2 + (value * 0.15)),
                            blurRadius: 15 + (value * 10),
                            spreadRadius: 2 + (value * 4),
                          )
                        ],
                      ),
                    );
                  },
                ),
              
              // 2. Chest Image with Animation
              AnimatedScale(
                scale: baseScale,
                duration: const Duration(milliseconds: 300),
                child: AnimatedOpacity(
                  opacity: baseOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: _buildChestGraphic(isLocked),
                ),
              ),

              // 3. Claimed Check Badge
              if (isClaimed)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                  ),
                ),

              // 4. Connector Node to Rail
              Positioned(
                bottom: -14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFF2E2E32) : accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A1A1E), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            target.toString(),
            style: GoogleFonts.outfit(
              color: numberColor,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          Text(
            isClaimed ? "Alındı" : (isReady ? "Hazır" : (isNext ? "Sıradaki" : "Kilitli")),
            style: GoogleFonts.outfit(
              color: isReady ? Colors.green : (isNext ? AppColors.primaryLight : Colors.white24),
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChestGraphic(bool isLocked) {
    Widget img = Image.asset(
      assetPath,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          return const Icon(Icons.bug_report, color: Colors.red, size: 32);
        }
        return const SizedBox(width: 48, height: 48);
      },
    );

    if (isLocked) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.65, 0, 0, 0, 0,
          0, 0.65, 0, 0, 0,
          0, 0.65, 0, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: img,
      );
    }
    return img;
  }
}

class _WeeklyProgressTrack extends StatelessWidget {
  final int current;
  final int maxTarget;

  const _WeeklyProgressTrack({
    required this.current,
    required this.maxTarget,
  });

  @override
  Widget build(BuildContext context) {
    double progress = (current / maxTarget).clamp(0.0, 1.0);

    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4A574), Color(0xFFF2C078)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
