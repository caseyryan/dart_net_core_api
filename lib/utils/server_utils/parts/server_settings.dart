part of '../../../server.dart';

class ServerSettings {
  /// [arguments] a list of arguments from main method
  /// e.g.
  /// [
  //     "--configPath",
  //     "config.dev.json",
  //     "--env",
  //     "dev"
  // ]
  /// [baseApiPath] this path will be prepended to
  /// all controllers by default. But if you need a custom
  /// default path for a particular controller you can override this
  /// by adding a @BaseApiPath annotation to that controller's
  /// constructor. E.g
  ///  @BaseApiPath('/api/v2')
  ///  UserController() {}
  /// and your controller will use a custom path
  ///
  /// [jsonSerializer] is used to serialize endpoint responses
  /// if the Content-Type header is application/json
  /// you can simply return an instance of a class e.g. User
  /// and it will automatically be serialized to json
  /// NOTICE: If you don't need your responses to be serialized automatically
  /// just set [jsonSerializer] to null
  ///
  /// [apiControllers] the list of controller types.
  /// It can be null or empty but if you also don't add
  /// standalone endpoints then this will mean the server is
  /// basically useless because there is no endpoint to call
  ///
  /// [lazyServiceInitializer] an initializer that will create a service
  /// instance only on demand
  ///
  /// [singletonServices] a list of services that will be stored as
  /// singletons in this server instance. Notice that an separate instance will
  /// be created for each isolate
  ///
  /// [custom500Handler] if you want to process default 500 error
  /// on your own, just pass this handler
  ///
  /// [configType] is the type of your config. Basically it's just for the
  /// purpose of a having a typed configuration. You can write your own class
  /// it will be deserialized using reflection
  ///
  /// [dateParser] a tool to convert string dates from params to a DateTime
  /// the default parser uses [DateTime.tryParse] but you can implement your own
  /// parser for any types of date representation
  ///

  const ServerSettings({
    this.arguments,
    this.baseApiPath = '/api/v1',
    this.httpPort = 8084,
    this.httpsPort = 8085,
    this.ipV4Address = '0.0.0.0',
    this.useHttp = true,
    this.useHttps = false,
    this.apiControllers,
    this.securityContext,
    this.custom500Handler,
    this.custom404Handler,
    this.configType = Config,
    this.jsonSerializer = const DefaultJsonSerializer(
      null,
    ),
    this.lazyServiceInitializer,
    this.singletonServices,
    this.dateParser = defaultDateParser,
  });

  final List<Type>? apiControllers;
  final SecurityContext? securityContext;
  final Type configType;
  final Map<Type, LazyServiceInitializer>? lazyServiceInitializer;
  final List<Service>? singletonServices;
  final List<String>? arguments;
  final bool useHttp;
  final bool useHttps;
  final int httpPort;
  final int httpsPort;
  final String baseApiPath;
  final String ipV4Address;
  final DateParser dateParser;
  final ExceptionHandler? custom500Handler;
  final ExceptionHandler? custom404Handler;
  final JsonSerializer? jsonSerializer;
}
