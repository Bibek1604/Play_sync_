import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/database/hive_service.dart';
import 'features/auth/data/models/user_model.dart';
import 'app/app.dart';

/// Application Entry Point
/// 
/// Initializes all required services and starts the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await HiveService.init();
  Hive.registerAdapter(UserModelAdapter());
  
  // Run the app with Riverpod state management
  runApp(const ProviderScope(child: PlaySyncApp()));
}
