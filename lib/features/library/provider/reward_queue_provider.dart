import 'package:flutter_riverpod/legacy.dart';
import '../models/reward_presentation_event.dart';

class RewardQueueState {
  final List<RewardPresentationEvent> events;
  final bool isPresenting;

  RewardQueueState({
    required this.events,
    this.isPresenting = false,
  });

  RewardQueueState copyWith({
    List<RewardPresentationEvent>? events,
    bool? isPresenting,
  }) {
    return RewardQueueState(
      events: events ?? this.events,
      isPresenting: isPresenting ?? this.isPresenting,
    );
  }
}

class RewardQueueNotifier extends StateNotifier<RewardQueueState> {
  RewardQueueNotifier() : super(RewardQueueState(events: []));

  void enqueue(RewardPresentationEvent event) {
    state = state.copyWith(events: [...state.events, event]);
  }

  RewardPresentationEvent? get current => state.events.isNotEmpty ? state.events.first : null;

  void markPresentationStarted() {
    state = state.copyWith(isPresenting: true);
  }

  void completeCurrent() {
    if (state.events.isEmpty) return;
    final newEvents = List<RewardPresentationEvent>.from(state.events)..removeAt(0);
    state = state.copyWith(
      events: newEvents,
      isPresenting: false,
    );
  }

  void clear() {
    state = RewardQueueState(events: [], isPresenting: false);
  }
}

final rewardQueueProvider = StateNotifierProvider<RewardQueueNotifier, RewardQueueState>((ref) {
  return RewardQueueNotifier();
});
