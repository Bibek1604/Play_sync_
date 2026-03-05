import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:play_sync_new/core/constants/app_colors.dart";
import "../../domain/entities/tournament_entity.dart";
import "../pages/tournament_detail_page.dart";

class TournamentCard extends ConsumerWidget {
  final TournamentEntity tournament;

  const TournamentCard({Key? key, required this.tournament}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Safety check for AppColors constants
    final Color cardBackground = isDark ? (AppColors.surfaceDark ?? Colors.grey[900]!) : Colors.white;
    final Color textColor = isDark ? (AppColors.textPrimaryDark ?? Colors.white) : AppColors.textPrimary;
    final Color subTextColor = isDark ? (AppColors.textSecondaryDark ?? Colors.grey) : AppColors.textSecondary;
    
    final Color statusColor;
    final String statusText;
    
    switch (tournament.status) {
      case TournamentStatus.open:
        statusColor = AppColors.primary;
        statusText = "Open";
        break;
      case TournamentStatus.ongoing:
        statusColor = AppColors.success;
        statusText = "Ongoing";
        break;
      case TournamentStatus.completed:
        statusColor = AppColors.textSecondary;
        statusText = "Completed";
        break;
      case TournamentStatus.closed:
        statusColor = AppColors.error;
        statusText = "Closed";
        break;
      case TournamentStatus.cancelled:
        statusColor = AppColors.textSecondary;
        statusText = "Cancelled";
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentDetailPage(tournament: tournament),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? (AppColors.borderDark ?? Colors.grey[800]!) : AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Header Section
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: Center(child: Icon(Icons.emoji_events_outlined, size: 48, color: AppColors.primary.withOpacity(0.5))),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${tournament.currentPlayers}/${tournament.maxPlayers}",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: subTextColor),
                      const SizedBox(width: 6),
                      Text(
                        tournament.startDate != null 
                          ? DateFormat("MMM dd, yyyy").format(tournament.startDate!)
                          : "TBD",
                        style: TextStyle(fontSize: 13, color: subTextColor),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.sports_esports_outlined, size: 14, color: subTextColor),
                      const SizedBox(width: 6),
                      Text(
                        tournament.game ?? "Various",
                        style: TextStyle(fontSize: 13, color: subTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Prize",
                              style: TextStyle(fontSize: 10, color: subTextColor, letterSpacing: 0.5),
                            ),
                            Text(
                              tournament.prize ?? "Trophy",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Join",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
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
}
