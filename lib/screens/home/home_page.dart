// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'online_mode.dart';
import 'offline_mode.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App illustration image
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 8),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/home_illustration.svg',
                height: 180,
              ),
            ),
          ),
          // Greeting and quick stats
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF2E7D32),
                      child: const Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Welcome back, Gamer!",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        SizedBox(height: 4),
                        Text("Ready to sync up and play?", style: TextStyle(fontSize: 15, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Quick stats (example)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatCard(icon: Icons.emoji_events, label: "Wins", value: "12"),
                    _StatCard(icon: Icons.history, label: "Games", value: "34"),
                    _StatCard(icon: Icons.leaderboard, label: "Rank", value: "#8"),
                  ],
                ),
              ],
            ),
          ),

          // App highlights
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Card(
              color: const Color(0xFFF1F8E9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Color(0xFF2E7D32), size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Sync & Play Instantly!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text("Seamless online and offline modes, leaderboards, and more.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Online/Offline modes
          const OnlineMode(),
          const OfflineMode(),

          // Navigation shortcuts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavShortcut(icon: Icons.leaderboard, label: "Leaderboard", route: "/dashboard", tabIndex: 2),
                _NavShortcut(icon: Icons.history, label: "History", route: "/dashboard", tabIndex: 1),
                _NavShortcut(icon: Icons.settings, label: "Settings", route: "/dashboard", tabIndex: 3),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 28),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _NavShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final int tabIndex;
  const _NavShortcut({required this.icon, required this.label, required this.route, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route, arguments: {"tabIndex": tabIndex});
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2E7D32),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}