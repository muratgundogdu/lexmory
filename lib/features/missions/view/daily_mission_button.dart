import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';

class DailyMissionButton extends StatelessWidget {
  final bool hasPendingDailyMission;
  final VoidCallback? onPressed;

  const DailyMissionButton({
    super.key,
    required this.hasPendingDailyMission,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 DÜZELTME: Buton alanını 40x40 kare olarak sabitliyoruz.
    // Böylece dış etkenler noktayı ve emojiyi sağa sola fırlatamayacak.
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Text('🎯', style: TextStyle(fontSize: 24)),
            onPressed: onPressed,
          ),

          if (hasPendingDailyMission)
          // 🎯 MİLİMETRİK AYAR: 40x40'lık alanda emojinin tam sağ üst kıvrımı
            Positioned(
              right: 4,
              top: 4,
              child: IgnorePointer(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha:0.4),
                        blurRadius: 3,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}