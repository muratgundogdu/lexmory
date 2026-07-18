// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lexmory/features/game/view/splash_screen.dart';
import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'features/game/services/ad_service.dart';

// --- DEBUG NAVIGATION OBSERVER ---
class DebugNavObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('NAV: Pushing ${route.settings.name ?? route.runtimeType} | State: ${route.isActive}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint('NAV: Popping ${route.settings.name ?? route.runtimeType} | State: ${route.isActive}');
    debugPrint('NAV: Returning to ${previousRoute?.settings.name ?? previousRoute?.runtimeType}');
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  final adService = AdService();
  adService.loadRewardedAd();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
      navigatorObservers: [DebugNavObserver()],
    );
  }
}
