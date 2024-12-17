import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_net_core_api/utils/time_utils.dart';

import 'base_model.dart';

/// This is used for counting failed attempts of login using a password
class FailedPasswordInfo extends BaseModel {
  @ORMIntColumn(
    intType: ORMIntType.smallInt,
    defaultValue: 0,
  )
  int? currentAttemptCount;

  /// the number of times a user got banned from
  /// password entering
  @ORMIntColumn(
    intType: ORMIntType.smallInt,
    defaultValue: 0,
  )
  int? numFailedRounds;

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

  @ORMUniqueColumn()
  int? userId;

  @ORMDateColumn(dateType: ORMDateType.timestamp)
  DateTime? unBlockAt;
}
