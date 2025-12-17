import 'package:flutter/material.dart';

class OnlineMode extends StatelessWidget {
  const OnlineMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Online Mode",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF66BB6A), width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.wifi, size: 80, color: const Color(0xFF2E7D32)),
                const SizedBox(height: 16),
                const Text(
                  "Find Players Online",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Join real-time multiplayer sessions\nwith gamers worldwide",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Go Online"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}