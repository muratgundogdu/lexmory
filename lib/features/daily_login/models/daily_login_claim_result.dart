import '../../library/models/chest_open_result.dart';

class DailyLoginClaimResult {
  final int streakDay;
  final int grantedTokens;
  final ChestOpenResult? chestResult;

  DailyLoginClaimResult({
    required this.streakDay,
    required this.grantedTokens,
    this.chestResult,
  });
}
