import 'package:flutter/material.dart';
import 'package:play_sync/screens/dashboard/home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Pages for sidebar navigation
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const Center(child: Text("Match History\nComing Soon", style: TextStyle(fontSize: 24), textAlign: TextAlign.center)),
    const Center(child: Text("Leaderboard\nComing Soon", style: TextStyle(fontSize: 24), textAlign: TextAlign.center)),
    const Center(child: Text("Settings\nComing Soon", style: TextStyle(fontSize: 24), textAlign: TextAlign.center)),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PlaySync"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildSidebar(), // ← SIDEBAR ADDED HERE
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar( // Optional: Keep bottom bar or remove if you want only sidebar
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Sidebar Header with User Info
          UserAccountsDrawerHeader(
            accountName: const Text(
              "Bibek Pandey",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("bibek@example.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "B",
                style: TextStyle(fontSize: 40, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold),
              ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
            ),
          ),

          // Menu Items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: _selectedIndex == 0,
            selectedTileColor: Colors.green[50],
            onTap: () {
              _onItemTapped(0);
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Match History'),
            selected: _selectedIndex == 1,
            selectedTileColor: Colors.green[50],
            onTap: () {
              _onItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard),
            title: const Text('Leaderboard'),
            selected: _selectedIndex == 2,
            selectedTileColor: Colors.green[50],
            onTap: () {
              _onItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            selected: _selectedIndex == 3,
            selectedTileColor: Colors.green[50],
            onTap: () {
              _onItemTapped(3);
              Navigator.pop(context);
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Add logout logic later (e.g., navigate to login)
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out")),
              );
            },
          ),
        ],
      ),
    );
  }
}