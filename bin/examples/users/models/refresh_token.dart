import 'package:mongo_dart/mongo_dart.dart';

class RefreshToken {
  String? refreshToken;
  String? publicKey;
  DateTime? createdAt;
  DateTime? expiresAt;
  DateTime? updatedAt;
  ObjectId? _id;
  ObjectId? userId;
}