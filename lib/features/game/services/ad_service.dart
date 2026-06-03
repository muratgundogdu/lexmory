import 'dart:async';

class AdService {
  // Gelecekte AdMob veya AppLovin entegrasyonu buraya gelecek
  Future<bool> showRewardedAd() async {
    // Reklam yükleme ve gösterme simülasyonu
    await Future.delayed(const Duration(seconds: 2));
    // Kullanıcı reklamı bitirdi mi?
    return true;
  }
}