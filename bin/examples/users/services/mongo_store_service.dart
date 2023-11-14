import 'package:dart_net_core_api/database/configs/mongo_config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class MongoStoreService<T> extends Service {
  MongoStoreService({
    this.collectionName,
  });

  /// [collectionName] can be used to set a fully custom collection name
  ///
  /// By default the name is taken from the name of [T] type converted to
  /// a snake case. E.g. `RefreshToken` will turn into `refresh_token`
  final String? collectionName;
  Db? _db;
  DbCollection? _collection;

  /// Might be useful if you don't want to extract
  /// typed objects or you want to execute
  /// some custom aggregation etc.
  Future<DbCollection> get collection async {
    await ensureConnected();
    return _collection!;
  }

  Future<T?> findOne([
    dynamic selector,
  ]) async {
    await ensureConnected();
    final value = await _collection!.findOne(selector);
    return _convertFromMap(value);
  }

  T? _convertFromMap(Map<String, dynamic>? value) {
    if (value == null) {
      return null;
    }
    return fromJson<T>(value) as T;
  }

  Map<String, dynamic> _convertToMapBeforeInsertion(T value) {
    /// TODO: сделать toBson() вмето toJson()
    final map = (value as Object).toJson() as Map<String, dynamic>;
    final now = DateTime.now().toUtc();
    if (map['createdAt'] == null) {
      map['createdAt'] = now;
    }
    map['updatedAt'] = now;
    return map;
  }

  Future<ObjectId?> insertOneAndReturnId(T value) async {
    await ensureConnected();
    final WriteResult result = await _collection!.insertOne(
      _convertToMapBeforeInsertion(value),
    );
    return result.document?['_id'] as ObjectId?;
  }

  Future<T?> findAndModify({
    dynamic query,
    dynamic sort,
    bool? remove,
    update,
    bool? returnNew,
    dynamic fields,
    bool? upsert,
  }) async {
    await ensureConnected();
    final value = await _collection!.findAndModify(
      fields: fields,
      query: query,
      sort: sort,
      remove: remove,
      returnNew: returnNew,
      update: update,
      upsert: upsert,
    );
    return _convertFromMap(value);
  }

  @override
  set isSingleton(bool value) {
    if (value) {
      throw '''
        $MongoStoreService CANNOT be a singleton. Use lazy initializer instead
      ''';
    }
    super.isSingleton = value;
  }

  MongoConfig get _config {
    return getConfig<MongoConfig>()!;
  }

  Future ensureConnected() async {
    if (_db != null) {
      return;
    }
    _db = await Db.create(_config.connectionString!);
    await _db!.open();
    final name = collectionName ?? '${T.toString().camelToSnake()}s';
    _collection = _db!.collection(name);
  }

  @override
  Future onReady() async {}

  @override
  Future dispose() async {
    await _db?.close();
  }
}
