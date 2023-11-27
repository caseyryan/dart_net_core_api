import 'package:dart_net_core_api/default_setups/configs/failed_password_config.dart';
import 'package:dart_net_core_api/default_setups/controllers/auth_controller.dart';
import 'package:dart_net_core_api/default_setups/models/mongo_models/failed_password_info.dart';
import 'package:dart_net_core_api/utils/extensions/extensions.dart';
import 'package:dart_net_core_api/utils/time_utils.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'mongo_store_service.dart';

/// If this services in added to the services initializer
/// of a service setup along with a built in [AuthController] it will also
/// check the number of attempts a user has entered an incorrect password
/// and if the user runs out of available attempts
/// the service will block the user for a specified number of minutes / hours and so on
class FailedPasswordBlockingService
    extends MongoStoreService<FailedPasswordInfo> {
  Future<String?> tryGetBlockingError(
    Object? userId,
  ) async {
    final config = getConfig<FailedPasswordConfig>();
    if (config == null) {
      return null;
    }
    userId = userId?.toObjectId();
    var info = await _findByUserId(userId);
    info ??= FailedPasswordInfo()..userId = userId as ObjectId?;
    int maxAttempts = config.numAllowedAttempts;
    int currentAttemptCount = info.currentAttemptCount;

    String? error = info.tryAgainErrorText;
    if (error != null) {
      return error;
    }

    int round = info.numFailedRounds;
    if (currentAttemptCount >= maxAttempts - 1) {
      final blockMinutes = config.getNumMinutesToBlock(round);
      info.unBlockAt = utcNow.add(
        Duration(
          minutes: blockMinutes,
        ),
      );
      info.currentAttemptCount = 0;
      info.numFailedRounds++;
    } else {
      info.currentAttemptCount++;
    }
    await updateOneAsync(
      selector: {
        'userId': userId,
      },
      value: info,
      upsert: true,
    );

    return error;
  }

  Future deleteByUserId(
    Object? userId,
  ) async {
    await deleteOneAsync(selector: {
      'userId': userId?.toObjectId(),
    });
  }

  Future<FailedPasswordInfo?> _findByUserId(
    Object? userId,
  ) async {
    return await findOneAsync(selector: {
      'userId': userId?.toObjectId(),
    });
  }
}
