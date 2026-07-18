import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/collection_card.dart';
import '../provider/collection_provider.dart';
import 'collection_placement_transition.dart';

class PureImageCard extends ConsumerStatefulWidget {
  final CollectionCard card;
  final bool isOwned;
  final bool isMistikMode;
  final bool isNewlyUnlocked;
  final Duration staggerDelay;

  const PureImageCard({
    super.key,
    required this.card,
    required this.isOwned,
    this.isMistikMode = false,
    this.isNewlyUnlocked = false,
    this.staggerDelay = Duration.zero,
  });

  @override
  ConsumerState<PureImageCard> createState() => _PureImageCardState();
}

class _PureImageCardState extends ConsumerState<PureImageCard> {
  static _CardThemeColors get _lockedTheme => _CardThemeColors(
        borderColor: Colors.white.withValues(alpha: 0.08),
        glowColor: Colors.transparent,
        bgGlowColor: Colors.white.withValues(alpha: 0.03),
      );

  static _CardThemeColors get _legendaryTheme => _CardThemeColors(
        borderColor: const Color(0xFFFFD275),
        glowColor: const Color(0xFFFFD275).withValues(alpha: 0.22),
        bgGlowColor: const Color(0xFFFFD275).withValues(alpha: 0.14),
      );

  static _CardThemeColors get _epicTheme => _CardThemeColors(
        borderColor: const Color(0xFF9D85FF),
        glowColor: const Color(0xFF9D85FF).withValues(alpha: 0.2),
        bgGlowColor: const Color(0xFF4C3BA8).withValues(alpha: 0.25),
      );

  static _CardThemeColors get _commonTheme => _CardThemeColors(
        borderColor: const Color(0xFFCD7F32).withValues(alpha: 0.7),
        glowColor: Colors.black26,
        bgGlowColor: Colors.black45,
      );

  _CardThemeColors _getCardTheme(int stars, bool owned, bool mistik) {
    if (!owned) return _lockedTheme;
    
    _CardThemeColors theme;
    if (stars == 3) {
      theme = _legendaryTheme;
    } else if (stars == 2) {
      theme = _epicTheme;
    } else {
      theme = _commonTheme;
    }

    if (mistik) {
      return _CardThemeColors(
        borderColor: theme.borderColor,
        glowColor: theme.glowColor.withValues(alpha: theme.glowColor.a * 1.5),
        bgGlowColor: theme.bgGlowColor,
      );
    }
    return theme;
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = _getCardTheme(widget.card.stars, widget.isOwned, widget.isMistikMode);

    // Common Base for Slot/Background
    final slotBase = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isOwned ? cardTheme.borderColor : _lockedTheme.borderColor,
          width: widget.isOwned ? 2.0 : 1.0,
        ),
      ),
    );

    // Owned Content (The full card as it looks now)
    final ownedContent = _buildFullCard(isLocked: false, cardTheme: cardTheme);

    // Locked Content (The grayed out card)
    final lockedContent = _buildFullCard(isLocked: true, cardTheme: _lockedTheme);

    // If it's already owned and NOT newly unlocked, just show ownedContent
    if (widget.isOwned && !widget.isNewlyUnlocked) {
      return AspectRatio(aspectRatio: 0.72, child: ownedContent);
    }

    // If it's NOT owned, just show lockedContent
    if (!widget.isOwned) {
      return AspectRatio(aspectRatio: 0.72, child: lockedContent);
    }

    // Incoming Artwork (Just the image for animation)
    final incomingArtwork = Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
      child: Image.asset(
        widget.card.imagePath,
        fit: BoxFit.contain,
      ),
    );

    return AspectRatio(
      aspectRatio: 0.72,
      child: CollectionPlacementTransition(
        slot: slotBase,
        lockedContent: lockedContent,
        ownedContent: ownedContent,
        incomingArtwork: incomingArtwork,
        shouldAnimate: widget.isNewlyUnlocked,
        staggerDelay: widget.staggerDelay,
        onCompleted: () {
          if (mounted) {
            ref.read(collectionProvider.notifier).markCardAsSeen(widget.card.id);
          }
        },
      ),
    );
  }

  Widget _buildFullCard({required bool isLocked, required _CardThemeColors cardTheme}) {
    final Color dynamicTextColor = isLocked ? Colors.white38 : Colors.white;
    final FontWeight dynamicFontWeight = isLocked ? FontWeight.w500 : FontWeight.bold;
    final Color dynamicStarColor = isLocked ? Colors.white24 : const Color(0xFFFFD275);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cardTheme.borderColor,
          width: isLocked ? 1.0 : 2.0,
        ),
        boxShadow: !isLocked
            ? [
                BoxShadow(
                  color: cardTheme.glowColor,
                  blurRadius: 14.0,
                  spreadRadius: 1.0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. KATMAN: İç Çerçeve
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF3F3F46), width: 0.5),
              ),
            ),
          ),

          // 2. KATMAN: Arka Plan Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardTheme.bgGlowColor.withValues(alpha: 0.1),
                    const Color(0xFF101012),
                  ],
                ),
              ),
            ),
          ),

          // 3. KATMAN: Esas Görsel
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
              child: _buildCardImage(isLocked),
            ),
          ),

          // 4. KATMAN: Kart İsmi
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                ),
              ),
              child: Text(
                isLocked ? '???' : widget.card.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: dynamicTextColor,
                  fontSize: 11,
                  fontWeight: dynamicFontWeight,
                ),
              ),
            ),
          ),

          // 5. KATMAN: Yıldızlar
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  widget.card.stars,
                  (index) => Icon(Icons.star_rounded, size: 10, color: dynamicStarColor),
                ).expand((w) => [w, const SizedBox(width: 1)]).toList()..removeLast(),
              ),
            ),
          ),

          // 6. KATMAN: Kilit İkonu
          if (isLocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white54,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardImage(bool isLocked) {
    Widget image = !isLocked
        ? Image.asset(
            widget.card.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white24),
            ),
          )
        : Image.asset(
            'lib/assets/cards/locked_card_placeholder.webp',
            fit: BoxFit.contain,
          );

    if (isLocked) {
      return Opacity(
        opacity: 0.30,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.6, 0, 0, 0, 0,
            0, 0.6, 0, 0, 0,
            0, 0, 0.6, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: image,
        ),
      );
    }

    return image;
  }
}

class _CardThemeColors {
  final Color borderColor;
  final Color glowColor;
  final Color bgGlowColor;

  const _CardThemeColors({
    required this.borderColor,
    required this.glowColor,
    required this.bgGlowColor,
  });
}
