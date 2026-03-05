import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:play_sync_new/core/constants/app_colors.dart";
import "../../domain/entities/tournament_entity.dart";

class TournamentDetailPage extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const TournamentDetailPage({Key? key, required this.tournament}) : super(key: key);

  @override
  ConsumerState<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends ConsumerState<TournamentDetailPage> {
  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? (AppColors.textPrimaryDark ?? Colors.white) : AppColors.textPrimary;
    final Color subTextColor = isDark ? (AppColors.textSecondaryDark ?? Colors.grey) : AppColors.textSecondary;
    final Color surfaceColor = isDark ? (AppColors.surfaceVariantDark ?? Colors.grey[900]!) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Banner Section
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary.withOpacity(0.1), 
                child: Icon(Icons.emoji_events, size: 80, color: AppColors.primary.withOpacity(0.5))
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tournament.game ?? "Various",
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Key Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem("Prize", tournament.prize ?? "Trophy", Icons.emoji_events, isDark),
                      _buildStatItem("Players", "${tournament.currentPlayers}/${tournament.maxPlayers}", Icons.people_alt, isDark),
                      _buildStatItem("Entry Fee", tournament.entryFee == 0 ? "Free" : "NPR ${tournament.entryFee}", Icons.confirmation_number, isDark),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Event Schedule Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? (AppColors.borderDark ?? Colors.grey[800]!) : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("EVENT SCHEDULE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: subTextColor, letterSpacing: 0.8)),
                        const SizedBox(height: 16),
                        _buildScheduleItem(
                          "Starting Date", 
                          tournament.startDate != null ? DateFormat("MMMM dd, yyyy").format(tournament.startDate!) : "To Be Decided", 
                          Icons.calendar_today, 
                          isDark
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        _buildScheduleItem("Type", tournament.type.toUpperCase(), Icons.layers_outlined, isDark),
                        const Divider(height: 24, thickness: 0.5),
                        _buildScheduleItem("Platform", "Online / Local", Icons.monitor, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Description
                  Text("ABOUT TOURNAMENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: subTextColor, letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  Text(
                    tournament.description ?? "This tournament is open to all skill levels. Join us for a competitive and fun environment where you can showcase your gaming skills and win amazing prizes. Rules will be shared upon registration.",
                    style: TextStyle(fontSize: 15, color: subTextColor, height: 1.6),
                  ),
                  const SizedBox(height: 100), // Spacing for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Registration requested!")),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: AppColors.primary,
            ),
            child: const Text("JOIN TOURNAMENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? (AppColors.textSecondaryDark ?? Colors.grey) : AppColors.textSecondary, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildScheduleItem(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? (AppColors.textSecondaryDark ?? Colors.grey) : AppColors.textSecondary)),
            Text(value, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
