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
import '../widgets/weekley_bookmark_progress.dart';

class DailyMissionSheet extends ConsumerStatefulWidget {
  const DailyMissionSheet({super.key});

  @override
  ConsumerState<DailyMissionSheet> createState() => _DailyMissionSheetState();
}

class _DailyMissionSheetState extends ConsumerState<DailyMissionSheet> {
  late Timer _countdownTimer;
  Duration _timeUntilReset = const Duration(hours: 23, minutes: 59, seconds: 59);

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
  void _showFlyingBookmarkAnimation(BuildContext context, Offset startOffset) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          onEnd: () => overlayEntry.remove(),
          builder: (context, value, child) {
            final currentY = startOffset.dy - (value * 140);
            final currentX = startOffset.dx - (value * 30);

            return Positioned(
              left: currentX,
              top: currentY,
              child: Opacity(
                opacity: (1.0 - value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1.0 + (value * 0.25),
                  child: const Material(
                    color: Colors.transparent,
                    child: Text('📖', style: TextStyle(fontSize: 30)),
                  ),
                ),
              ),
            );
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

    final bool isSuccess = await notifier.claimMission(progressData.mission.id);

    if (isSuccess) {
      _showFlyingBookmarkAnimation(context, startPosition);
      await ref.read(gameProvider.notifier).addTokens(progressData.mission.rewardTokens);

      if (mounted) {
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
                const Text('📖', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    '+1 Ayraç',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
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

  /// 🎁 🎯 YENİ: PREMIUM TIKLANABİLİR HAFTALIK SANDIK ÖDÜLÜ ALMA METODU
  /// 🎁 🎯 PREMIUM TIKLANABİLİR HAFTALIK SANDIK ÖDÜLÜ ALMA METODU
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

    // 🎯 DÜZELTME: Artık gerçek provider kontrolü çalışıyor!
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
            // 🎯 DÜZELTME: borderSide parametresini buradan siliyoruz, RoundedRectangleBorder'ın içine taşıyoruz:
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primary, width: 1), // Lüks altın sınır çizgisi buraya geldi
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

    if (missionState.isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst Sürükleme Çubuğu
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Başlık ve Premium Sayaç Alanı (Taşma Korumalı)
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
          WeeklyBookmarkCard(
            current: missionState.weeklyBookmarks,
            claimedChests: missionState.claimedChestValues, // 🎯 İŞTE BU YENİ VERİYİ KARTA PASLIYORUZ!
            onClaimChest: (chestValue) => _onClaimChestReward(chestValue),
          ),
          const SizedBox(height: 20),

          // Günün Aktif 3 Görevi Listesi
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: missionState.missions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final progressData = missionState.missions[index];

                return DailyMissionCard(
                  mission: progressData,
                  onClaim: (offset) => _onClaimReward(progressData, offset),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}