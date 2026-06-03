import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/regen_countdown.dart';
import '../models/game_state.dart';

class GameHeader extends ConsumerStatefulWidget {
  final GameState game;
  final GlobalKey tokenKey;    // Token kutusu için
  final GlobalKey? categoryKey; // Kategori metni için (Tutorial için eklendi)

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
        if (mounted){ setState(() => _showParticles = false);}
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

// build metodundaki Column yapısını şu şekilde güncelle:
  @override
  Widget build(BuildContext context) {
    final bool isPenalty = widget.game.isLastAttemptCorrect == false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCategoryInfo(),
          // Token ve Geri Sayım Alanı
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTokenBadge(isPenalty),
              const SizedBox(height: 4),
              // HEADER ALTINDAKİ GERİ SAYIM
              RegenCountdown(
                lastRegenTime: widget.game.lastRegenTime,
                currentTokens: widget.game.tokens,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white38,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return Column(
      key: widget.categoryKey, // ANAHTARI BURAYA BAĞLA
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("KATEGORİ",
            style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
        Text(widget.game.category,
            style: GoogleFonts.baloo2(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber[100])),
      ],
    );
  }

  Widget _buildTokenBadge(bool isPenalty) {
    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: [
        // --- KRİTİK ÇÖZÜM: GÖRÜNMEZ SABİT KEY HEDEFİ ---
        // Bu kutu asla animasyona girmez, bu yüzden "Multiple Key" hatası vermez.
        // Coin parçacıkları hala bu konumu hedef alır.
        SizedBox(
          key: widget.tokenKey,
          width: 100, // 80'den 120'ye çıkarıldı
          height: 45, // 30'dan 45'e çıkarıldı
        ),

        // --- LOKAL COIN PARÇACIKLARI ---
        if (_showParticles)
          ...List.generate(12, (index) {
            return Positioned(
              left: 10,
              child: const Text("🪙", style: TextStyle(fontSize: 16))
                  .animate(key: ValueKey("cp_${widget.game.rewardTrigger}_$index"))
                  .fadeIn(duration: 200.ms)
                  .move(
                begin: Offset(-60 - (index * 10), -20 + (index * 5)),
                end: Offset.zero,
                duration: (600 + (index * 70)).ms,
                curve: Curves.easeOutQuint,
              )
                  .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1))
                  .fadeOut(delay: 500.ms),
            );
          }),

        // --- GÖRSEL TOKEN KUTUSU (Key İçermez) ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPenalty ? Colors.redAccent : Colors.amber.withValues(alpha:0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🪙", style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                "$_displayTokens",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        )
        // Animasyonlar Container'a uygulanır ama Key üstteki statik SizedBox'tadır.
            .animate(target: isPenalty ? 1 : 0)
            .shake(hz: 8, duration: 400.ms)
            .tint(color: Colors.red, end: 0.2, duration: 150.ms)
            .animate(target: _showParticles ? 1 : 0)
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 300.ms, curve: Curves.easeOutBack)
            .tint(color: Colors.amber, end: 0.1, duration: 300.ms),
      ],
    );
  }
}