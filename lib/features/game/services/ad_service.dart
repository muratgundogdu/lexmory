import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  RewardedAd? _rewardedAd;

  // Test ID'leri (Yayına çıkarken gerçek ID'lerle değişecek)
  /*final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3378948179203260/4166967567' // Android Test Rewarded ID
      : 'ca-app-pub-3378948179203260/3637014754'; // iOS Test Rewarded ID*/

  // Google hesabı onaylanmadığı için google test ID'leri kullanıldı
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917' // Android Test Rewarded ID
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded ID

  /// Reklamı arka planda önceden yükler
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          print('Reklam yüklenemedi: $error');
        },
      ),
    );
  }

  /// Reklamı gösterir ve sonuç döner
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      loadRewardedAd(); // Reklam yoksa yüklemeye çalış
      return false;
    }

    bool earnedReward = false;
    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd(); // Bir sonraki kullanım için yeni reklam yükle
        completer.complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
        completer.complete(false);
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      earnedReward = true; // Kullanıcı reklamı izledi, ödülü hak etti
    });

    return completer.future;
  }
}