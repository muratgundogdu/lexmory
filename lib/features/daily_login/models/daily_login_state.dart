class DailyLoginState {
  final String? lastClaimedDate; // yyyy-MM-dd
  final String? activatedOnDate; // yyyy-MM-dd
  final int currentStreakDay; // 1-7
  final bool isRewardAvailable;
  final bool isClaiming;
  final bool isLoading;

  const DailyLoginState({
    this.lastClaimedDate,
    this.activatedOnDate,
    required this.currentStreakDay,
    this.isRewardAvailable = false,
    this.isClaiming = false,
    this.isLoading = true,
  });

  factory DailyLoginState.initial() {
    return const DailyLoginState(
      currentStreakDay: 1,
      isRewardAvailable: false,
      isClaiming: false,
      isLoading: true,
    );
  }

  DailyLoginState copyWith({
    String? lastClaimedDate,
    String? activatedOnDate,
    int? currentStreakDay,
    bool? isRewardAvailable,
    bool? isClaiming,
    bool? isLoading,
  }) {
    return DailyLoginState(
      lastClaimedDate: lastClaimedDate ?? this.lastClaimedDate,
      activatedOnDate: activatedOnDate ?? this.activatedOnDate,
      currentStreakDay: currentStreakDay ?? this.currentStreakDay,
      isRewardAvailable: isRewardAvailable ?? this.isRewardAvailable,
      isClaiming: isClaiming ?? this.isClaiming,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastClaimedDate': lastClaimedDate,
      'activatedOnDate': activatedOnDate,
      'currentStreakDay': currentStreakDay,
    };
  }

  factory DailyLoginState.fromJson(Map<String, dynamic> json) {
    return DailyLoginState(
      lastClaimedDate: json['lastClaimedDate'] as String?,
      activatedOnDate: json['activatedOnDate'] as String?,
      currentStreakDay: json['currentStreakDay'] as int? ?? 1,
      isRewardAvailable: false, 
      isClaiming: false,
      isLoading: true,
    );
  }
}
