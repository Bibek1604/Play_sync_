import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard"), backgroundColor: Color(0xFF66BB6A)),
      body: const Center(
        child: Text("!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }
  
}