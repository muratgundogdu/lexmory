import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/collection_pool.dart';
import '../../game/providers/game_provider.dart';
import '../models/collection_card.dart';
import '../models/collection_state.dart';

class CollectionNotifier extends StateNotifier<CollectionState> {
  final Ref ref;
  static const String _storageKey = 'lexmory_owned_cards';

  CollectionNotifier(this.ref) : super(CollectionState.initial()) {
    _loadFromDisk();
  }

  // 💾 Cihaz hafızasından sahip olunan kartları yükle
  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedCards = prefs.getStringList(_storageKey);
    if (savedCards != null) {
      state = state.copyWith(ownedCardIds: savedCards);
    }
  }

  // 💾 Kart listesini kalıcı olarak kaydet
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.ownedCardIds);
  }

  /// 🎁 RASTGELE KART ÖDÜLÜ VER (Günlük Görev veya Kategori Sonu Sandığı için)
  /// Bu metot bir [ChestResult] fırlatır, böylece UI'da oyuncuya ne çıktığını gösterebilirsin.
  Future<ChestResult> openRewardChest() async {
    if (collectionPool.isEmpty) {
      throw Exception("Kart havuzu boş!");
    }

    // 1. Havuzdan tamamen rastgele bir kart seç
    final random = Random();
    final CollectionCard rolledCard = collectionPool[random.nextInt(collectionPool.length)];

    final bool isDuplicate = state.ownedCardIds.contains(rolledCard.id);

    if (isDuplicate) {
      // 2. KOPYA DURUMU: Yıldız seviyesine göre iade miktarını hesapla
      int refundAmount = 50; // 1 Yıldız varsayılan
      if (rolledCard.stars == 2) refundAmount = 150;
      if (rolledCard.stars == 3) refundAmount = 400;

      // GameProvider'a tokenları ekle
      await ref.read(gameProvider.notifier).addTokens(refundAmount);

      return ChestResult(
        card: rolledCard,
        isDuplicate: true,
        refundTokens: refundAmount,
      );
    } else {
      // 3. YENİ KART DURUMU: Koleksiyona ekle ve diske yaz
      final updatedCards = [...state.ownedCardIds, rolledCard.id];
      state = state.copyWith(ownedCardIds: updatedCards);
      await _saveToDisk();

      return ChestResult(
        card: rolledCard,
        isDuplicate: false,
        refundTokens: 0,
      );
    }
  }

  /// 🛒 MARKET KART PAKETİ SATIN ALMA MEKANİZMASI
  /// Sabit bir paket ücreti (Örn: 500 Token) karşılığında sandık açar.
  Future<ChestResult?> buyCardPacket({int packetCost = 500}) async {
    final gameState = ref.read(gameProvider);

    // Ekonomi kontrolü
    if (gameState.tokens < packetCost) return null;

    // Önce parayı düş (spendTokens metodunun var olduğunu varsayıyoruz)
    await ref.read(gameProvider.notifier).spendTokens(packetCost);

    // Ardından sandığı aç ve ödülü ver
    return await openRewardChest();
  }
}

// UI bilgilendirmesi için yardımcı sınıf
class ChestResult {
  final CollectionCard card;
  final bool isDuplicate;
  final int refundTokens;

  ChestResult({
    required this.card,
    required this.isDuplicate,
    required this.refundTokens,
  });
}

// Global Provider Tanımı
final collectionProvider = StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  return CollectionNotifier(ref);
});