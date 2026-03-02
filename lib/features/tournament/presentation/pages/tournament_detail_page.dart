import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_payment_entity.dart';
import '../providers/tournament_notifier.dart';
import '../providers/tournament_payment_notifier.dart';

/// Detailed view of a single tournament with join / pay / chat actions.
class TournamentDetailPage extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailPage({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailPage> createState() =>
      _TournamentDetailPageState();
}

class _TournamentDetailPageState extends ConsumerState<TournamentDetailPage> {
  @override
  void initState() {
    super.initState();
    // Fetch fresh data
    Future.microtask(() {
      ref.read(tournamentProvider.notifier).fetchTournamentById(widget.tournamentId);
      ref.read(tournamentPaymentProvider.notifier).checkPaymentStatus(widget.tournamentId);
    });
  }

  String? get _currentUserId =>
      ref.read(authNotifierProvider).user?.userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tState = ref.watch(tournamentProvider);
    final pState = ref.watch(tournamentPaymentProvider);
    final tournament = tState.selectedTournament;

    return Scaffold(
      appBar: AppBar(
        title: Text(tournament?.name ?? 'Tournament'),
        actions: [
          if (tournament != null &&
              _currentUserId != null &&
              tournament.isCreator(_currentUserId!))
            PopupMenuButton<String>(
              onSelected: (v) => _onCreatorAction(v, tournament),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'payments', child: Text('View Payments')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      body: tState.isLoading && tournament == null
          ? const Center(child: CircularProgressIndicator())
          : tState.error != null && tournament == null
              ? _buildError(tState.error!)
              : tournament == null
                  ? const Center(child: Text('Tournament not found'))
                  : _buildBody(tournament, pState, theme),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ref
                .read(tournamentProvider.notifier)
                .fetchTournamentById(widget.tournamentId),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    TournamentEntity t,
    TournamentPaymentState pState,
    ThemeData theme,
  ) {
    final df = DateFormat('MMM d, yyyy • h:mm a');
    final isCreator = _currentUserId != null && t.isCreator(_currentUserId!);
    final isParticipant = _currentUserId != null && t.isParticipant(_currentUserId!);
    final isPaid = pState.lastPayment?.status == PaymentStatus.success;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(tournamentProvider.notifier)
            .fetchTournamentById(widget.tournamentId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ────────────────────────────────────────────────────
          Text(t.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (t.description != null)
            Text(t.description!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 16),

          // ── Info Grid ─────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(label: 'Status', value: t.status.name.toUpperCase()),
                  _DetailRow(label: 'Type', value: t.type),
                  _DetailRow(label: 'Players', value: '${t.currentPlayers} / ${t.maxPlayers}'),
                  if (t.entryFee > 0)
                    _DetailRow(label: 'Entry Fee', value: 'Rs. ${t.entryFee}'),
                  if (t.prize != null)
                    _DetailRow(label: 'Prize', value: t.prize!),
                  if (t.startDate != null)
                    _DetailRow(label: 'Start', value: df.format(t.startDate!)),
                  if (t.endDate != null)
                    _DetailRow(label: 'End', value: df.format(t.endDate!)),
                  if (t.game != null)
                    _DetailRow(label: 'Game', value: t.game!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Rules ─────────────────────────────────────────────────────
          if (t.rules != null && t.rules!.isNotEmpty) ...[
            Text('Rules', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t.rules!, style: theme.textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Participants ──────────────────────────────────────────────
          Text('Participants (${t.participants.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (t.participants.isEmpty)
            const Card(child: ListTile(title: Text('No participants yet')))
          else
            Card(
              child: Column(
                children: t.participants
                    .take(10)
                    .map((p) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: p.avatar != null
                                ? NetworkImage(p.avatar!)
                                : null,
                            child: p.avatar == null
                                ? Text((p.fullName ?? '?')[0].toUpperCase())
                                : null,
                          ),
                          title: Text(p.fullName ?? 'Participant'),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),

          // ── Action Buttons ────────────────────────────────────────────
          _buildActions(t, isCreator, isParticipant, isPaid, pState),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActions(
    TournamentEntity t,
    bool isCreator,
    bool isParticipant,
    bool isPaid,
    TournamentPaymentState pState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Join via payment
        if (!isCreator &&
            !isParticipant &&
            t.requiresPayment &&
            t.isJoinable) ...[
          FilledButton.icon(
            onPressed: pState.flowStatus == PaymentFlowStatus.initiating
                ? null
                : () => _initiatePayment(),
            icon: const Icon(Icons.payment),
            label: Text(
              pState.flowStatus == PaymentFlowStatus.initiating
                  ? 'Processing...'
                  : 'Pay & Join (Rs. ${t.entryFee})',
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Free join (no entry fee)
        if (!isCreator &&
            !isParticipant &&
            !t.requiresPayment &&
            t.isJoinable)
          FilledButton.icon(
            onPressed: () {}, // TODO: implement free join
            icon: const Icon(Icons.person_add),
            label: const Text('Join Tournament'),
          ),

        // Chat access (for paid / creator / free tournaments)
        if ((isCreator || isParticipant || isPaid) &&
            t.status != TournamentStatus.cancelled) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.tournamentChat,
              arguments: {
                'tournamentId': t.id,
                'tournamentName': t.name,
              },
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Tournament Chat'),
          ),
        ],

        // Payment status message
        if (pState.flowStatus == PaymentFlowStatus.success) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('Payment successful! You can now access the chat.'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _initiatePayment() async {
    final notifier = ref.read(tournamentPaymentProvider.notifier);
    await notifier.initiatePayment(widget.tournamentId);

    if (!mounted) return;
    final pState = ref.read(tournamentPaymentProvider);

    if (pState.flowStatus == PaymentFlowStatus.awaitingPayment &&
        pState.paymentInitiation != null) {
      // Navigate to eSewa WebView
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.esewaPayment,
        arguments: {
          'paymentUrl': pState.paymentInitiation!.paymentUrl,
          'params': pState.paymentInitiation!.params,
          'tournamentId': widget.tournamentId,
        },
      );

      // result is the base64 data from eSewa callback
      if (result is String && result.isNotEmpty) {
        await notifier.verifyPayment(result);
        if (mounted) {
          ref.read(tournamentProvider.notifier).fetchTournamentById(widget.tournamentId);
        }
      }
    }
  }

  void _onCreatorAction(String action, TournamentEntity tournament) async {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          AppRoutes.tournamentCreate,
          arguments: {'tournament': tournament},
        );
        break;
      case 'payments':
        Navigator.pushNamed(
          context,
          AppRoutes.tournamentPayments,
          arguments: {'tournamentId': tournament.id},
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Tournament?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          final success =
              await ref.read(tournamentProvider.notifier).deleteTournament(tournament.id);
          if (success && mounted) Navigator.pop(context);
        }
        break;
    }
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
