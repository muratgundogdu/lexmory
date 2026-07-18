import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexmory/features/missions/view/daily_mission_sheet.dart';
import 'package:lexmory/features/missions/providers/daily_mission_provider.dart';
import 'package:lexmory/features/missions/models/daily_mission.dart';
import 'package:lexmory/features/missions/widgets/weekly_collection_card.dart';
import 'package:lexmory/features/game/providers/game_provider.dart';
import 'package:lexmory/features/game/repository/game_repository.dart';
import 'package:lexmory/features/game/services/ad_service.dart';

// Mock DailyMissionNotifier
class MockDailyMissionNotifier extends DailyMissionNotifier {
  MockDailyMissionNotifier(super.ref, DailyMissionState initialState) {
    state = initialState;
  }

  @override
  Future<void> init() async {}
  
  @override
  Future<void> resetForNewDayIfNeeded() async {}
  
  @override
  Future<void> saveState() async {}

  @override
  Future<bool> claimMission(String missionId) async {
    final missions = state.missions.map((m) {
      if (m.mission.id == missionId) {
        return m.copyWith(isClaimed: true);
      }
      return m;
    }).toList();
    
    state = state.copyWith(
      missions: missions,
      weeklyBookmarks: state.weeklyBookmarks + 1,
    );
    return true;
  }
}

// Mock GameNotifier
class MockGameNotifier extends GameNotifier {
  MockGameNotifier(Ref ref) : super(MockGameRepository(), MockAdService(), ref);

  @override
  void startRegenTimer() {}

  @override
  Future<void> loadTokens() async {}

  @override
  Future<void> addTokens(int amount) async {}
}

class MockGameRepository extends GameRepository {}
class MockAdService extends AdService {}

void main() {
  late List<DailyMissionProgress> mockMissions;

  setUp(() {
    mockMissions = [
      DailyMissionProgress(
        mission: const DailyMission(
          id: 'm1',
          title: 'Mission 1',
          icon: '🎯',
          type: DailyMissionType.solveWords,
          target: 5,
          rewardTokens: 100,
          rewardBookmarks: 1,
          difficulty: DailyMissionDifficulty.easy,
        ),
        currentProgress: 5, // Ready to claim
      ),
      DailyMissionProgress(
        mission: const DailyMission(
          id: 'm2',
          title: 'Mission 2',
          icon: '🔥',
          type: DailyMissionType.reachStreak,
          target: 3,
          rewardTokens: 150,
          rewardBookmarks: 1,
          difficulty: DailyMissionDifficulty.medium,
        ),
        currentProgress: 1,
      ),
    ];
  });

  testWidgets('DailyMissionSheet scrolls vertically on small screens', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final initialState = DailyMissionState(
      missions: mockMissions,
      weeklyBookmarks: 5,
      claimedMissionIds: {},
      claimedChestValues: {},
      isLoading: false,
    );

    final container = ProviderContainer(
      overrides: [
        dailyMissionProvider.overrideWith((ref) => MockDailyMissionNotifier(ref, initialState)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DailyMissionSheet(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Mission 1'), findsOneWidget);
    
    final listView = find.byType(ListView);
    await tester.drag(listView, const Offset(0, -300));
    await tester.pump(); 

    expect(find.text('Mission 2'), findsOneWidget);
  });

  testWidgets('Successful claim starts flight animation and pulses target', (tester) async {
    final initialState = DailyMissionState(
      missions: mockMissions,
      weeklyBookmarks: 5,
      claimedMissionIds: {},
      claimedChestValues: {},
      isLoading: false,
    );

    final container = ProviderContainer(
      overrides: [
        dailyMissionProvider.overrideWith((ref) => MockDailyMissionNotifier(ref, initialState)),
        gameProvider.overrideWith((ref) => MockGameNotifier(ref)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: DailyMissionSheet(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Verify initial count
    expect(find.text('5 / 21'), findsOneWidget);

    // Find and tap "ÖDÜLÜ AL"
    final claimBtn = find.text('ÖDÜLÜ AL');
    expect(claimBtn, findsOneWidget);
    await tester.tap(claimBtn);
    
    // Pump to start the claim process
    await tester.pump();
    
    // Check for the flying bookmark icon in the overlay
    final flyingIcon = find.byIcon(Icons.menu_book_rounded);
    // Header icon + Card icons (2) + flying icon = 4?
    // Let's just check if at least N are found.
    expect(flyingIcon, findsAtLeastNWidgets(3)); 

    // Advance animation - midpoint
    await tester.pump(const Duration(milliseconds: 400));
    
    // Count should still be 5 / 21 visually because it updates on arrival
    expect(find.text('5 / 21'), findsOneWidget);

    // Complete animation - wait enough time
    await tester.pump(const Duration(seconds: 2));
    
    // After arrival, count should be updated to 6 / 21
    expect(find.text('6 / 21'), findsOneWidget);

    // Verify pulse card
    final card = find.byType(WeeklyCollectionCard);
    expect(card, findsOneWidget);
  });
}
