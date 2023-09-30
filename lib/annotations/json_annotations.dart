import '../utils/extensions.dart';

class JsonIgnore {
  const JsonIgnore();
}

/// If you need a field to have a specific name
/// in Json, you can pass the name here
class JsonName {
  const JsonName(this.name);
  final String name;
}

class MongoType {
  const MongoType();
}

/// Use this annotation if you need
/// to serialize / deserialize
/// private fields
class JsonInclude {
  const JsonInclude();
}

/// for mongodb
class BsonIgnore {
  const BsonIgnore();
}

abstract class KeyNameConverter {
  const KeyNameConverter();
  String convert(String value);
}

/// Used for json serialization. This annotation (is set on class)
/// will convert every field / variable name in a way that the first
/// letter will be uppercase
/// e.g. firstName will be converted to FirstName
class FirstLetterToUppercaseConverter extends KeyNameConverter {
  const FirstLetterToUppercaseConverter();

  @override
  String convert(String value) {
    return value.firstToUpperCase();
  }
}

/// Converts keys to snake case. Can be used on classes
/// as well as on public variables and getters
/// e.g. a name like userFirstName will be converted to
/// user_first_name
class CamelToSnakeConverter extends KeyNameConverter {
  const CamelToSnakeConverter();

  @override
  String convert(String value) {
    return value.camelToSnake();
  }
}

class SnakeToCamelConverter extends KeyNameConverter {
  const SnakeToCamelConverter();

  @override
  String convert(String value) {
    return value.snakeToCamel();
  }
}
