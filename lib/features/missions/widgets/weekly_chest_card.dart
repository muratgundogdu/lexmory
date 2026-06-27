import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_typography.dart';
import '../models/mission_status.dart';

class WeeklyChestZone extends StatelessWidget {
  final int currentBookmarks;
  final ChestStatus bronzeStatus;
  final ChestStatus silverStatus;
  final ChestStatus goldStatus;
  final VoidCallback onOpenBronze;
  final VoidCallback onOpenSilver;
  final VoidCallback onOpenGold;

  const WeeklyChestZone({
    super.key,
    required this.currentBookmarks,
    required this.bronzeStatus,
    required this.silverStatus,
    required this.goldStatus,
    required this.onOpenBronze,
    required this.onOpenSilver,
    required this.onOpenGold,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ADIM: Bronz alınmadıysa veya henüz 7'ye ulaşma aşamasındaysa SADECE BRONZ göster
    if (bronzeStatus != ChestStatus.claimed) {
      return _buildChestCard(
        title: '🥉 Bronz Sandık',
        icon: '📦',
        current: currentBookmarks,
        target: 7,
        rewardText: '🎁 500 Token',
        themeColor: const Color(0xFFCD7F32),
        isReady: bronzeStatus == ChestStatus.claimable,
        onOpen: onOpenBronze,
      );
    }

    // 2. ADIM: Bronz alındıysa ama Gümüş henüz tamamlanıp talep edilmediyse SADECE GÜMÜŞ göster
    if (silverStatus != ChestStatus.claimed) {
      return _buildChestCard(
        title: '🥈 Gümüş Sandık',
        icon: '🪙',
        current: currentBookmarks,
        target: 14,
        rewardText: '🎁 1000 Token + 2 Joker',
        themeColor: const Color(0xFFC0C0C0),
        isReady: silverStatus == ChestStatus.claimable,
        onOpen: onOpenSilver,
      );
    }

    // 3. ADIM: Gümüş de alındıysa artık geriye sadece HEDEF ALTIN kalır
    return _buildChestCard(
      title: '🥇 Altın Sandık',
      icon: '👑',
      current: currentBookmarks,
      target: 21,
      rewardText: '🎁 1500 Token + 5 Joker + Rozet',
      themeColor: AppColors.primaryLight,
      isReady: goldStatus == ChestStatus.claimable,
      onOpen: onOpenGold,
      isGold: true,
    );
  }

  Widget _buildChestCard({
    required String title,
    required String icon,
    required int current,
    required int target,
    required String rewardText,
    required Color themeColor,
    required bool isReady,
    required VoidCallback onOpen,
    bool isGold = false,
  }) {
    int remaining = target - current;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isReady ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady ? themeColor : AppColors.surfaceElevated,
          width: isReady ? 2 : 1,
        ),
        boxShadow: isGold && isReady ? [
          BoxShadow(
            color: AppColors.primaryLight.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isReady ? themeColor.withOpacity(0.15) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: TextStyle(fontSize: isReady ? 30 : 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(rewardText, style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isReady
                      ? 'Hedef Tamamlandı, Açılabilir!'
                      : (remaining > 0 ? '$remaining ayraç sonra hedef aktif' : '$current / $target Ayraç'),
                  style: TextStyle(color: isReady ? themeColor : AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isReady ? onOpen : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              disabledBackgroundColor: AppColors.surfaceElevated,
              foregroundColor: AppColors.background,
              disabledForegroundColor: AppColors.textMuted.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              isReady ? 'AÇ' : 'KİLİTLİ',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}