import 'package:dart_net_core_api/server.dart';

class ServerWithMongo {
  factory ServerWithMongo.withJWTAuth({
    int numInstances = 2,
    required ServerSettings settings,
    List<Type>? apiControllers,
  }) {
    return ServerWithMongo(
      settings: settings,
      numInstances: numInstances,
    );
  }

  ServerWithMongo({
    int numInstances = 2,
    required ServerSettings settings,
  }) {}
}
