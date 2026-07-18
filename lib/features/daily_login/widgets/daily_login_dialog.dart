import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../data/chest_configs.dart';
import '../models/daily_login_reward.dart';
import '../providers/daily_login_provider.dart';

class DailyLoginDialog extends ConsumerWidget {
  const DailyLoginDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyLoginProvider);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "GÜNLÜK GİRİŞ ÖDÜLÜ",
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
              const SizedBox(height: 6),
              Text(
                "Her gün gel, ödüllerin büyüsün!",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 24),
              
              // 7 Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final reward = dailyLoginRewards[index];
                  return _DayCell(
                    reward: reward,
                    isClaimed: day < dailyState.currentStreakDay,
                    isCurrent: day == dailyState.currentStreakDay && dailyState.isRewardAvailable,
                    isFuture: day > dailyState.currentStreakDay || (day == dailyState.currentStreakDay && !dailyState.isRewardAvailable),
                  ).animate(delay: (400 + (index * 50)).ms).fadeIn().scale(begin: const Offset(0.8, 0.8));
                },
              ),
              
              const SizedBox(height: 24),
              
              // Claim Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: dailyState.isRewardAvailable && !dailyState.isClaiming
                      ? () async {
                          try {
                            await ref.read(dailyLoginProvider.notifier).claimReward();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Hata: $e")),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: dailyState.isClaiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          "AL",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Kapat",
                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12),
                ),
              ).animate(delay: 1000.ms).fadeIn(),
            ],
          ),
        ),
      ),
    ).animate().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
  }
}

class _DayCell extends StatelessWidget {
  final DailyLoginReward reward;
  final bool isClaimed;
  final bool isCurrent;
  final bool isFuture;

  const _DayCell({
    required this.reward,
    required this.isClaimed,
    required this.isCurrent,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasChest = reward.chestTypeId != null;
    
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFF252529),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Opacity(
        opacity: isClaimed ? 0.3 : (isFuture ? 0.5 : 1.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${reward.day}. GÜN",
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isCurrent ? AppColors.primary : Colors.white38,
              ),
            ),
            const SizedBox(height: 4),
            if (hasChest)
               Image.asset(
                 chestConfigs[reward.chestTypeId]?.imagePath ?? '',
                 width: 32,
                 height: 32,
               )
            else
              const Text("🪙", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              "${reward.tokenAmount}",
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isCurrent ? Colors.white : Colors.white70,
              ),
            ),
            if (isClaimed)
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
          ],
        ),
      ),
    );
  }
}
