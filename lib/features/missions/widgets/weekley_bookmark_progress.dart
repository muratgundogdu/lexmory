import 'package:flutter/material.dart';
// Kendi projenin model import yolunu buraya yaz:
// import '../models/daily_mission.dart'; // Eğer oradaysa
// import '../../missions/models/daily_mission.dart'; // Tahmini yol
import '../../../../core/app_colors.dart';
import '../../../../core/app_typography.dart';
import '../models/mission_status.dart'; // ChestStatus enum'ı için

class WeeklyBookmarkCard extends StatefulWidget {
  final int current;
  final int maxTarget = 21;

  // 🎯 YENİ: Hangi sandıkların açıldığını tutan seti artık dışarıdan alıyoruz
  final Set<int> claimedChests;
  final Function(int chestValue)? onClaimChest;

  const WeeklyBookmarkCard({
    super.key,
    required this.current,
    required this.claimedChests, // 🎯 Zorunlu alan yaptık
    this.onClaimChest,
  });

  @override
  State<WeeklyBookmarkCard> createState() => _WeeklyBookmarkCardState();
}

class _WeeklyBookmarkCardState extends State<WeeklyBookmarkCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true); // Lüks ve asil bir ritimde yavaşça süzülme
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (widget.current / widget.maxTarget).clamp(0.0, 1.0);

    // Dinamik sonraki hedef hesaplama mantığı
    String nextTargetTitle = '🥇 Altın Sandık';
    int nextTargetValue = 21;
    String badge = '🥇';

    if (widget.current < 7) {
      nextTargetTitle = '🥉 Bronz Sandık';
      nextTargetValue = 7;
      badge = '🥉';
    } else if (widget.current < 14) {
      nextTargetTitle = '🥈 Gümüş Sandık';
      nextTargetValue = 14;
      badge = '🥈';
    }

    int remaining = nextTargetValue - widget.current;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          // Sağ arka plandaki lüks transparan ikon
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.auto_stories, size: 85, color: AppColors.primary),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: Başlık ve Büyük Sayaç
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Haftalık Koleksiyon',
                        style: AppTypography.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.current} / ${widget.maxTarget}',
                    style: AppTypography.pageTitle.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Milestone Eşiklerini Barındıran Progress Bar Alanı
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ana Çizgi (Progress Bar)
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                  // Eşik Çizgileri ve TIKLANABİLİR İkonları (7 - 14 - 21)
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 80) * (7 / 21) - 10,
                    top: -6, // Tıklama alanı için hafif optimize edildi
                    child: _buildMilestoneIndicator('🥉', 7),
                  ),
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 80) * (14 / 21) - 10,
                    top: -6,
                    child: _buildMilestoneIndicator('🥈', 14),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: _buildMilestoneIndicator('🥇', 21),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Eşik Alt Yazıları (7, 14, 21 Ayracı yazıları)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Text('7 Ayraç', style: TextStyle(color: widget.current >= 7 ? AppColors.primaryLight : AppColors.textMuted, fontSize: 11, fontWeight: widget.current >= 7 ? FontWeight.bold : FontWeight.normal)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text('14 Ayraç', style: TextStyle(color: widget.current >= 14 ? AppColors.primaryLight : AppColors.textMuted, fontSize: 11, fontWeight: widget.current >= 14 ? FontWeight.bold : FontWeight.normal)),
                  ),
                  Text('21', style: TextStyle(color: widget.current >= 21 ? AppColors.primaryLight : AppColors.textMuted, fontSize: 11)),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceElevated, height: 1),
              const SizedBox(height: 12),

              // Sonraki Hedef Odak Alanı
              Row(
                children: [
                  Text(badge, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Sonraki Hedef: ',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    nextTargetTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    remaining > 0 ? '$remaining ayraç kaldı' : 'Maksimum seviye!',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎯 YENİLENDİ: Tıklanabilir, Animasyonlu Premium Sandık Butonu
  Widget _buildMilestoneIndicator(String emoji, int targetValue) {
    bool isAchieved = widget.current >= targetValue;

    // 🎯 DÜZELTME: Sabit "false" yerine artık diskten gelen gerçek veriye baktırıyoruz!
    bool isClaimed = widget.claimedChests.contains(targetValue);
    bool isClaimable = isAchieved && !isClaimed;

    Widget indicator = Opacity(
      opacity: isClaimed ? 0.3 : (isAchieved ? 1.0 : 0.4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isClaimed
                ? Colors.transparent
                : (isClaimable ? AppColors.primary : (isAchieved ? AppColors.primaryLight : Colors.transparent)),
            width: isClaimable || isClaimed ? 1.5 : 1,
          ),
          boxShadow: isClaimable ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: Text(
          isClaimed ? '✅' : emoji, // Ödül alındıysa yerine şık bir onay işareti koyar
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );

    if (isClaimable) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.04),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (widget.onClaimChest != null) {
                widget.onClaimChest!(targetValue);
              }
            },
            borderRadius: BorderRadius.circular(20),
            splashColor: AppColors.primaryLight.withOpacity(0.2),
            highlightColor: Colors.transparent,
            child: indicator,
          ),
        ),
      );
    }

    return indicator;
  }
}