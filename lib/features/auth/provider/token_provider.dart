import 'package:flutter_riverpod/flutter_riverpod.dart';

// Başlangıç parası 300 olan basit bir token sağlayıcı
final tokenProvider = StateProvider<int>((ref) => 300);