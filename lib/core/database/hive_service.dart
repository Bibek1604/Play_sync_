import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String userBoxName = 'userBox';
  static const String tokenBoxName = 'tokenBox';
  static const String registeredUsersBoxName = 'registered_users';

  static Future<void> init() async {
    await Hive.initFlutter();
    // Open boxes on init to ensure they persist
    await Hive.openBox(userBoxName);
    await Hive.openBox(registeredUsersBoxName);
  }

  static Future<Box> openUserBox() async {
    if (!Hive.isBoxOpen(userBoxName)) {
      return await Hive.openBox(userBoxName);
    }
    return Hive.box(userBoxName);
  }

  static Future<Box> openRegisteredUsersBox() async {
    if (!Hive.isBoxOpen(registeredUsersBoxName)) {
      return await Hive.openBox(registeredUsersBoxName);
    }
    return Hive.box(registeredUsersBoxName);
  }

  static Future<Box> openTokenBox() async {
    if (!Hive.isBoxOpen(tokenBoxName)) {
      return await Hive.openBox(tokenBoxName);
    }
    return Hive.box(tokenBoxName);
  }
}
