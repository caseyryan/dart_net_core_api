import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// This converter is used on on _id field for mongo types
/// it can convert ids in both directions
class MongoIdConverter extends JsonValueConverter {
  // static final RegExp _idRegExp = RegExp(r'[a-z0-9]{24}');

  const MongoIdConverter();

  @override
  Object? convert(covariant Object? value) {
    // if (value is String) {
    //   if (_idRegExp.hasMatch(value)) {
    //     return ObjectId.fromHexString(value);
    //   }
    // } else 
    if (value is ObjectId) {
      return value.toHexString();
    }
    return value;
  }
}
