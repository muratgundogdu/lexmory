import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/providers/game_provider.dart';
import '../provider/library_provider.dart';
import '../../../data/library_rooms.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  bool isUpgrading = false;
  String upgradeStatusText = "";

  final List<String> stageActionNames = [
    "Zemin Hazırlanıyor",
    "Raflar Montajlanıyor",
    "Kitaplar Yerleştiriliyor",
    "Çalışma Masası Kuruluyor",
    "Aydınlatmalar Takılıyor",
    "Halı Seriliyor",
    "Bitkiler Yerleştiriliyor",
    "Dekorasyon Tamamlanıyor",
  ];

  Future<void> _handleUpgrade(int currentStage) async {
    if (isUpgrading) return;

    // 1. Maliyeti ve Bakiyeyi Kontrol Et
    final cost = ref.read(libraryProvider.notifier).getUpgradeCost(widget.roomId, currentStage);
    final gameState = ref.read(gameProvider);

    if (gameState.tokens < cost) return;

    // 2. Animasyonu Başlat
    setState(() {
      isUpgrading = true;
      upgradeStatusText = "SIRA SENDE!";
    });

    HapticFeedback.mediumImpact();
    await Future.delayed(800.ms);

    // 3. Provider Üzerinden Geliştirmeyi Yap (Token düşme ve Stage artırma bu metodun içinde)
    // LibraryNotifier içindeki upgradeRoom artık SharedPreferences kaydı da yapıyor.
    ref.read(libraryProvider.notifier).upgradeRoom(widget.roomId);

    HapticFeedback.lightImpact();
    setState(() => upgradeStatusText = "SIRA SENDE!");

    await Future.delayed(700.ms);
    if (!mounted) return;

    setState(() {
      isUpgrading = false;
      upgradeStatusText = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    // Stage bilgisini LibraryProvider'dan izle (watch)
    final libraryState = ref.watch(libraryProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);

    // Token bilgisini ana GameProvider'dan izle (watch)
    final gameState = ref.watch(gameProvider);
    final int playerTokens = gameState.tokens;

    // Mevcut odanın verilerini ve stage bilgisini al
    final roomData = libraryRooms.firstWhere((r) => r['id'] == widget.roomId);
    final int currentStageIndex = libraryState.roomStages[widget.roomId] ?? 0;
    final bool isMaxStage = currentStageIndex >= 7;

    int nextUpgradeCost = 0;
    bool canAfford = false;

    if (!isMaxStage) {
      nextUpgradeCost = libraryNotifier.getUpgradeCost(widget.roomId, currentStageIndex);
      // Bakiye kontrolü - >= operatörü ile tam tutar kontrolü
      canAfford = playerTokens >= nextUpgradeCost;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. ARKA PLAN: TAM EKRAN ODA GÖRSELİ
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.05, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'lib/assets/library/${widget.roomId}/room_stage_$currentStageIndex.png',
                key: ValueKey('room_img_$currentStageIndex'),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // 2. GÖRSEL ÜZERİ KARARTMA (Okunabilirlik için)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. ÜST BİLGİ (Kategori adı ve Progress)
          Column(
            children: [
              _buildCompactHeader(roomData['name'] as String),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildRefinedProgress(currentStageIndex, 7),
              ),
            ],
          ),

          // 4. ALT PANEL (Upgrade Kartı)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: isMaxStage
                    ? _buildCompletedArea()
                    : _buildUpgradePanel(currentStageIndex, canAfford, nextUpgradeCost),
              ),
            ),
          ),

          // 5. UPGRADE EFEKTLERİ (Glow ve Status Popup)
          if (isUpgrading) _buildGlowOverlay(),
          if (isUpgrading) Center(child: _buildStatusPopup()),
        ],
      ),
    );
  }

  Widget _buildRefinedProgress(int current, int total) {
    double progress = current / total;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ODA GELİŞİMİ",
                style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
            Text("%${(progress * 100).toInt()}",
                style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 6,
            color: Colors.white10,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: 1.seconds,
                  width: (MediaQuery.of(context).size.width - 48) * progress,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFD4A574), Color(0xFFF2C078)]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradePanel(int currentStage, bool canAfford, int cost) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("SIRADAKİ ADIM",
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(
            stageActionNames[currentStage + 1].toUpperCase(),
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildUpgradeButton(currentStage, canAfford, cost),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(int currentStage, bool canAfford, int cost) {
    final bool isButtonDisabled = !canAfford || isUpgrading;
    return Opacity(
      opacity: isButtonDisabled ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: isButtonDisabled ? null : () => _handleUpgrade(currentStage),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: canAfford
                ? const LinearGradient(colors: [Color(0xFFD4A574), Color(0xFFF2C078)])
                : LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade900]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isUpgrading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(canAfford ? "GELİŞTİR" : "YETERSİZ TOKEN",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: canAfford ? Colors.black : Colors.white24)),
                const SizedBox(width: 10),
                Text("🪙 $cost", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: canAfford ? Colors.black : Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(String title) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            Text(title.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPopup() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4A574), width: 1.5),
      ),
      child: Text(
        upgradeStatusText.toUpperCase(),
        style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
      ),
    ).animate().scale(curve: Curves.easeOutBack).fadeIn();
  }

  Widget _buildGlowOverlay() => IgnorePointer(
    child: Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            const Color(0xFFCEA14F).withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    ).animate().fadeIn().fadeOut(delay: 800.ms),
  );

  Widget _buildCompletedArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4A574).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFF2C078), size: 32).animate(onPlay: (c) => c.repeat()).shimmer(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ODA TAMAMLANDI", style: GoogleFonts.outfit(color: const Color(0xFFF2C078), fontWeight: FontWeight.bold, fontSize: 12)),
                Text("Kütüphanenizin bu parçası artık hazır.", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}