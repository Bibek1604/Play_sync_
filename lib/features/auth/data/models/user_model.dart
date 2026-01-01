import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String? name;
  @HiveField(3)
  final String token;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    required this.token,
  });

  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        token: user.token,
      );

  User toEntity() => User(
        id: id,
        email: email,
        name: name,
        token: token,
      );
}
