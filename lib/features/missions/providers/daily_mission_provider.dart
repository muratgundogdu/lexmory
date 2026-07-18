import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexmory/features/library/models/chest_reward_source.dart';
import 'package:lexmory/features/library/models/reward_presentation_event.dart';
import 'package:lexmory/features/library/provider/collection_provider.dart';
import 'package:lexmory/features/library/provider/reward_queue_provider.dart';
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
  final Set<int> claimedChestValues;
  final String? lastClaimedDailyChestDate;
  final bool isLoading;

  DailyMissionState({
    this.firstOpenDate,
    this.currentMissionDate,
    required this.missions,
    this.weeklyBookmarks = 0,
    this.totalBookmarks = 0,
    required this.claimedMissionIds,
    required this.claimedChestValues,
    this.lastClaimedDailyChestDate,
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
    String? lastClaimedDailyChestDate,
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
      lastClaimedDailyChestDate: lastClaimedDailyChestDate ?? this.lastClaimedDailyChestDate,
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

  bool get allMissionsClaimed => missions.isNotEmpty && missions.every((m) => claimedMissionIds.contains(m.mission.id));
}

class DailyMissionNotifier extends StateNotifier<DailyMissionState> {
  final Ref _ref;

  DailyMissionNotifier(this._ref)
      : super(
    DailyMissionState(
      missions: [],
      claimedMissionIds: {},
      claimedChestValues: {}, 
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
  final String _claimedChestValuesKey = 'claimedChestValues';
  final String _lastClaimedDailyChestDateKey = 'lastClaimedDailyChestDate';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOrCreateDailyMissions();
    if (!mounted) return;
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadOrCreateDailyMissions() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final savedFirstOpenDateStr = _prefs.getString(_firstOpenDateKey);
    final savedCurrentMissionDate = _prefs.getString(_currentMissionDateKey);
    final savedMissionsJson = _prefs.getStringList(_missionsProgressKey);
    final savedClaimedMissionIds =
    _prefs.getStringList(_claimedMissionIdsKey)?.toSet();

    final savedClaimedChests = _prefs.getStringList(_claimedChestValuesKey)
        ?.map((e) => int.parse(e))
        .toSet() ?? {};

    final savedWeeklyBookmarks = _prefs.getInt(_weeklyBookmarksKey) ?? 0;
    final savedTotalBookmarks = _prefs.getInt(_totalBookmarksKey) ?? 0;
    final savedLastClaimedDailyChestDate = _prefs.getString(_lastClaimedDailyChestDateKey);
    final String? lastClaimedDate = (savedLastClaimedDailyChestDate != null && savedLastClaimedDailyChestDate.isNotEmpty) 
        ? savedLastClaimedDailyChestDate : null;

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
      await _selectAndSaveNewMissions(firstOpenDate, savedWeeklyBookmarks, savedClaimedChests, shouldResetWeekly: false);
    } else if (savedCurrentMissionDate != today) {
      final bool isResetRequired = _isNewCalendarWeek(savedCurrentMissionDate, DateTime.now());
      await _selectAndSaveNewMissions(firstOpenDate, savedWeeklyBookmarks, savedClaimedChests, shouldResetWeekly: isResetRequired);
    } else {
      if (!mounted) return;
      state = state.copyWith(
        firstOpenDate: firstOpenDate,
        currentMissionDate: savedCurrentMissionDate,
        missions: missions,
        claimedMissionIds: savedClaimedMissionIds ?? {},
        claimedChestValues: savedClaimedChests,
        weeklyBookmarks: savedWeeklyBookmarks,
        totalBookmarks: savedTotalBookmarks,
        lastClaimedDailyChestDate: lastClaimedDate,
      );
    }
  }

  Future<void> _selectAndSaveNewMissions(
      DateTime firstOpenDate, int currentWeeklyBookmarks, Set<int> currentClaimedChests, {required bool shouldResetWeekly}) async {
    final now = DateTime.now();
    final dayIndex = now.difference(DateTime(firstOpenDate.year, firstOpenDate.month, firstOpenDate.day)).inDays + 1;

    int weeklyBookmarks = currentWeeklyBookmarks;
    Set<int> claimedChests = currentClaimedChests;

    if (shouldResetWeekly) {
      weeklyBookmarks = 0;
      claimedChests = {};
    }

    final newMissions = _selectTodayMissions(dayIndex);
    final newMissionProgressList = newMissions
        .map((mission) => DailyMissionProgress(mission: mission))
        .toList();

    if (!mounted) return;
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
    final random = Random();

    if (dayIndex <= 7) {
      final missionIdsForDay = onboardingDailyMissionIds[dayIndex] ?? [];
      for (var id in missionIdsForDay) {
        final found = dailyMissionPool.firstWhere((m) => m.id == id);
        selectedMissions.add(found);
      }
    } else {
      final Set<DailyMissionType> chosenTypes = {};

      final easyPool = dailyMissionPool
          .where((m) => m.difficulty == DailyMissionDifficulty.easy)
          .toList();
      final mediumPool = dailyMissionPool
          .where((m) => m.difficulty == DailyMissionDifficulty.medium)
          .toList();
      final hardPool = dailyMissionPool
          .where((m) => m.difficulty == DailyMissionDifficulty.hard)
          .toList();

      if (easyPool.isNotEmpty) {
        final easyMission = easyPool[random.nextInt(easyPool.length)];
        selectedMissions.add(easyMission);
        chosenTypes.add(easyMission.type);
      }

      List<DailyMission> validMediumPool = mediumPool
          .where((m) => !chosenTypes.contains(m.type))
          .toList();

      if (validMediumPool.isEmpty) validMediumPool = mediumPool;

      final mediumMission = validMediumPool[random.nextInt(validMediumPool.length)];
      selectedMissions.add(mediumMission);
      chosenTypes.add(mediumMission.type);

      List<DailyMission> validHardPool = hardPool
          .where((m) => !chosenTypes.contains(m.type))
          .toList();

      if (validHardPool.isEmpty) validHardPool = hardPool;

      final hardMission = validHardPool[random.nextInt(validHardPool.length)];
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

    await _prefs.setStringList(
        _claimedChestValuesKey, state.claimedChestValues.map((e) => e.toString()).toList());

    await _prefs.setInt(_weeklyBookmarksKey, state.weeklyBookmarks);
    await _prefs.setInt(_totalBookmarksKey, state.totalBookmarks);
    await _prefs.setString(_lastClaimedDailyChestDateKey, state.lastClaimedDailyChestDate ?? '');
  }

  Future<void> resetForNewDayIfNeeded() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (state.currentMissionDate != today) {
      await _loadOrCreateDailyMissions();
    }
  }

  bool _isNewCalendarWeek(String? lastDateStr, DateTime now) {
    if (lastDateStr == null || lastDateStr.isEmpty) return false;
    try {
      final lastDate = DateFormat('yyyy-MM-dd').parse(lastDateStr);
      
      // Find the Monday of each date's week
      final lastMonday = DateTime(lastDate.year, lastDate.month, lastDate.day).subtract(Duration(days: lastDate.weekday - 1));
      final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      
      return currentMonday.isAfter(lastMonday);
    } catch (e) {
      return false;
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

        if (type == DailyMissionType.reachStreak) {
          if (amount == -1) {
            newProgress = 0;
          } else {
            newProgress = missionProgress.currentProgress + amount;
          }
        } else {
          newProgress = missionProgress.currentProgress + amount;
        }

        return missionProgress.copyWith(
          currentProgress: min(
            max(0, newProgress),
            missionProgress.mission.target,
          ),
        );
      }
      return missionProgress;
    }).toList();

    if (!mounted) return;
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

    if (!mounted) return;
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

    if (!mounted) return true;
    state = state.copyWith(
      missions: updatedMissions,
      claimedMissionIds: newClaimedMissionIds,
      weeklyBookmarks: newWeeklyBookmarks,
      totalBookmarks: newTotalBookmarks,
    );

    await saveState();

    // 🎯 Check if all daily missions are now claimed for the Silver Chest
    if (state.allMissionsClaimed) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (state.lastClaimedDailyChestDate != today) {
        try {
          final result = await _ref.read(collectionProvider.notifier).openChestReward(ChestRewardSource.dailyMission);
          
          if (!mounted) return true;
          _ref.read(rewardQueueProvider.notifier).enqueue(RewardPresentationEvent(
            id: 'daily_${DateTime.now().millisecondsSinceEpoch}',
            source: ChestRewardSource.dailyMission,
            result: result,
            createdAt: DateTime.now(),
            title: 'Günlük Görev Tamamlandı!',
          ));

          state = state.copyWith(lastClaimedDailyChestDate: today);
          await saveState();
        } catch (e) {
          debugPrint('Failed to open daily chest reward: $e');
        }
      }
    }

    return true;
  }

  Future<bool> claimWeeklyChest(int chestValue) async {
    if (state.weeklyBookmarks < chestValue) return false;

    if (state.claimedChestValues.contains(chestValue)) return false;

    final newClaimedChests = Set<int>.from(state.claimedChestValues)..add(chestValue);

    if (!mounted) return true;
    state = state.copyWith(
      claimedChestValues: newClaimedChests,
    );

    await saveState();

    // 🎯 Check weekly milestones for chests
    String? chestTypeId;
    String? milestoneTitle;
    
    if (chestValue == 7) {
      chestTypeId = 'wooden_chest';
      milestoneTitle = 'Bronz Hedef Tamamlandı!';
    } else if (chestValue == 14) {
      chestTypeId = 'silver_chest';
      milestoneTitle = 'Gümüş Hedef Tamamlandı!';
    } else if (chestValue == 21) {
      chestTypeId = 'golden_chest';
      milestoneTitle = 'Altın Hedef Tamamlandı!';
    }

    if (chestTypeId != null) {
      try {
        final result = await _ref.read(collectionProvider.notifier).openChestReward(
          ChestRewardSource.weeklyMission, 
          chestTypeId: chestTypeId,
        );
        
        if (!mounted) return true;
        _ref.read(rewardQueueProvider.notifier).enqueue(RewardPresentationEvent(
          id: 'weekly_${chestValue}_${DateTime.now().millisecondsSinceEpoch}',
          source: ChestRewardSource.weeklyMission,
          result: result,
          createdAt: DateTime.now(),
          title: milestoneTitle,
        ));
      } catch (e) {
        debugPrint('Failed to open weekly chest reward ($chestValue): $e');
      }
    }

    return true;
  }
}

final dailyMissionProvider =
StateNotifierProvider<DailyMissionNotifier, DailyMissionState>((ref) {
  return DailyMissionNotifier(ref)..init();
});
