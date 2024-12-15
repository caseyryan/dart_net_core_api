import 'dart:async';

import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_net_core_api/default_setups/configs/failed_password_config.dart';
import 'package:dart_net_core_api/default_setups/controllers/auth_controller.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/utils/time_utils.dart';

import '../../default_setups/models/db_models/failed_password_info.dart';

/// If this services is added to the services initializer
/// of a service setup along with a built in [AuthController] it will also
/// check the number of attempts a user has entered an incorrect password
/// and if the user runs out of available attempts
/// the service will block the user for a specified number of minutes / hours and so on
class FailedPasswordBlockingService extends Service {
  Future<String?> tryGetBlockingError(
    int? userId,
  ) async {
    return await _tryGetBlockingError(userId, false);
  }

  Future<String?> _tryGetBlockingError(
    int? userId,
    bool lastAttempt,
  ) async {
    final config = getConfig<FailedPasswordConfig>();
    if (config == null) {
      return null;
    }
    FailedPasswordInfo? info = FailedPasswordInfo()..userId = userId;

    final result = await info.tryFind<FailedPasswordInfo>();
    if (result.isError) {
      if (!result.error!.isTableNotExists) {
        throw InternalServerException(
          message: result.error!.message!,
        );
      } else {
        if (lastAttempt) {
          return 'Could not create table for password blocking service';
        }

        /// table not exists
        if (await (FailedPasswordInfo).createTable()) {
          return _tryGetBlockingError(userId, true);
        }

        return 'Failed to check password block';
      }
    }

    if (result.value == null) {
      info.currentAttemptCount = 0;
      info.numFailedRounds = 0;
      final upsertResult = await info.tryInsertOne<FailedPasswordInfo>(
        conflictResolution: ConflictResolution.error,
        createTableIfNotExists: true,
      );
      if (upsertResult.isError) {
        return upsertResult.error!.message;
      } else if (upsertResult.value == null) {
        return 'Could password blocking record';
      }
      return null;
    } else {
      info = result.value!;
    }

    int maxAttempts = config.numAllowedAttempts;
    int currentAttemptCount = info.currentAttemptCount ?? 0;

    String? error = info.tryAgainErrorText;
    if (error != null) {
      return error;
    }
    info.numFailedRounds ??= 0;
    info.currentAttemptCount ??= 0;

    int round = info.numFailedRounds!;
    if (currentAttemptCount >= maxAttempts - 1) {
      final blockMinutes = config.getNumMinutesToBlock(round);
      info.unBlockAt = utcNow.add(
        Duration(
          minutes: blockMinutes,
        ),
      );
      info.currentAttemptCount = 0;
      info.numFailedRounds = info.numFailedRounds! + 1;
    } else {
      info.currentAttemptCount = info.currentAttemptCount! + 1;
    }

    final upsertResult = await info.tryUpsertOne<FailedPasswordInfo>();
    if (upsertResult.isError) {
      return upsertResult.error!.message;
    }
    if (upsertResult.value != null) {}

    return null;
  }

  Future deleteByUserId(
    int? userId,
  ) async {
    await (FailedPasswordInfo).delete().where([
      ORMWhereEqual(
        key: 'user_id',
        value: userId,
      ),
    ]).execute();
  }

  @override
  FutureOr dispose() {}

  @override
  FutureOr onReady() {}
}
