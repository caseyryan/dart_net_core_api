import 'package:dart_net_core_api/utils/time_utils.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'base_mongo_model.dart';

/// This is used for counting failed attempts of login using a password
class FailedPasswordInfo extends BaseModel {
  int currentAttemptCount = 0;

  /// the number of times a user got banned from
  /// password entering
  int numFailedRounds = 0;

  String? get tryAgainErrorText {
    int minutes = canTryAgainInMinutes + 1;
    if (minutes > 0) {
      String timeText = '$minutes minute(s)';
      return 'You ran out of login attempts. Please try again in $timeText';
    }
    return null;
  }

  int get canTryAgainInMinutes {
    if (unBlockAt == null) {
      return -1;
    }
    final minutes = unBlockAt!.difference(utcNow).inMinutes;
    if (minutes < 0) {
      return -1;
    }
    return minutes;
  }

  ObjectId? userId;
  DateTime? unBlockAt;
}
