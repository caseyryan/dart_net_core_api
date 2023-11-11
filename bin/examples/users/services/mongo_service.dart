import 'package:dart_net_core_api/database/configs/mongo_config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class MongoService<T> extends Service {
  final String? collectionName;
  MongoService({
    this.collectionName,
  });

  Db? _db;
  DbCollection? _collection;

  /// Might be useful if you don't want to extract
  /// typed objects or you want to execute
  /// some custom aggregation etc.
  Future<DbCollection> get collection async {
    await _tryInit();
    return _collection!;
  }

  Future<T?> findOne([
    dynamic selector,
  ]) async {
    await _tryInit();
    final value = await _collection!.findOne(selector);
    return _convertFromMap(value);
  }

  T? _convertFromMap(Map<String, dynamic>? value) {
    if (value == null) {
      return null;
    }
    return fromJson<T>(value) as T;
  }

  Map<String, dynamic> _convertToMap(T value) {
    return (value as Object).toJson() as Map<String, dynamic>;
  }

  Future<bool> insertOne(T value) async {
    await _tryInit();
    final result = await _collection!.insertOne(
      _convertToMap(value),
    );
    return result.isSuccess;
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
    await _tryInit();
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
        $MongoService CANNOT be a singleton because it 
        is initialized and disposed for each request 
        api controller instance that requires it.
        Put this service into `lazyServiceInitializer` 
        in your Server instance settings
      ''';
    }
    super.isSingleton = value;
  }

  MongoConfig get _config {
    return getConfig<MongoConfig>()!;
  }

  Future _tryInit() async {
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
