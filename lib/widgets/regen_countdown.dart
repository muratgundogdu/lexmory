import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegenCountdown extends StatefulWidget {
  final DateTime lastRegenTime;
  final int currentTokens;
  final TextStyle? style;

  const RegenCountdown({
    super.key,
    required this.lastRegenTime,
    required this.currentTokens,
    this.style,
  });

  @override
  State<RegenCountdown> createState() => _RegenCountdownState();
}

class _RegenCountdownState extends State<RegenCountdown> {
  Timer? _timer;
  String _timeLeft = "";

  @override
  void initState() {
    super.initState();
    _calculateTime();
    // Her saniye süreyi güncelle
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTime());
  }

  @override
  void didUpdateWidget(RegenCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tokenlar değiştiğinde veya zaman güncellendiğinde anında hesapla
    _calculateTime();
  }

  void _calculateTime() {
    // 100 jeton ve üzerindeyse süreyi gizle (Ekonomi kuralı)
    if (widget.currentTokens >= 100) {
      if (mounted) setState(() => _timeLeft = "");
      return;
    }

    // Mevcut ekonomi: 10 dakikada bir yenilenme
    final nextRegen = widget.lastRegenTime.add(const Duration(minutes: 10));
    final remaining = nextRegen.difference(DateTime.now());

    if (remaining.isNegative) {
      // Süre dolduysa ama henüz provider'dan yeni veri gelmediyse 00:00 göster
      if (mounted) setState(() => _timeLeft = "00:00");
    } else {
      final mins = remaining.inMinutes.toString().padLeft(2, '0');
      final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      if (mounted) setState(() => _timeLeft = "$mins:$secs");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Süre yoksa veya tokenlar doluysa widget'ı tamamen gizle
    if (widget.currentTokens >= 100 || _timeLeft.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      _timeLeft,
      style: widget.style ?? GoogleFonts.outfit(
        fontSize: 10,
        color: Colors.white.withValues(alpha: 0.3),
        letterSpacing: 0.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}