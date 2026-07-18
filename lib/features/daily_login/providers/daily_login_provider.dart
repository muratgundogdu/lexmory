import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../core/services/clock_provider.dart';
import '../../game/providers/game_provider.dart';
import '../../library/models/chest_open_result.dart';
import '../../library/models/chest_reward_source.dart';
import '../../library/models/reward_presentation_event.dart';
import '../../library/provider/collection_provider.dart';
import '../../library/provider/reward_queue_provider.dart';
import '../models/daily_login_reward.dart';
import '../models/daily_login_state.dart';
import '../models/daily_login_claim_result.dart';

class DailyLoginNotifier extends StateNotifier<DailyLoginState> {
  final Ref _ref;
  static const String _storageKey = 'lexmory_daily_login_state';

  DailyLoginNotifier(this._ref) : super(DailyLoginState.initial());

  @visibleForTesting
  late Future<void> initialization;

  void init() {
    initialization = _loadFromDisk();
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    
    DailyLoginState loadedState = DailyLoginState.initial();
    if (jsonStr != null) {
      try {
        loadedState = DailyLoginState.fromJson(json.decode(jsonStr));
      } catch (e) {
        debugPrint('Error loading daily login state: $e');
      }
    }

    final now = _ref.read(clockProvider)();
    final todayStr = _formatDate(now);
    
    if (!mounted) return;

    // Migration and Activation Logic
    if (loadedState.activatedOnDate == null) {
      if (loadedState.lastClaimedDate != null) {
        // Rule 2: Missing activatedOnDate but lastClaimedDate exists
        loadedState = loadedState.copyWith(activatedOnDate: loadedState.lastClaimedDate);
      } else {
        // Check if onboarding is already complete
        final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;
        final hintClearShown = prefs.getBool('hint_clear_tutorial_shown') ?? false;
        final revealShown = prefs.getBool('reveal_tutorial_shown') ?? false;

        if (tutorialCompleted && hintClearShown && revealShown) {
          // Rule 3: Missing activatedOnDate and onboarding is true
          loadedState = loadedState.copyWith(activatedOnDate: todayStr);
        }
      }
    }

    if (loadedState.activatedOnDate == null || todayStr == loadedState.activatedOnDate) {
      state = loadedState.copyWith(isRewardAvailable: false, isLoading: false);
    } else if (loadedState.lastClaimedDate == todayStr) {
      state = loadedState.copyWith(isRewardAvailable: false, isLoading: false);
    } else {
      int nextStreakDay = 1;
      if (loadedState.lastClaimedDate != null) {
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr = _formatDate(yesterday);
        
        if (loadedState.lastClaimedDate == yesterdayStr) {
          nextStreakDay = loadedState.currentStreakDay >= 7 ? 1 : loadedState.currentStreakDay + 1;
        } else {
          nextStreakDay = 1;
        }
      } else {
        nextStreakDay = 1;
      }
      
      state = loadedState.copyWith(
        currentStreakDay: nextStreakDay,
        isRewardAvailable: true,
        isLoading: false,
      );
    }
  }

  Future<void> activateAfterOnboarding() async {
    if (state.activatedOnDate != null) return;

    final now = _ref.read(clockProvider)();
    final todayStr = _formatDate(now);

    state = state.copyWith(activatedOnDate: todayStr);
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(state.toJson()));
  }

  bool get canClaimToday => state.isRewardAvailable && !state.isClaiming;

  DailyLoginReward get currentReward => dailyLoginRewards[state.currentStreakDay - 1];

  Future<DailyLoginClaimResult> claimReward() async {
    if (!canClaimToday) {
      throw StateError('Reward not available or already claiming');
    }

    final now = _ref.read(clockProvider)();
    final todayStr = _formatDate(now);
    final reward = currentReward;
    final previousState = state;

    state = state.copyWith(isClaiming: true);

    try {
      await _ref.read(gameProvider.notifier).addTokens(reward.tokenAmount);

      ChestOpenResult? chestResult;
      if (reward.chestTypeId != null) {
        chestResult = await _ref.read(collectionProvider.notifier).openChestReward(
          ChestRewardSource.dailyLogin,
          chestTypeId: reward.chestTypeId,
        );

        if (!mounted) return DailyLoginClaimResult(streakDay: reward.day, grantedTokens: reward.tokenAmount, chestResult: chestResult);
        _ref.read(rewardQueueProvider.notifier).enqueue(RewardPresentationEvent(
          id: 'login_day_${reward.day}_${DateTime.now().millisecondsSinceEpoch}',
          source: ChestRewardSource.dailyLogin,
          result: chestResult,
          createdAt: DateTime.now(),
          title: '${reward.day}. Gün Giriş Ödülü!',
        ));
      }

      if (!mounted) return DailyLoginClaimResult(streakDay: reward.day, grantedTokens: reward.tokenAmount, chestResult: chestResult);
      state = state.copyWith(
        lastClaimedDate: todayStr,
        isRewardAvailable: false,
        isClaiming: false,
      );
      
      await _saveToDisk();

      return DailyLoginClaimResult(
        streakDay: reward.day,
        grantedTokens: reward.tokenAmount,
        chestResult: chestResult,
      );
    } catch (e) {
      state = previousState.copyWith(isClaiming: false);
      rethrow;
    }
  }
}

final dailyLoginProvider = StateNotifierProvider<DailyLoginNotifier, DailyLoginState>((ref) {
  return DailyLoginNotifier(ref)..init();
});
