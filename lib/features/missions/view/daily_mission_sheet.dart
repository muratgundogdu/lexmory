import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/app_colors.dart';
import '../../../../core/app_typography.dart';

// Projedeki mevcut widget ve enum yolları
import '../../game/providers/game_provider.dart';
import '../models/daily_mission.dart';
import '../providers/daily_mission_provider.dart';
import '../widgets/daily_mission_card.dart';
import '../widgets/weekly_collection_card.dart';

class DailyMissionSheet extends ConsumerStatefulWidget {
  const DailyMissionSheet({super.key});

  @override
  ConsumerState<DailyMissionSheet> createState() => _DailyMissionSheetState();
}

class _DailyMissionSheetState extends ConsumerState<DailyMissionSheet> {
  late Timer _countdownTimer;
  Duration _timeUntilReset = const Duration(hours: 23, minutes: 59, seconds: 59);

  // Animation Queue & Visual State
  final List<_PendingAnimation> _animationQueue = [];
  bool _isAnimating = false;
  int? _visualWeeklyBookmarks;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilReset();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _syncVisualBookmarks(int actualValue) {
    _visualWeeklyBookmarks ??= actualValue;
  }

  void _enqueueAnimation(Offset startOffset, int rewardAmount) {
    // Respect reduced motion if enabled
    if (MediaQuery.maybeOf(context)?.accessibleNavigation ?? false) {
      setState(() {
        _visualWeeklyBookmarks = (_visualWeeklyBookmarks ?? 0) + rewardAmount;
      });
      final state = WeeklyCollectionCard.progressTargetKey.currentContext?.findAncestorStateOfType<WeeklyCollectionCardState>();
      state?.pulse();
      return;
    }

    _animationQueue.add(_PendingAnimation(startOffset: startOffset, rewardAmount: rewardAmount));
    _processNextAnimation();
  }

  void _processNextAnimation() {
    if (_animationQueue.isEmpty || _isAnimating) return;

    final pending = _animationQueue.removeAt(0);
    _isAnimating = true;

    // We need to wait for a frame to ensure target is rendered if it just appeared
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showFlyingBookmarkAnimation(context, pending);
    });
  }

  /// Gece 00:00'a kalan süreyi sistem saatine bağımlı ve kesin olarak hesaplar
  void _calculateTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (mounted) {
      setState(() {
        _timeUntilReset = tomorrow.difference(now);
      });
    }
  }

  /// Her saniye sapma olmadan tetiklenen akıllı sayaç döngüsü
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeUntilReset();
      if (_timeUntilReset.inSeconds <= 0) {
        ref.read(dailyMissionProvider.notifier).resetForNewDayIfNeeded();
      }
    });
  }

  /// Taşma riskini en aza indiren kompakt sayaç formatı
  String _getRemainingTimeText() {
    final hours = _timeUntilReset.inHours;
    final minutes = _timeUntilReset.inMinutes.remainder(60);
    return 'Yenilenme: ${hours}s ${minutes}dk';
  }

  /// ✈️ PREMIUM UÇAN AYRAÇ (📖) ANİMASYON MOTORU
  void _showFlyingBookmarkAnimation(BuildContext context, _PendingAnimation pending) {
    // Find target position using GlobalKey
    final RenderBox? targetBox = WeeklyCollectionCard.progressTargetKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (targetBox == null) {
      // If target not found, just update count and move on
      setState(() {
        _visualWeeklyBookmarks = (_visualWeeklyBookmarks ?? 0) + pending.rewardAmount;
        _isAnimating = false;
      });
      _processNextAnimation();
      return;
    }

    final targetOffset = targetBox.localToGlobal(Offset(targetBox.size.width / 2, targetBox.size.height / 2));
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _BookmarkFlightAnimation(
          startOffset: pending.startOffset,
          targetOffset: targetOffset,
          onComplete: () {
            if (mounted) {
              setState(() {
                _visualWeeklyBookmarks = (_visualWeeklyBookmarks ?? 0) + pending.rewardAmount;
                _isAnimating = false;
              });

              // Trigger pulse on the target card
              final state = WeeklyCollectionCard.progressTargetKey.currentContext?.findAncestorStateOfType<WeeklyCollectionCardState>();
              state?.pulse();
              
              overlayEntry.remove();
              _processNextAnimation();
            } else {
              overlayEntry.remove();
            }
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  /// 🎯 PREMIUM GÜNLÜK GÖREV ÖDÜL ALMA METODU
  Future<void> _onClaimReward(DailyMissionProgress progressData, Offset startPosition) async {
    final notifier = ref.read(dailyMissionProvider.notifier);

    if (progressData.isClaimed) return;

    // İlk asenkron işlem (Bekleme başlıyor...)
    final bool isSuccess = await notifier.claimMission(progressData.mission.id);

    // 🔥 2. ADIM: Bekleme bitti! Alt satıra geçmeden önce bu sayfa hala ekranda açık mı kontrol et:
    if (!mounted) return;

    if (isSuccess) {
      // Visual feedback via flying animation
      _enqueueAnimation(startPosition, progressData.mission.rewardBookmarks);

      // İkinci asenkron işlem (Token ekleme süreci...)
      await ref.read(gameProvider.notifier).addTokens(progressData.mission.rewardTokens);

      // 🔥 3. ADIM: İkinci bekleme de bitti! SnackBar göstermeden önce sayfa hala açık mı kontrol et:
      if (!mounted) return;

      // Artık widget'a ait context'i %100 güvenle kullanabiliriz, uyarı tamamen kaybolacak.
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '+${progressData.mission.rewardTokens} Token',
                  style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '+${progressData.mission.rewardBookmarks} Ayraç',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// 🎁 🎯 PREMIUMHAFTALIK SANDIK ÖDÜLÜ ALMA METODU
  Future<void> _onClaimChestReward(int chestValue) async {
    final notifier = ref.read(dailyMissionProvider.notifier);

    int rewardTokens = 100;
    String chestName = 'Bronz Sandık 🥉';

    if (chestValue == 14) {
      rewardTokens = 250;
      chestName = 'Gümüş Sandık 🥈';
    } else if (chestValue == 21) {
      rewardTokens = 500;
      chestName = 'Altın Sandık 🥇';
    }

    final bool isSuccess = await notifier.claimWeeklyChest(chestValue);

    if (isSuccess) {
      // Büyük ödülü cüzdana güvenli bir şekilde ekle
      await ref.read(gameProvider.notifier).addTokens(rewardTokens);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceElevated,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primary, width: 1),
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$chestName Açıldı! +$rewardTokens Token',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionState = ref.watch(dailyMissionProvider);
    _syncVisualBookmarks(missionState.weeklyBookmarks);

    if (missionState.isLoading) {
      return Container(
        height: 400,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Üst Sürükleme Çubuğu
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: Scrollbar(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      // Başlık ve Sayaç Alanı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Günlük Görevler',
                              style: AppTypography.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRemainingTimeText(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Haftalık İlerleme ve Sandıklar Kartı
                      WeeklyCollectionCard(
                        current: _visualWeeklyBookmarks ?? missionState.weeklyBookmarks,
                        claimedChests: missionState.claimedChestValues,
                        onClaimChest: (chestValue) => _onClaimChestReward(chestValue),
                      ),
                      const SizedBox(height: 20),

                      // Günün Aktif 3 Görevi Listesi
                      ...missionState.missions.map((progressData) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DailyMissionCard(
                              mission: progressData,
                              onClaim: (offset) => _onClaimReward(progressData, offset),
                            ),
                          )),
                      
                      // Extra spacing to ensure last card is fully visible above system bar
                      const SizedBox(height: 24),
                      SizedBox(height: MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingAnimation {
  final Offset startOffset;
  final int rewardAmount;

  _PendingAnimation({required this.startOffset, required this.rewardAmount});
}

class _BookmarkFlightAnimation extends StatefulWidget {
  final Offset startOffset;
  final Offset targetOffset;
  final VoidCallback onComplete;

  const _BookmarkFlightAnimation({
    required this.startOffset,
    required this.targetOffset,
    required this.onComplete,
  });

  @override
  State<_BookmarkFlightAnimation> createState() => _BookmarkFlightAnimationState();
}

class _BookmarkFlightAnimationState extends State<_BookmarkFlightAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        
        final p0 = widget.startOffset;
        final p2 = widget.targetOffset;
        
        // Control point for quadratic Bezier (Arc-like path)
        final p1 = Offset(
          (p0.dx + p2.dx) / 2 + 50, 
          (p0.dy + p2.dy) / 2 - 150, 
        );

        final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
        final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
        
        final double opacity = t < 0.1 ? t * 10 : (t > 0.9 ? (1.0 - t) * 10 : 1.0);
        final double scale = t < 0.2 ? 1.0 + t : (t > 0.8 ? 1.2 - (t - 0.8) : 1.2);

        return Positioned(
          left: x - 15,
          top: y - 15,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: t * 0.4,
                child: const Material(
                  color: Colors.transparent,
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
