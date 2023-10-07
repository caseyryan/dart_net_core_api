part of '../../server.dart';

String _readEnvironment(String? env) {
  env = env?.toLowerCase();
  if (env == 'prod' || env == 'stage' || env == 'dev') {
    return env!;
  }
  return 'prod';
}
