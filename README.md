### Dart Net Core API

## UNDER CONSTRUCTION


`Dart Net Core API` is the easiest to set up and use API server ever written Dart. The main idea, and the main difference between `Dart Net Core API` and other existing dart servers, is the maximum automation. The name and the concept was inspired by [Dotnet Core API](https://dotnet.microsoft.com/en-us/apps/aspnet/apis). No it doesn't repeat its API or anything, it has its own. What I mean is that it has borrowed the simplicity from the Dotnet Core. I personally think that the `Dotnet Core API` is a great solution but being a `Dart` developer I want to write in `Dart` (unexpected, right?) but I also want to have the benefits that Dotnet developers have. Even if you never worked with `Dotnet Core` you will still be able to understand what I was talking about when you look at the examples below



- [Getting started](#getting-started)
    - [JSON Configs](#json-configs)
    - [Server Code example](#server-code-example)
    - [Isolates](#isolates)
    - [Controllers](#controllers)
    - [Endpoint Annotations](#endpoint-annotations)
    - [Socket Connections](#socket-connections)
    - [Cron Jobs](#cron-jobs)




### Getting Started

Create an empty `Dart` project and add the following dependencies to your `pubspec.yaml`
(To be completed, the package is not published yet so don't try it so far, it's here just for the sake of the documentation, which will be updated as it goes)

```yaml
dependencies:
  dart_net_core_api: ^0.0.1 (not published yet)
```

### JSON Configs

Create a `config.dev.json` or `config.prod.json` file in the root of your project and add the similar content 
to it, using whatever you need. You need ```jwtConfig``` only in case you want to use the built-in 
`AuthController` because it's based on Json Web Tokens. If you don't need it, you may not fill in these values
You also don't need `socketConfig` if you are not planning to use the built-in sockets.
The database configs like: `mongoConfig`, `postgresqlConfig`, `mysqlConfig` are optional and you can fill them in
if you need to use any of these databases with a built-in ORM. If you want to implement a custom solution 
feel free to skip all of these. 

**If you want to use any of the configs here, please refer to the config model class structures 
e.g. jwtConfig is defined in `JwtConfig` class, `mongoConfig` is defined in `MongoConfig` class etc.**


```json
{
    "jwtConfig": {
        "hmacKey": "REPLACE_WITH_YOUR_HMAC_KEY",
        "refreshTokenHmacKey": "REPLACE_WITH_YOUR_REFRESH_TOKEN_HMAC_KEY",
        "issuer": "https://localhost",
        "bearerLifeSeconds": 86400,
        "useRefreshToken": true,
        "refreshLifeSeconds": 2592000,
        "audiences": [
            "https://localhost"
        ]
    },
    "maxUploadFileSizeBytes": 104857600,
    "mongoConfig": {},
    "postgresqlConfig": {},
    "mysqlConfig": {},
    "passwordHashConfig": {
        "salt": "REPLACE_WITH_PASSWORD_HASH_SALT"
    },
    "staticFileConfig": {
        "isAbsolute": false,
        "staticFilesRoot": "bin/static_files"
    },
    "socketConfig": {
        "port": 3001,
        "allowDefaultNamespace": true
    },
    "failedPasswordConfig": {
        "numAllowedAttempts": 5,
        "blockMinutes": [
            5,
            15,
            30,
            60,
            120,
            240,
            1440
        ]
    },
    "printDebugInfo": true
}
```
---
ENVIRONMENT VARIABLES: The configs support environment variables. If you want to use the value from an environment variable
you can use the following syntax `$ENV` or `$env` (lowercase) in the config file. For example, if you set the 
environment variable `salt` to `$ENV` it will search for an environment variable called `SALT` (uppercase) because 
the `$ENV` is uppercase, and if you use the lowercase syntax (`$env`) it will search for an environment variable called `salt`.

```json
{
    "passwordHashConfig": {
        "salt": "$ENV"
    }
}
```

It is also possible to use a different name for the environment variable, for example if called your 
environment variable as `MY_STRONG_PASSWORD_SALT` but the config field is still called `salt` you can use the 
following approach: 
```json 
{
    "salt": "$MY_STRONG_PASSWORD_SALT"
}
```
Notice that it starts with a dollar sign followed by the name of your environment variable.

---

**IMPORTANT!** The `config.dev.json` and `config.prod.json` etc. are NOT the required config names. You may call them whatever you want, but this approach is just clear enough to understand what the file is used for and in which environment. 
In order for the server to find the config file, you need to pass the `--configPath` argument to the server launch command. 
For example, if you have a `config.dev.json` file in the root of your project, you can launch the server like this:

```bash
dart bin/main.dart --configPath config.dev.json --env dev
```

The example is also provided in the `vscode` launch configuration file.

```json
{   
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Example Server",
            "request": "launch",
            "type": "dart",
            "program": "example/main.dart",
            "args": [
                "--configPath",
                "example/config.dev.json",
                "--env",
                "dev"
            ]
        },
    ],
    "compounds": []
}
```

### Server Code example
Create a `main.dart` file in the root of your project and add the similar code
to it (of course you don't have to use the example code, it's just here to show you how it works)

```dart
import 'package:dart_net_core_api/base_services/password_hash_service/password_hash_service.dart';
import 'package:dart_net_core_api/default_setups/controllers/auth_controller.dart';
import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/jwt/jwt_service.dart';

import 'controllers/user_controller.dart';

/// `arguments` are required. They are used to find 
/// configs and detect the environment
void main(List<String> arguments) {
  Logger.root.level = Level.ALL;
  Server(
    /// This is the number of isolates that will be created
    numInstances: 2,
    settings: ServerSettings(
      arguments: arguments,
      apiControllers: [
        AuthController,
        AdminController,
        /// this is a controller that is documented
        UserController,
      ],
      /// The default config is recommended. But you can implement a custom one
      /// The only requirement is that it MUST implement `IConfig` interface 
      /// or else it will not be recognized as a config
      /// If you implement a custom one, you must also write a corresponding JSON 
      /// config so that your config could be deserialized from it correctly 
      configType: Config,
      singletonServices: [
        /// The services provided below are not required. It's just an example setup
        /// You don't have to use any of the built-in services at all

        /// the built-in Json Web Token Service. 
        /// If you don't need it
        /// you may implement your own authorization service
        JwtService(),
        /// This service helps generate password hashes in a 
        /// built-it AuthController
        PasswordHashService(),
      ],
      /// Prefer lazyServiceInitializer for the type of
      /// services that are supposed to live for a period of one
      /// request and be destroyed along with controllers.
      /// For the services that are not supposed to be disposed of
      /// use `singletonServices`
      lazyServiceInitializer: {},
      /// if you don't want to specify a custom Json Serializer
      /// in each model you can use this one
      /// For example you want all of your serialized model fields to be snake cased
      /// just add `CamelToSnake` instance here and it will be applied to all models
      /// automatically. Local serializers on fields will override this behavior
      jsonSerializer: DefaultJsonSerializer(
        /// CamelToSnake(),
        /// SnakeToCamel(),
        null,
      ),
      /// The base path may be overridden in each controller if necessary
      /// by using [BaseApiPath] annotation on the controller class, with a new path
      /// e.g. @BaseApiPath('/api/v2') if you need a second version of your API
      baseApiPath: '/api/v1',
    ),
  );
}
```

### Isolates

The SDK is based on the built-in `Dart` `HttpServer` under the hood
so it natively supports running in isolates. When you specify the number of isolates
in the `Server` constructor, it will create that number of isolates and run the server
in each of them. The number is only limited by your hardware capabilities.




### Controllers

The SDK is based on the concept of a single-use controllers. It means that all your endpoints 
must be placed into an ancestors of `ApiController` class. The controller types must be 
registered in the `Server` constructor. 
A new instance of a controller will be created for each request and it will be disposed of 
after the request is processed. So DON'T store any data in the field variables of your controllers between requests, it will be lost. 

The controllers support real dependency injection. 

*At the moment it's restricted by the registered services.*

The **real** dependency injection means that you don't have to use any hacks/builders to inject services into your controllers like it's done in Flutter, for example. 
All you have to do is to add a constructor parameter with the type of the service you want to inject and it will be injected automatically. The server will search for the service in the `Server` constructor and if it's not found it will try to find it in the `singletonServices` list. If it's not found there either, it will throw an exception. 
You can also use the `lazyServiceInitializer` list to add services that will be instantiated on demand. 
For example, you can add a service that will be instantiated for each request and will be destroyed along with the controller.

```dart
@BaseApiPath('/api/v2/dictionary')
class DictionaryController extends ApiController {

    DictionaryController(
        this.lemmatizationService,
    );
    /// if this service was added to the `Server` constructor
    /// it will be automatically injected when the controller is instantiated 
    final LemmatizationService lemmatizationService;

    @HttpGet('/word/{:word}')
    Future<User?> getUserById({
        required String word,
    }) async {
        final lemmatizedWord = await lemmatizationService.lemmatize(word);
        ...
    }
}
```









