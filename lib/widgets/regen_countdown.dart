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
  late String _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTime());
  }

  void _calculateTime() {
    if (widget.currentTokens >= 100) {
      if (mounted) setState(() => _timeLeft = "");
      return;
    }

    final nextRegen = widget.lastRegenTime.add(const Duration(minutes: 10));
    final remaining = nextRegen.difference(DateTime.now());

    if (remaining.isNegative) {
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
    if (widget.currentTokens >= 100 || _timeLeft.isEmpty) return const SizedBox.shrink();

    return Text(
      _timeLeft,
      style: widget.style ?? GoogleFonts.poppins(
        fontSize: 10,
        color: Colors.white38,
        letterSpacing: 0.5,
      ),
    );
  }
}