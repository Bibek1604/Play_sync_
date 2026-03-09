import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:play_sync_new/core/constants/app_colors.dart";
import "../../domain/entities/tournament_entity.dart";
import "../pages/tournament_detail_page.dart";
import "../../../auth/presentation/providers/auth_notifier.dart";
import "../controllers/tournament_join_controller.dart";

/// Compact tournament card styled like the profile page tiles —
/// white bg, rounded corners, left icon badge, label+value rows,
/// right chevron arrow.
class TournamentCard extends ConsumerWidget {
  final TournamentEntity tournament;
  const TournamentCard({Key? key, required this.tournament}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authNotifierProvider).user?.userId;
    final isParticipant =
        currentUserId != null && tournament.isParticipant(currentUserId);

    final (statusLabel, statusColor) = _statusStyle(tournament.status);
    final accent = _sportAccent(tournament.game);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TournamentDetailPage(tournament: tournament),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tournament name
                    Text(
                      tournament.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Meta row
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _MetaItem(
                          icon: Icons.calendar_today_rounded,
                          label: tournament.startDate != null
                              ? DateFormat("MMM d").format(tournament.startDate!)
                              : "TBD",
                        ),
                        _MetaItem(
                          icon: Icons.group_rounded,
                          label:
                              "${tournament.currentPlayers}/${tournament.maxPlayers}",
                        ),
                        _MetaItem(
                          icon: tournament.entryFee > 0
                              ? Icons.payments_rounded
                              : Icons.check_circle_outline_rounded,
                          label: tournament.entryFee > 0
                              ? "Rs. ${tournament.entryFee}"
                              : "Free",
                          color: tournament.entryFee > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Status + joined badges
                    Row(
                      children: [
                        _StatusPill(
                            label: statusLabel, color: statusColor),
                        if (isParticipant) ...[
                          const SizedBox(width: 6),
                          const _StatusPill(
                              label: "Joined",
                              color: Color(0xFF10B981)),
                        ],
                        if (tournament.prize != null &&
                            tournament.prize!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _StatusPill(
                            label: "🏆 ${tournament.prize!}",
                            color: accent,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),
if (!isParticipant && tournament.status == TournamentStatus.open)
                Consumer(
                  builder: (context, ref, _) {
                    final joinState = ref.watch(tournamentJoinControllerProvider);
                    return SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: joinState.isLoading 
                          ? null 
                          : () => ref.read(tournamentJoinControllerProvider.notifier).joinTournament(context, tournament),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: joinState.isLoading 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Join", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static (String, Color) _statusStyle(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.open:
        return ("Open", const Color(0xFF10B981));
      case TournamentStatus.ongoing:
        return ("Live", const Color(0xFF6366F1));
      case TournamentStatus.completed:
        return ("Ended", const Color(0xFF94A3B8));
      case TournamentStatus.cancelled:
        return ("Cancelled", const Color(0xFFEF4444));
      case TournamentStatus.closed:
        return ("Closed", const Color(0xFFF59E0B));
    }
  }

  static Color _sportAccent(String? game) {
    final g = (game ?? "").toLowerCase();
    if (g.contains("cricket")) return const Color(0xFF10B981);
    if (g.contains("football") || g.contains("soccer"))
      return const Color(0xFF6366F1);
    if (g.contains("basketball")) return const Color(0xFFF97316);
    if (g.contains("chess")) return const Color(0xFF64748B);
    if (g.contains("tennis")) return const Color(0xFFF59E0B);
    return AppColors.primary;
  }
}
class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
