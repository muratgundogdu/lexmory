import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_typography.dart';
import '../models/daily_mission.dart';

class DailyMissionCard extends StatefulWidget {
  final DailyMissionProgress mission;
  final Function(Offset) onClaim;

  const DailyMissionCard({
    super.key,
    required this.mission,
    required this.onClaim,
  });

  @override
  State<DailyMissionCard> createState() => _DailyMissionCardState();
}

class _DailyMissionCardState extends State<DailyMissionCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Süzülme hızını daha premium bir ritme çektik
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProgress = widget.mission.currentProgress;
    final targetProgress = widget.mission.mission.target;

    bool isClaimed = widget.mission.isClaimed;
    bool isClaimable = currentProgress >= targetProgress && !isClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 4), // Sheet içi boşluk düzeni için optimize edildi
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Toplanmış kartların tasarımı premium koyu arka plana sadık kalacak şekilde revize edildi
        color: isClaimed ? AppColors.surfaceElevated.withValues(alpha:0.4) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClaimed
              ? AppColors.primary.withValues(alpha:0.2)
              : (isClaimable ? AppColors.primaryLight.withValues(alpha:0.4) : AppColors.surfaceElevated),
          width: isClaimable || isClaimed ? 1.5 : 1,
        ),
        boxShadow: isClaimable ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha:0.08),
            blurRadius: 12,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır: İkon + Görev Adı + Sayaç / Durum
          Row(
            children: [
              Text(widget.mission.mission.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.mission.mission.title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isClaimed ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isClaimed)
                Text(
                  '$currentProgress / $targetProgress',
                  style: TextStyle(
                    color: isClaimable ? AppColors.primaryLight : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              if (isClaimed)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Alındı',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
            ],
          ),

          // 🎯 UX DÜZELTMESİ: İlerleme çubuğu sadece devam ederken değil, ödül alınmayı beklerken de full dolu (%100) gözükür
          if (!isClaimed) ...[
            const SizedBox(height: 14),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (currentProgress / targetProgress).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isClaimable ? AppColors.primaryLight : AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Alt Satır: Ödüller ve Al Butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${widget.mission.mission.rewardTokens} Token',
                        style: TextStyle(
                          color: isClaimed ? AppColors.textSecondary : AppColors.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.menu_book_rounded,
                      color: isClaimed ? AppColors.textSecondary : AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '+${widget.mission.mission.rewardBookmarks} Ayraç',
                        style: TextStyle(
                          color: isClaimed ? AppColors.textSecondary : AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isClaimable)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.04), // Hafif ve premium bir esneme
                      child: child,
                    );
                  },
                  child: Builder(
                    builder: (btnCtx) {
                      return ElevatedButton(
                        onPressed: () {
                          final RenderBox box = btnCtx.findRenderObject() as RenderBox;
                          // Find center of the button for better animation start point
                          final center = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
                          widget.onClaim(center);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          shadowColor: AppColors.primary.withValues(alpha:0.4),
                        ),
                        child: const Text(
                          'ÖDÜLÜ AL',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}