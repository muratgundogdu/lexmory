import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tutorial/models/tutorial_state.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';

class JokerBar extends ConsumerWidget {
  final GameState game;
  final GlobalKey? hintKey;
  final GlobalKey? clearKey;
  final GlobalKey? revealKey;

  const JokerBar({
    super.key,
    required this.game,
    this.hintKey,
    this.clearKey,
    this.revealKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {    final notifier = ref.read(gameProvider.notifier);
  final tutorial = ref.watch(tutorialProvider);

  final step = tutorial.currentStep;
  final bool isTutorialActive = tutorial.isTutorialActive;

  // 1. Ana tutorial (Phase 1 ve 2 - ELMA bölümü) kontrolü
  final bool isPhase1or2 = isTutorialActive &&
      (tutorial.phase == TutorialPhase.phase1 || tutorial.phase == TutorialPhase.phase2);

  // 2. Tıklama İzinlerini Tanımlayalım
  // Eğer tutorial aktifse; sadece o anki adıma ait butona izin ver.
  // Eğer tutorial aktif değilse (normal oyun); Phase 1 veya 2'de değilsek izin ver.

  final bool canUseHint = isTutorialActive
      ? (step == TutorialStep.forcedHint)
      : !isPhase1or2;

  final bool canUseClear = isTutorialActive
      ? (step == TutorialStep.forcedClear)
      : !isPhase1or2;

  final bool canUseReveal = isTutorialActive
      ? (step == TutorialStep.forcedReveal) // Eğer tutorial aktifse sadece forcedReveal adımında izin ver
      : (!isPhase1or2 && game.hasStarted && !game.isInitialReveal);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _JokerButton(
          key: hintKey,
          icon: Icons.lightbulb_outline,
          label: "Harf Aç",
          cost: 80,
          // canUseHint değişkenini burada kullanıyoruz
          onTap: (tutorial.isTutorialActive)
              ? (tutorial.currentStep == TutorialStep.forcedHint ? () => notifier.useHint() : null)
              : () => notifier.useHint(),
        ),
        _JokerButton(
          key: clearKey,
          icon: Icons.auto_fix_high,
          label: "Yanlış Sil",
          cost: 60,
          // canUseClear değişkenini burada kullanıyoruz
          onTap: (tutorial.isTutorialActive)
              ? (tutorial.currentStep == TutorialStep.forcedClear ? () => notifier.clearWrong() : null)
              : () => notifier.clearWrong(),
        ),
        _JokerButton(
          key: revealKey,
          icon: Icons.visibility_outlined,
          label: "Tekrar",
          cost: 40,
          // canUseReveal değişkenini burada kullanıyoruz
          onTap: canUseReveal ? () => notifier.showAgain() : null,
        ),
      ],
    ),
  );
  }
}

/// Joker Buton Tasarımı (Hatanın çözümü için bu sınıfı ekledik)
class _JokerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int cost;
  final VoidCallback? onTap;

  // HATA BURADAYDI: Constructor'a 'super.key' parametresini ekledik
  const _JokerButton({
    super.key, // <--- BU SATIRI EKLEYİN
    required this.icon,
    required this.label,
    required this.cost,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: Colors.amber[100], size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(
              "🪙 $cost",
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}