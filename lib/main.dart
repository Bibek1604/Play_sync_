import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "app/app.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("[MAIN] ========================================");
  debugPrint("[MAIN] PlaySync App Starting...");
  debugPrint("[MAIN] ========================================");

  runApp(const ProviderScope(child: PlaySyncApp()));
}
