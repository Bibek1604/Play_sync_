import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int current = 0;

  final List<OnboardingData> pages = [
    OnboardingData(
      icon: Icons.sports_esports,
      title: "Play Together",
      description: "Create or join gaming sessions with players worldwide. Experience real-time multiplayer fun!",
      color: const Color(0xFF2E7D32),
    ),
    OnboardingData(
      icon: Icons.location_on,
      title: "Find Nearby Gamers",
      description: "Discover players in your area for offline meetups and local gaming tournaments.",
      color: const Color(0xFF388E3C),
    ),
    OnboardingData(
      icon: Icons.chat_bubble,
      title: "Real-Time Chat",
      description: "Stay connected with your team through instant messaging and voice coordination.",
      color: const Color(0xFF43A047),
    ),
    OnboardingData(
      icon: Icons.leaderboard,
      title: "Climb the Ranks",
      description: "Compete on leaderboards, earn achievements, and become a gaming legend!",
      color: const Color(0xFF66BB6A),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                  child: Text(
                    "Skip",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => current = i),
                itemCount: pages.length,
                itemBuilder: (context, index) => _buildPage(pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) => _buildDot(i == current, pages[i].color)),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (current > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: pages[current].color, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text("Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: pages[current].color)),
                          ),
                        ),
                      if (current > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (current == pages.length - 1) {
                              Navigator.pushReplacementNamed(context, '/register');
                            } else {
                              _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pages[current].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(current == pages.length - 1 ? "Get Started" : "Next", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Icon(current == pages.length - 1 ? Icons.arrow_forward : Icons.arrow_forward_ios, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(color: data.color.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(color: data.color.withOpacity(0.2), shape: BoxShape.circle),
                child: Center(child: Icon(data.icon, size: 70, color: data.color)),
              ),
            ),
          ),
          const SizedBox(height: 50),
          Text(data.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Text(data.description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildDot(bool active, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: active ? 30 : 10,
      decoration: BoxDecoration(color: active ? color : Colors.grey[300], borderRadius: BorderRadius.circular(5)),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingData({required this.icon, required this.title, required this.description, required this.color});
}
