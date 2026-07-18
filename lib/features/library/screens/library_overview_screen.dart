import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/library_main_view.dart';
import '../widgets/collection_view.dart';
import '../provider/library_navigation_provider.dart';

class LibraryOverviewScreen extends ConsumerStatefulWidget {
  const LibraryOverviewScreen({super.key});

  @override
  ConsumerState<LibraryOverviewScreen> createState() => _LibraryOverviewScreenState();
}

class _LibraryOverviewScreenState extends ConsumerState<LibraryOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = ref.read(libraryTabProvider);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newTab = _tabController.index;
        ref.read(libraryTabProvider.notifier).state = newTab;
        
        // If switching to the Library tab (0), request focus
        if (newTab == 0) {
          ref.read(libraryFocusRequestProvider.notifier).state = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for external changes to the tab provider (e.g. from completion flow)
    ref.listen<int>(libraryTabProvider, (prev, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    return Scaffold(
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
          controller: _tabController,
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          // 1. SEKME: Kütüphane listesi ve odalar
          LibraryMainView(),

          // 2. SEKME: Kart albümü grid görünümü
          CollectionView(),
        ],
      ),
    );
  }
}
