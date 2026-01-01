import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String userBoxName = 'userBox';
  static const String tokenBoxName = 'tokenBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters here
    // e.g. Hive.registerAdapter(UserModelAdapter());
  }

  static Future<Box> openUserBox() async {
    return await Hive.openBox(userBoxName);
  }

  static Future<Box> openTokenBox() async {
    return await Hive.openBox(tokenBoxName);
  }
}
