import 'package:flutter/material.dart';

class OfflineMode extends StatelessWidget {
  const OfflineMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Offline Mode",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 16),
                const Text(
                  "Play Offline",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Practice solo or play local games\nwhen you're not connected",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                  ),
                  child: const Text("Play Offline", style: TextStyle(color: Color(0xFF2E7D32))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}