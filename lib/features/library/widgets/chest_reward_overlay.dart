import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_typography.dart';
import '../../../data/collections.dart';
import '../models/chest_open_result.dart';
import '../models/card_reward_result.dart';
import 'reward_rarity_style.dart';
import 'reward_ribbon.dart';

class ChestRewardOverlay extends StatefulWidget {
  final ChestOpenResult result;
  final String? title;
  final String? subtitle;

  const ChestRewardOverlay({
    super.key,
    required this.result,
    this.title,
    this.subtitle,
  });

  @override
  State<ChestRewardOverlay> createState() => _ChestRewardOverlayState();
}

class _ChestRewardOverlayState extends State<ChestRewardOverlay> {
  int _currentIndex = 0;
  bool _showingCompletion = false;
  late List<String> _completionList;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _completionList = widget.result.unlockedCharacterIds.toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _precacheAll();
      _initialized = true;
    }
  }

  Future<void> _precacheAll() async {
    for (final reward in widget.result.rewards) {
      precacheImage(AssetImage(reward.card.imagePath), context).catchError((e) {
        debugPrint('Failed to precache reward image: ${reward.card.imagePath}');
      });
    }
    for (final completionId in _completionList) {
      final album = albumSets.firstWhere((a) => a.id == completionId);
      precacheImage(AssetImage(album.characterImagePath), context).catchError((e) {
        debugPrint('Failed to precache character image: ${album.characterImagePath}');
      });
    }
  }

  void _onNext() {
    setState(() {
      if (_currentIndex < widget.result.rewards.length - 1) {
        _currentIndex++;
      } else if (!_showingCompletion && _completionList.isNotEmpty) {
        _showingCompletion = true;
        _currentIndex = 0;
      } else if (_showingCompletion && _currentIndex < _completionList.length - 1) {
        _currentIndex++;
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result.rewards.isEmpty && _completionList.isEmpty) {
      return Material(
        color: Colors.black.withValues(alpha: 0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text("Ödül alınırken bir hata oluştu.", style: AppTypography.bodyLarge),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("KAPAT"),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha:0.9),
        child: GestureDetector(
          onTap: _onNext,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _showingCompletion 
                  ? _buildCompletionView(_completionList[_currentIndex])
                  : _buildRewardView(widget.result.rewards[_currentIndex]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardView(CardRewardResult reward) {
    final card = reward.card;
    final rarityStyle = RewardRarityStyle.from(card.rarity);

    return Column(
      key: ValueKey('reward_${card.id}_$_currentIndex'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!.toUpperCase(),
            style: GoogleFonts.outfit(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
        ] else if (widget.title != null)
           const SizedBox(height: 40),

        // Card Artwork
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 360,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: rarityStyle.borderColor, width: 2.5),
                boxShadow: rarityStyle.glow,
              ),
              clipBehavior: Clip.antiAlias, // Critical for diagonal ribbon
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        card.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Image load error: ${card.imagePath}');
                          return const Center(
                            child: Icon(Icons.style_rounded, size: 80, color: Colors.white10),
                          );
                        },
                      ),
                    ),
                  ),
                  RewardRibbon(
                    isNew: reward.isNew,
                    duplicateTokenValue: reward.duplicateTokenValue,
                  ),
                ],
              ),
            ),
            if (rarityStyle.showSparkles) ...[
              Positioned(
                top: -10,
                right: -10,
                child: Icon(Icons.auto_awesome_rounded, color: rarityStyle.accentColor, size: 32),
              ),
              Positioned(
                bottom: 20,
                left: -15,
                child: Icon(Icons.auto_awesome_rounded, color: rarityStyle.accentColor, size: 24),
              ),
            ],
          ],
        ),
        const SizedBox(height: 32),
        // Info (Rarity text removed)
        Text(
          card.name,
          style: AppTypography.pageTitle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          card.setName,
          style: AppTypography.bodyMedium.copyWith(
            color: rarityStyle.accentColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 60),
        Text(
          "Devam etmek için dokun",
          style: AppTypography.labelSmall.copyWith(color: Colors.white24),
        ),
      ],
    );
  }

  Widget _buildCompletionView(String collectionId) {
    final album = albumSets.firstWhere((a) => a.id == collectionId);
    return Column(
      key: ValueKey('completion_$collectionId'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "KOLEKSİYON TAMAMLANDI!",
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primary,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        // Character Artwork
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: album.themeColor.withValues(alpha:0.1),
            border: Border.all(color: album.themeColor.withValues(alpha:0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: album.themeColor.withValues(alpha:0.2),
                blurRadius: 40,
                spreadRadius: 10,
              )
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              album.characterImagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Character Image load error: ${album.characterImagePath}');
                return const Center(
                  child: Icon(Icons.person_rounded, size: 100, color: Colors.white10),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          album.characterName,
          style: AppTypography.pageTitle.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 16),
        _buildBadge("ÖDÜL: ${album.rewardTokens} 🪙", AppColors.primary),
        const SizedBox(height: 60),
        Text(
          "Kütüphaneye eklemek için dokun",
          style: AppTypography.labelSmall.copyWith(color: Colors.white24),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
