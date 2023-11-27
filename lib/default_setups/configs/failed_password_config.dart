import 'package:dart_net_core_api/config.dart';

class FailedPasswordConfig implements IConfig {
  late int numAllowedAttempts;
  /// a list of [int]s that specify numbers of minutes 
  /// to block a user for failed password attempts
  /// e.g. [60, 180, 1440] means that when a user runs out of [numAllowedAttempts]
  /// for the first time, the next attempt will be available in 60 minutes. 
  /// When that happens for the second time, then the next attempt will be 
  /// available in 180 and so on. You may use your own preset of minutes
  late List<int> blockMinutes;

  int getNumMinutesToBlock(int currentRound) {
    if (currentRound >= blockMinutes.length) {
      return blockMinutes.last;
    }
    else if (currentRound < 0) {
      return blockMinutes.first;
    }
    return blockMinutes[currentRound];
  }
}