import 'package:dart_net_core_api/utils/extensions/extensions.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// This converter is used on on _id field for mongo types
/// it can convert ids in both directions
class MongoIdConverter extends JsonValueConverter {
  const MongoIdConverter();

  @override
  Object? convert(
    covariant Object? value,
    SerializationDirection direction,
  ) {
    if (direction == SerializationDirection.toJson) {
      if (value is ObjectId) {
        return value.toHexString();
      }
    } else if (direction == SerializationDirection.fromJson) {
      if (value is String) {
        if (value.isMatchingObjectId()) {
          return ObjectId.fromHexString(value);
        }
      }
    }
    return value;
  }
}
