import 'package:dart_net_core_api/database/configs/mongo_config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/extensions/extensions.dart';
import 'package:dart_net_core_api/utils/time_utils.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import '../models/mongo_models/base_mongo_model.dart';

class MongoCollectionIndex {
  final String? key;
  final Map<String, dynamic>? keys;
  final bool? unique;
  final bool? sparse;
  final bool? background;
  final bool? dropDups;
  final Map<String, dynamic>? partialFilterExpression;
  final String? name;
  final bool? modernReply;
  const MongoCollectionIndex({
    this.key,
    this.keys,
    this.unique,
    this.sparse,
    this.background,
    this.dropDups,
    this.partialFilterExpression,
    this.name,
    this.modernReply,
  });
}

class MongoStoreService<T extends BaseMongoModel> extends Service {
  MongoStoreService({
    this.collectionName,
    this.createCollectionOptions,
    this.rawOptions,
    this.indices = const [],
  });

  static final Map<Object, String> _collectionNames = {};

  /// [collectionName] can be used to set a fully custom collection name
  ///
  /// By default the name is taken from the name of [T] type converted to
  /// a snake case. E.g. `RefreshToken` will turn into `refresh_token`
  final String? collectionName;
  final CreateCollectionOptions? createCollectionOptions;
  final Map<String, Object>? rawOptions;
  final List<MongoCollectionIndex> indices;

  Db? _db;
  DbCollection? _collection;

  String get _collectionName {
    if (_collectionNames[runtimeType] == null) {
      _collectionNames[runtimeType] = collectionName ?? '${T.toString().camelToSnake()}s';
    }
    return _collectionNames[runtimeType]!;
  }

  /// Might be useful if you don't want to extract
  /// typed objects or you want to execute
  /// some custom aggregation etc.
  Future<DbCollection> getCollectionAsync() async {
    await ensureConnected();
    return _collection!;
  }

  Future<T?> findOneAsync({
    required Map<String, dynamic> selector,
  }) async {
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

  Future<List<T>> findManyAsync({
    Map<String, dynamic> selector = const {},
    int page = 0,
    int limit = 20,
  }) async {
    await ensureConnected();
    final result = await _collection!
        .find(selector)
        .skip(page * limit)
        .take(limit)
        .map(
          (e) => fromJson<T>(e) as T,
        )
        .cast<T>()
        .toList();

    return result;
  }

  Map<String, dynamic> _convertToMapBeforeInsertion(T value) {
    final map = value.toBson() as Map<String, dynamic>;
    final now = utcNow;
    if (map['createdAt'] == null) {
      map['createdAt'] = now;
    }
    map['updatedAt'] = now;
    return map;
  }

  Future<ObjectId?> insertOneAndReturnIdAsync(T value) async {
    await ensureConnected();
    final WriteResult result = await _collection!.insertOne(
      _convertToMapBeforeInsertion(value),
    );
    return result.document?['_id'] as ObjectId?;
  }

  Future<bool> deleteOneAsync({
    required Map<String, dynamic> selector,
    WriteConcern? writeConcern,
    CollationOptions? collation,
    String? hint,
    Map<String, Object>? hintDocument,
  }) async {
    await ensureConnected();
    final result = await _collection!.deleteOne(
      selector,
      writeConcern: writeConcern,
      collation: collation,
      hint: hint,
      hintDocument: hintDocument,
    );
    return result.isSuccess;
  }

  /// all fields that are not supposed to be set
  /// in a database, must be null in the value object
  Future<bool> updateOneAsync({
    required Map<String, dynamic> selector,
    required T value,
    bool? upsert,
  }) async {
    await ensureConnected();
    value.updatedAt = utcNow;
    final bson = value.toBson(
      includeNullValues: false,
    );

    final result = await _collection!.updateOne(
      selector,
      {
        '\$set': bson,
      },
      upsert: upsert,
    );
    return result.isSuccess;
  }

  Future<T?> findAndModifyAsync({
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
    final name = _collectionName;
    if (_collection == null) {
      await _db!.createCollection(
        name,
        createCollectionOptions: createCollectionOptions,
        rawOptions: rawOptions,
      );
    }
    _collection = _db!.collection(name);
    for (var index in indices) {
      await _collection!.createIndex(
        background: index.background,
        dropDups: index.dropDups,
        key: index.key,
        keys: index.keys,
        modernReply: index.modernReply,
        name: index.name,
        partialFilterExpression: index.partialFilterExpression,
        sparse: index.sparse,
        unique: index.unique,
      );
    }
  }

  @override
  Future onReady() async {}

  @override
  Future dispose() async {
    await _db?.close();
  }
}
