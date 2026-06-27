import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/providers/game_provider.dart';
import '../provider/library_provider.dart';
import '../widgets/room_stage_reveal.dart';
import '../../../data/library_rooms.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  bool isUpgrading = false;
  String upgradeStatusText = "";
  int? _revealFromStage;

  late final AnimationController _revealController;

  // UI animasyonu için kullanılan aksiyon metinleri
  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _handleUpgrade(int currentStage) async {
    if (isUpgrading) return;

    final cost = ref.read(libraryProvider.notifier).getUpgradeCost(widget.roomId, currentStage);
    final gameState = ref.read(gameProvider);

    if (gameState.tokens < cost) return;

    // 1. DATA DOSYASINDAN ODA VERİSİNİ VE ADIM İSİMLERİNİ ALIYORUZ
    final roomData = libraryRooms.firstWhere((r) => r['id'] == widget.roomId);
    final List<String> stageTitles = List<String>.from(roomData['stageTitles']);

    // 2. SABİT LİSTE YERİNE DATA DOSYASINDAKİ İSMİ KONTROL EDİYORUZ
    final actionText = currentStage < stageTitles.length
        ? stageTitles[currentStage]
        : "Geliştiriliyor";

    setState(() {
      isUpgrading = true;
      upgradeStatusText = "$actionText...".toUpperCase();
    });

    HapticFeedback.mediumImpact();
    await Future.delayed(700.ms);
    if (!mounted) return;

    final int fromStage = currentStage;

    setState(() {
      _revealFromStage = fromStage;
      upgradeStatusText = "TAMAMLANDI!";
    });

    HapticFeedback.lightImpact();

    // 3. ANİMASYONU BAŞLATIYORUZ (Görsel efektler ekranda oynatılıyor)
    await _revealController.forward(from: 0);
    if (!mounted) return;

    // 4. ANİMASYON BİTTİKTEN SONRA STATE'İ GÜNCELLİYORUZ VE PARAYI DÜŞÜYORUZ
    // Böylece alt paneldeki yazılar ve maliyetler animasyon sırasında erkenden zıplamıyor.
    ref.read(libraryProvider.notifier).upgradeRoom(widget.roomId);

    setState(() {
      isUpgrading = false;
      _revealFromStage = null;
      upgradeStatusText = "";
    });
    _revealController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final libraryNotifier = ref.read(libraryProvider.notifier);
    final gameState = ref.watch(gameProvider);

    final roomData = libraryRooms.firstWhere((r) => r['id'] == widget.roomId);
    final int totalStages = roomData['totalStages'] as int;
    final int currentStageIndex = libraryState.roomStages[widget.roomId] ?? 0;
    final bool isMaxStage = currentStageIndex >= totalStages;

    int nextUpgradeCost = 0;
    bool canAfford = false;

    if (!isMaxStage) {
      nextUpgradeCost = libraryNotifier.getUpgradeCost(widget.roomId, currentStageIndex);
      canAfford = gameState.tokens >= nextUpgradeCost;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. TAM EKRAN ODA — önceki stage sabit, yeni öğe üzerine yerleşir
          Positioned.fill(
            child: RoomStageReveal(
              roomId: widget.roomId,
              stageIndex: currentStageIndex,
              revealFromStage: _revealFromStage,
              revealAnimation: _revealController,
              showSparkles: _revealFromStage != null,
            ),
          ),

          // 2. OKUNABİLİRLİK GRADIENTI
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

          // 3. ÜST PANEL
          Column(
            children: [
              _buildCompactHeader(roomData['name'] as String),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildRefinedProgress(currentStageIndex, totalStages),
              ),
            ],
          ),

          // 4. DOKUNULMAZ: ALT UPGRADE PANELİ
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

          // 5. UPGRADE EFEKTLERİ
          if (isUpgrading) _buildGlowOverlay(),
          if (isUpgrading) Center(child: _buildStatusPopup()),
        ],
      ),
    );
  }

  Widget _buildRefinedProgress(int current, int total) {
    double progress = (current / total).clamp(0.0, 1.0);
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
    // 1. DATA DOSYASINDAN BU ODANIN VERİLERİNİ VE ADIM İSİMLERİNİ ALIYORUZ
    final roomData = libraryRooms.firstWhere((r) => r['id'] == widget.roomId);
    final List<String> stageTitles = List<String>.from(roomData['stageTitles']);

    // 2. ESKİ LİSTE YERİNE DATA DOSYASINDAKİ LİSTEYE GÖRE KONTROL EDİYORUZ
    String nextStepTitle = (currentStage < stageTitles.length)
        ? stageTitles[currentStage]
        : "SON DOKUNUŞLAR";

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
            nextStepTitle.toUpperCase(),
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
          colors: [const Color(0xFFCEA14F).withOpacity(0.3), Colors.transparent],
        ),
      ),
    ).animate().fadeIn().fadeOut(delay: 700.ms),
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