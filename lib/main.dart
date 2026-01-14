import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/hive_service.dart';
import 'app/app.dart';

/// Application Entry Point
/// 
/// Initializes all required services and starts the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await HiveService.init();
  
  // Run the app with Riverpod state management
  runApp(const ProviderScope(child: PlaySyncApp()));
}
