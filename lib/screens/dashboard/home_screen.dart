import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Header
              Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Text(
                      "B",
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, Bibek!",
                          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        Text(
                          "Ready to play & sync?",
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Stats Grid - COMPLETELY OVERFLOW-FREE
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.0, // Higher ratio = taller cards, no overflow ever
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard("Online Games", "142", Icons.videogame_asset, const Color(0xFF2E7D32)),
                  _buildStatCard("Offline Games", "89", Icons.location_on, Colors.orange),
                  _buildStatCard("Active Players", "1,247", Icons.people_alt, Colors.blue),
                  _buildStatCard("Your Wins", "36", Icons.emoji_events, Colors.purple),
                ],
              ),

              const SizedBox(height: 40),

              // Quick Actions
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildActionButton("Create Session", Icons.add_circle_outline, const Color(0xFF2E7D32))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildActionButton("Find Nearby", Icons.location_searching, Colors.orange)),
                ],
              ),

              const SizedBox(height: 40),

              // Nearby Games
              Text(
                "Nearby Offline Games",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildNearbyCard("Football Match", "Alex • 600m", "7/10 players", Icons.sports_soccer),
                    _buildNearbyCard("Board Games Night", "Sarah • 1.2km", "4/8 players", Icons.casino),
                    _buildNearbyCard("Basketball", "Mike • 800m", "9/12 players", Icons.sports_basketball),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Online Sessions
              Text(
                "Active Online Sessions",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSessionTile("Chess Masters", "2/2 • In Progress", Icons.grid_3x3),
              _buildSessionTile("Ludo Party Room", "3/4 • Waiting", Icons.casino),
              _buildSessionTile("Among Us Crew", "8/10 • Lobby Open", Icons.videogame_asset),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // Overflow-free Stat Card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action Button
  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 10,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nearby Card (safe height)
  Widget _buildNearbyCard(String title, String subtitle, String players, IconData icon) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFF2E7D32), child: Icon(icon, color: Colors.white, size: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              const SizedBox(height: 4),
              Text(players, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Join", style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Session Tile
  Widget _buildSessionTile(String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: const Color(0xFF2E7D32), child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text("Enter", style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}