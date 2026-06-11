import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_dimens.dart';
import '../../../core/app_typography.dart';
import '../../../core/utils.dart';
import '../../../widgets/regen_countdown.dart';
import '../models/game_state.dart';

class GameHeader extends ConsumerStatefulWidget {
  final GameState game;
  final GlobalKey tokenKey;
  final GlobalKey? categoryKey;

  const GameHeader({
    super.key,
    required this.game,
    required this.tokenKey,
    this.categoryKey,
  });

  @override
  ConsumerState<GameHeader> createState() => _GameHeaderState();
}

class _GameHeaderState extends ConsumerState<GameHeader> {
  late int _displayTokens;
  Timer? _timer;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _displayTokens = widget.game.tokens;
  }

  @override
  void didUpdateWidget(GameHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ödül tetiklendiğinde parçacıkları göster
    if (widget.game.rewardTrigger > oldWidget.game.rewardTrigger) {
      setState(() => _showParticles = true);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _showParticles = false);
      });
    }

    // Sayacı güncelleme mantığı
    if (!widget.game.showCategoryCompletePanel) {
      if (widget.game.tokens != _displayTokens) {
        _startRollingCounter(widget.game.tokens);
      }
    }
  }

  void _startRollingCounter(int target) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      int diff = (target - _displayTokens).abs();
      int step = diff > 100 ? 8 : (diff > 50 ? 4 : 1);

      if (_displayTokens < target) {
        setState(() => _displayTokens = min(target, _displayTokens + step));
      } else if (_displayTokens > target) {
        setState(() => _displayTokens = max(target, _displayTokens - step));
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPenalty = widget.game.isLastAttemptCorrect == false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // GameHeader build metodu içindeki Row yapısını bu şekilde güncelle:

        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Üstten hizalama önemli
          children: [
            // 1. SOL: Token alanı (Genişliği içeriğe göre, ama aşırı büyümesini engelliyoruz)
            IntrinsicWidth(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTokenArea(isPenalty),
              ),
            ),

            // 2. ORTA: Kategori Bloğu (Esnek Alan)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8), // Yanlardan boşluk
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "KATEGORİ",
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 3.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      key: widget.categoryKey,
                      child: Column(
                        children: [
                          Text(
                            widget.game.category.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2, // Çok uzunsa 2 satıra izin ver
                            overflow: TextOverflow.ellipsis, // Hala sığmazsa ... yap
                            style: AppTypography.pageTitle.copyWith(
                              // Kategori çok uzunsa fontu küçült (Dinamik fontSize)
                              fontSize: widget.game.category.length > 15 ? 16 : 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Altın Dekoratif Çizgi
                          Container(
                            width: 30,
                            height: 2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.primary,
                                  Colors.transparent
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),

            // 3. SAĞ: Streak Badge (İçeriğine göre genişlik alır)
            IntrinsicWidth(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _buildStreakArea(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokenArea(bool isPenalty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTokenBadge(isPenalty),
        const SizedBox(height: 4), // Rozet ile metin arası boşluk
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SATIR: Başlık
              Text(
                "Yenileniyor..",
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 7.5,
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1), // İki satır arası çok dar boşluk
              // 2. SATIR: Geri sayım süresi
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: RegenCountdown(
                  lastRegenTime: widget.game.lastRegenTime,
                  currentTokens: widget.game.tokens,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 10,
                    color: AppColors.primary, // Süre altın sarısı (primary)
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakArea() {
    // Streak 0 ise alanı ayırıyoruz ki simetri bozulmasın
    if (widget.game.streak == 0) {
      return const SizedBox(width: 40, height: 36);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.warning, size: 16),
          const SizedBox(width: 4),
          Text(
            "x${widget.game.streak}",
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildTokenBadge(bool isPenalty) {
    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: [
        // Tutorial parmağı burayı hedef alır
        SizedBox(
          key: widget.tokenKey,
          width: 85,
          height: 36,
        ),

        // Coin Parçacıkları
        if (_showParticles)
          ...List.generate(6, (index) {
            return Positioned(
              left: 10,
              child: const Text("🪙", style: TextStyle(fontSize: 14))
                  .animate(key: ValueKey("cp_${widget.game.rewardTrigger}_$index"))
                  .fadeIn(duration: 200.ms)
                  .move(
                begin: Offset(-30 - (index * 6), -10 + (index * 3)),
                end: Offset.zero,
                duration: (500 + (index * 40)).ms,
                curve: Curves.easeOutQuint,
              )
                  .fadeOut(delay: 300.ms),
            );
          }),

        // Görsel Token Kutusu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            border: Border.all(
              color: isPenalty ? AppColors.error : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🪙", style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                formatTokenCount(_displayTokens),
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isPenalty ? AppColors.error : AppColors.primary,
                ),
              ),
            ],
          ),
        )
            .animate(target: isPenalty ? 1 : 0)
            .shake(hz: 6, duration: 400.ms)
            .animate(target: _showParticles ? 1 : 0)
            .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 200.ms)
            .tint(color: AppColors.primary, end: 0.1),
      ],
    );
  }
}