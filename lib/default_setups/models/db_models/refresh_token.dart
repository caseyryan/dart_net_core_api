import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_net_core_api/utils/time_utils.dart';

import 'base_model.dart';

class RefreshToken extends BaseModel {
  @ORMStringColumn(limit: 1024)
  String? refreshToken;

  /// in this case it's enough for storing uuid
  @ORMStringColumn(limit: 50)
  String? publicKey;

  @ORMIntColumn(
    intType: ORMIntType.integer,
  )
  @ORMNotNullColumn()
  int? userId;

  @ORMDateColumn(
    dateType: ORMDateType.timestamp,
  )
  DateTime? expiresAt;

  bool get isExpired {
    if (expiresAt == null) {
      return true;
    }
    return utcNow.isAfter(expiresAt!);
  }
}
