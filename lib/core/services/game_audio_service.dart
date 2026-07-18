import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameAudioServiceProvider = Provider((ref) => GameAudioService());

class GameAudioService {
  // Pre-created players for performance and low latency
  final AudioPlayer _wrongPlayer = AudioPlayer();
  final AudioPlayer _jokerPlayer = AudioPlayer();
  final AudioPlayer _transitionPlayer = AudioPlayer();
  final AudioPlayer _flipPlayer = AudioPlayer();

  GameAudioService() {
    _init();
  }

  Future<void> _init() async {
    AudioCache.instance.prefix = '';
    // Optional: Set low latency mode for UI sounds
    _wrongPlayer.setPlayerMode(PlayerMode.lowLatency);
    _jokerPlayer.setPlayerMode(PlayerMode.lowLatency);
    _transitionPlayer.setPlayerMode(PlayerMode.lowLatency);
    _flipPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  /// Oyuncu yanlış harf kutusuna bastığında (Volume: 0.45)
  Future<void> playWrongTap() async {
    await _safePlay(
      _wrongPlayer,
      'lib/assets/audio/sfx/wrong_tap.ogg',
      volume: 0.45,
    );
  }

  /// “3 Yanlışı Sil” jokeri çalıştırıldığında (Volume: 0.65)
  Future<void> playRemoveWrongJoker() async {
    await _safePlay(
      _jokerPlayer,
      'lib/assets/audio/sfx/joker_remove_wrong.ogg',
      volume: 0.65,
    );
  }

  /// “Buldum” butonu ve Tekrar jokerinde (Volume: 0.55)
  Future<void> playBoardTransition() async {
    await _safePlay(
      _transitionPlayer,
      'lib/assets/audio/sfx/board_hide.ogg',
      volume: 0.55,
    );
  }

  /// Doğru harf seçiminde (Volume: 0.60)
  Future<void> playCardFlip() async {
    await _safePlay(
      _flipPlayer,
      'lib/assets/audio/sfx/card_flip.ogg',
      volume: 0.60,
    );
  }

  /// Helper to play sounds safely and with low latency
  Future<void> _safePlay(AudioPlayer player, String path, {double volume = 1.0}) async {
    try {
      // Stop before playing again to allow rapid taps (reset to start)
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      
      await player.setVolume(volume);
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('GameAudioService Error playing $path: $e');
      // Oyunu durdurmamalı, sessizce devam et.
    }
  }

  void dispose() {
    _wrongPlayer.dispose();
    _jokerPlayer.dispose();
    _transitionPlayer.dispose();
    _flipPlayer.dispose();
  }
}
