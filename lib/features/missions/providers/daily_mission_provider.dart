import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/daily_mission.dart';
import '../data/daily_missions_data.dart';

/// State of the daily missions system.
class DailyMissionState {
  final DateTime? firstOpenDate;
  final String? currentMissionDate;
  final List<DailyMissionProgress> missions;
  final int weeklyBookmarks;
  final int totalBookmarks;
  final Set<String> claimedMissionIds;
  // 🎯 YENİ: Toplanmış sandıkların eşik değerlerini tutan kalıcı hafıza seti (Örn: {7, 14})
  final Set<int> claimedChestValues;
  final bool isLoading;

  DailyMissionState({
    this.firstOpenDate,
    this.currentMissionDate,
    required this.missions,
    this.weeklyBookmarks = 0,
    this.totalBookmarks = 0,
    required this.claimedMissionIds,
    required this.claimedChestValues, // Artık zorunlu alan
    this.isLoading = true,
  });

  DailyMissionState copyWith({
    DateTime? firstOpenDate,
    String? currentMissionDate,
    List<DailyMissionProgress>? missions,
    int? weeklyBookmarks,
    int? totalBookmarks,
    Set<String>? claimedMissionIds,
    Set<int>? claimedChestValues,
    bool? isLoading,
  }) {
    return DailyMissionState(
      firstOpenDate: firstOpenDate ?? this.firstOpenDate,
      currentMissionDate: currentMissionDate ?? this.currentMissionDate,
      missions: missions ?? this.missions,
      weeklyBookmarks: weeklyBookmarks ?? this.weeklyBookmarks,
      totalBookmarks: totalBookmarks ?? this.totalBookmarks,
      claimedMissionIds: claimedMissionIds ?? this.claimedMissionIds,
      claimedChestValues: claimedChestValues ?? this.claimedChestValues,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get completedMissionCount =>
      missions.where((p) => p.isCompleted).length;

  int get claimedMissionCount => claimedMissionIds.length;

  bool get hasClaimableMission =>
      missions.any((p) => p.isCompleted && !claimedMissionIds.contains(p.mission.id));

  int get weeklyBookmarkTarget => 21;

  bool get bronzeChestReady => weeklyBookmarks >= 7 && !claimedChestValues.contains(7);
  bool get silverChestReady => weeklyBookmarks >= 14 && !claimedChestValues.contains(14);
  bool get goldChestReady => weeklyBookmarks >= 21 && !claimedChestValues.contains(21);
}

class DailyMissionNotifier extends StateNotifier<DailyMissionState> {
  DailyMissionNotifier()
      : super(
    DailyMissionState(
      missions: [],
      claimedMissionIds: {},
      claimedChestValues: {}, // Varsayılan boş
      isLoading: true,
    ),
  );

  late SharedPreferences _prefs;
  final String _firstOpenDateKey = 'firstOpenDate';
  final String _currentMissionDateKey = 'currentMissionDate';
  final String _missionsProgressKey = 'missionsProgress';
  final String _claimedMissionIdsKey = 'claimedMissionIds';
  final String _weeklyBookmarksKey = 'weeklyBookmarks';
  final String _totalBookmarksKey = 'totalBookmarks';
  // 🎯 YENİ: Sandık disk kayıt anahtarı
  final String _claimedChestValuesKey = 'claimedChestValues';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOrCreateDailyMissions();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadOrCreateDailyMissions() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final savedFirstOpenDateStr = _prefs.getString(_firstOpenDateKey);
    final savedCurrentMissionDate = _prefs.getString(_currentMissionDateKey);
    final savedMissionsJson = _prefs.getStringList(_missionsProgressKey);
    final savedClaimedMissionIds =
    _prefs.getStringList(_claimedMissionIdsKey)?.toSet();

    // 🎯 YENİ: Diskten toplanan sandık verilerini oku
    final savedClaimedChests = _prefs.getStringList(_claimedChestValuesKey)
        ?.map((e) => int.parse(e))
        .toSet() ?? {};

    final savedWeeklyBookmarks = _prefs.getInt(_weeklyBookmarksKey) ?? 0;
    final savedTotalBookmarks = _prefs.getInt(_totalBookmarksKey) ?? 0;

    DateTime? firstOpenDate = savedFirstOpenDateStr != null
        ? DateTime.parse(savedFirstOpenDateStr)
        : null;

    List<DailyMissionProgress> missions = [];
    if (savedMissionsJson != null) {
      try {
        missions = savedMissionsJson
            .map((jsonString) =>
            DailyMissionProgress.fromPool(json.decode(jsonString), dailyMissionPool))
            .toList();
      } catch (e) {
        missions = [];
      }
    }

    if (firstOpenDate == null) {
      firstOpenDate = DateTime.now();
      await _prefs.setString(_firstOpenDateKey, firstOpenDate.toIso8601String());
      await _selectAndSaveNewMissions(firstOpenDate, savedWeeklyBookmarks, savedClaimedChests);
    } else if (savedCurrentMissionDate != today) {
      await _selectAndSaveNewMissions(firstOpenDate, savedWeeklyBookmarks, savedClaimedChests);
    } else {
      state = state.copyWith(
        firstOpenDate: firstOpenDate,
        currentMissionDate: savedCurrentMissionDate,
        missions: missions,
        claimedMissionIds: savedClaimedMissionIds ?? {},
        claimedChestValues: savedClaimedChests,
        weeklyBookmarks: savedWeeklyBookmarks,
        totalBookmarks: savedTotalBookmarks,
      );
    }
  }

  Future<void> _selectAndSaveNewMissions(
      DateTime firstOpenDate, int currentWeeklyBookmarks, Set<int> currentClaimedChests) async {
    final now = DateTime.now();
    final dayIndex = now.difference(DateTime(firstOpenDate.year, firstOpenDate.month, firstOpenDate.day)).inDays + 1;

    // 🎯 HAFTALIK SIFIRLAMA KONTROLÜ: Eğer yeni bir haftaya girildiyse (Pazartesi veya 7 gün döngüsü)
    // Haftalık ilerleme ve toplanan sandıklar sıfırlanır
    int weeklyBookmarks = currentWeeklyBookmarks;
    Set<int> claimedChests = currentClaimedChests;

    // Basit mantık: onboarding bitip yeni haftaya geçildiğinde veya dayIndex 7'ye tam bölündüğünde sıfırla
    if (dayIndex % 7 == 1 && dayIndex > 1) {
      weeklyBookmarks = 0;
      claimedChests = {};
    }

    final newMissions = _selectTodayMissions(dayIndex);
    final newMissionProgressList = newMissions
        .map((mission) => DailyMissionProgress(mission: mission))
        .toList();

    state = state.copyWith(
      firstOpenDate: firstOpenDate,
      currentMissionDate: DateFormat('yyyy-MM-dd').format(now),
      missions: newMissionProgressList,
      claimedMissionIds: {},
      claimedChestValues: claimedChests,
      weeklyBookmarks: weeklyBookmarks,
      isLoading: false,
    );
    await saveState();
  }

  List<DailyMission> _selectTodayMissions(int dayIndex) {
    List<DailyMission> selectedMissions = [];
    final _random = Random();

    if (dayIndex <= 7) {
      final missionIdsForDay = onboardingDailyMissionIds[dayIndex] ?? [];
      for (var id in missionIdsForDay) {
        final found = dailyMissionPool.firstWhere((m) => m.id == id);
        selectedMissions.add(found);
      }
    } else {
      // 🎯 7. GÜNDEN SONRA: TİP ÇAKIŞMASINI ENGELLEYEN AKILLI SEÇİM ALGORİTMASI
      final Set<DailyMissionType> chosenTypes = {};

      // 1. Ana havuzları zorluklarına göre filtrele
      final easyPool = dailyMissionPool
          .where((m) => m.difficulty == DailyMissionDifficulty.easy)
          .toList();
      final mediumPool = dailyMissionPool
          .where((m) => m.difficulty == DailyMissionDifficulty.medium)
          .toList();
      final hardPool = dailyMissionPool
          .where((m) => m.difficulty == DailyMissionDifficulty.hard)
          .toList();

      // --- Kural 1: KOLAY GÖREV SEÇİMİ ---
      if (easyPool.isNotEmpty) {
        final easyMission = easyPool[_random.nextInt(easyPool.length)];
        selectedMissions.add(easyMission);
        chosenTypes.add(easyMission.type); // Kolay görevin tipini cebe koyduk
      }

      // --- Kural 2: ORTA GÖREV SEÇİMİ (Farklı Tipte) ---
      // Kolay görevin tipiyle eşleşmeyen orta zorluktaki görevleri filtrele
      List<DailyMission> validMediumPool = mediumPool
          .where((m) => !chosenTypes.contains(m.type))
          .toList();

      // Güvenlik Önlemi: Eğer havuzda görev kalmazsa orijinal orta havuzuna geri dön
      if (validMediumPool.isEmpty) validMediumPool = mediumPool;

      final mediumMission = validMediumPool[_random.nextInt(validMediumPool.length)];
      selectedMissions.add(mediumMission);
      chosenTypes.add(mediumMission.type); // Orta görevin tipini de kaydettik

      // --- Kural 3: ZOR GÖREV SEÇİMİ (Kolay ve Ortadan Tamamen Farklı Tipte) ---
      // Hem kolay hem orta görev tipiyle eşleşmeyen zor görevleri filtrele
      List<DailyMission> validHardPool = hardPool
          .where((m) => !chosenTypes.contains(m.type))
          .toList();

      if (validHardPool.isEmpty) validHardPool = hardPool;

      final hardMission = validHardPool[_random.nextInt(validHardPool.length)];
      selectedMissions.add(hardMission);
    }

    return selectedMissions;
  }

  Future<void> saveState() async {
    await _prefs.setString(
        _currentMissionDateKey, state.currentMissionDate ?? '');
    await _prefs.setStringList(
      _missionsProgressKey,
      state.missions.map((p) => json.encode(p.toJson())).toList(),
    );
    await _prefs.setStringList(
        _claimedMissionIdsKey, state.claimedMissionIds.toList());

    // 🎯 YENİ: Sandık durumlarını diskte String listesi olarak sakla
    await _prefs.setStringList(
        _claimedChestValuesKey, state.claimedChestValues.map((e) => e.toString()).toList());

    await _prefs.setInt(_weeklyBookmarksKey, state.weeklyBookmarks);
    await _prefs.setInt(_totalBookmarksKey, state.totalBookmarks);
  }

  Future<void> resetForNewDayIfNeeded() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (state.currentMissionDate != today) {
      await _loadOrCreateDailyMissions();
    }
  }

  DailyMission? findMissionById(String id) {
    try {
      return dailyMissionPool.firstWhere((mission) => mission.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProgress(
      DailyMissionType type, {
        int amount = 1,
      }) async {
    final updatedMissions = state.missions.map((missionProgress) {
      if (missionProgress.mission.type == type &&
          !state.claimedMissionIds.contains(missionProgress.mission.id) &&
          !missionProgress.isClaimed) {

        int newProgress;

        // 🎯 1. SEÇENEK: SERİ YAKALAMA GÖREVİ ÖZEL MANTIĞI
        if (type == DailyMissionType.reachStreak) {
          if (amount == -1) {
            // 🚨 Oyuncu yandı/seriyi bozdu! Görev sayacını sıfıra çekiyoruz.
            // (Ana streak sistemine dokunulmaz, sadece bu görevin bugünkü sayacı sıfırlanır)
            newProgress = 0;
          } else {
            // Oyuncu o gün içinde başarılı bir adım daha attı, görevin kendi iç sayacını +1 artır.
            newProgress = missionProgress.currentProgress + amount;
          }
        } else {
          // 🎯 DİĞER GÖREVLER: (Kelime çözme, reklam izleme vb.) normal şekilde üstüne eklenerek artar.
          newProgress = missionProgress.currentProgress + amount;
        }

        return missionProgress.copyWith(
          currentProgress: min(
            max(0, newProgress), // Negatif değer almasını engellemek için koruma
            missionProgress.mission.target,
          ),
        );
      }
      return missionProgress;
    }).toList();

    state = state.copyWith(missions: updatedMissions);
    await saveState();
  }

  Future<void> updateMaxProgress(DailyMissionType type, int value) async {
    final updatedMissions = state.missions.map((missionProgress) {
      if (missionProgress.mission.type == type &&
          !state.claimedMissionIds.contains(missionProgress.mission.id) &&
          !missionProgress.isClaimed) {
        return missionProgress.copyWith(
          currentProgress: min(
            max(missionProgress.currentProgress, value),
            missionProgress.mission.target,
          ),
        );
      }
      return missionProgress;
    }).toList();

    state = state.copyWith(missions: updatedMissions);
    await saveState();
  }

  Future<bool> claimMission(String missionId) async {
    final missionIndex = state.missions.indexWhere((p) => p.mission.id == missionId);
    if (missionIndex == -1) return false;

    final missionProgress = state.missions[missionIndex];

    if (!missionProgress.isCompleted ||
        missionProgress.isClaimed ||
        state.claimedMissionIds.contains(missionId)) {
      return false;
    }

    final updatedMissions = List<DailyMissionProgress>.from(state.missions);
    updatedMissions[missionIndex] = missionProgress.copyWith(isClaimed: true);

    final newClaimedMissionIds = Set<String>.from(state.claimedMissionIds)
      ..add(missionId);
    final newWeeklyBookmarks =
        state.weeklyBookmarks + missionProgress.mission.rewardBookmarks;
    final newTotalBookmarks =
        state.totalBookmarks + missionProgress.mission.rewardBookmarks;

    state = state.copyWith(
      missions: updatedMissions,
      claimedMissionIds: newClaimedMissionIds,
      weeklyBookmarks: newWeeklyBookmarks,
      totalBookmarks: newTotalBookmarks,
    );

    await saveState();
    return true;
  }

  // =========================================================================
  // 🎯 YENİ: PREMIUM HAFTALIK SANDIK ÖDÜL KİLİTLEME METODU (BUG KORUMALI)
  // =========================================================================
  Future<bool> claimWeeklyChest(int chestValue) async {
    // 1. Oyuncu gerekli ayraç eşiğine ulaşmış mı?
    if (state.weeklyBookmarks < chestValue) return false;

    // 2. Bu sandık daha önce toplanmış mı? (Double-claim koruması)
    if (state.claimedChestValues.contains(chestValue)) return false;

    // 3. State'i güncelle ve sandığı toplananlar listesine kilitle
    final newClaimedChests = Set<int>.from(state.claimedChestValues)..add(chestValue);

    state = state.copyWith(
      claimedChestValues: newClaimedChests,
    );

    // 4. Diske kalıcı olarak kaydet
    await saveState();
    return true;
  }
}

final dailyMissionProvider =
StateNotifierProvider<DailyMissionNotifier, DailyMissionState>((ref) {
  return DailyMissionNotifier()..init();
});