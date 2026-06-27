import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/library_main_view.dart';
import '../widgets/collection_view.dart';

class LibraryOverviewScreen extends ConsumerWidget {
  const LibraryOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2, // Kütüphanem ve Koleksiyon
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F10),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F10),
          elevation: 0,
          title: Text(
            "LEXMORY ARŞİVİ",
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          // SEKMELERİN TASARIMI
          bottom: TabBar(
            indicatorColor: const Color(0xFFF2C078),
            labelColor: const Color(0xFFF2C078),
            unselectedLabelColor: Colors.white38,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            tabs: const [
              Tab(
                  text: "KÜTÜPHANEM",
                  icon: Icon(Icons.account_balance_rounded, size: 20)
              ),
              Tab(
                  text: "KOLEKSİYON",
                  icon: Icon(Icons.style_rounded, size: 20)
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. SEKME: Kütüphane listesi ve odalar
            LibraryMainView(),

            // 2. SEKME: Kart albümü grid görünümü
            CollectionView(),
          ],
        ),
      ),
    );
  }
}