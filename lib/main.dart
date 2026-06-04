import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lexmory/features/game/view/splash_screen.dart';

import 'core/app_theme.dart';
import 'core/app_colors.dart';

void main() {
  // 2. Binding'i bir değişkene ata (Native splash için zorunlu)
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 3. Flutter hazır olana kadar native splash ekranını tut
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Oryantasyon ayarı
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Sistem arayüz ayarları
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
      // Uygulama senin yazdığın SplashScreen ile başlar
      home: const SplashScreen(),
    );
  }
}