// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Reklam paketi
import 'package:lexmory/features/game/view/splash_screen.dart';
import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'features/game/services/ad_service.dart';

// 1. Burayı Future<void> ve async olarak güncelle
void main() async {
  // 2. Flutter motorunun başlatıldığından emin ol
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 3. Reklam SDK'sını bekleyerek (await) başlat
  await MobileAds.instance.initialize();

  // 2. AdService'i hazırla ve ilk reklamı yükle
  final adService = AdService();
  adService.loadRewardedAd();

  // 4. Native Splash'i tut
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Oryantasyon ve sistem ayarları
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: LexmoryApp()));
}

class LexmoryApp extends StatelessWidget {
  const LexmoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexmory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}