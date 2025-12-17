// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';
import 'online_mode.dart';
import 'offline_mode.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back, Gamer!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
                SizedBox(height: 8),
                Text("Ready to sync up and play?", style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          OnlineMode(),
          OfflineMode(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}