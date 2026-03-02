import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/tournament_payment_entity.dart';
import '../providers/tournament_payment_notifier.dart';

/// Shows payment records for a specific tournament (for creators/admins).
class TournamentPaymentsPage extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentPaymentsPage({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentPaymentsPage> createState() =>
      _TournamentPaymentsPageState();
}

class _TournamentPaymentsPageState
    extends ConsumerState<TournamentPaymentsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(tournamentPaymentProvider.notifier)
          .fetchTournamentPayments(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentPaymentProvider);
    final df = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Payments')),
      body: state.tournamentPayments.isEmpty
          ? const Center(child: Text('No payments found'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.tournamentPayments.length,
              itemBuilder: (context, index) {
                final payment = state.tournamentPayments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(payment.status),
                      child: Icon(
                        _statusIcon(payment.status),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      payment.payerId?.fullName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rs. ${payment.amount}'),
                        if (payment.paidAt != null)
                          Text(df.format(payment.paidAt!),
                              style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    trailing: _PaymentStatusChip(status: payment.status),
                  ),
                );
              },
            ),
    );
  }

  Color _statusColor(PaymentStatus status) => switch (status) {
        PaymentStatus.success => Colors.green,
        PaymentStatus.pending => Colors.orange,
        PaymentStatus.failed => Colors.red,
      };

  IconData _statusIcon(PaymentStatus status) => switch (status) {
        PaymentStatus.success => Icons.check,
        PaymentStatus.pending => Icons.hourglass_empty,
        PaymentStatus.failed => Icons.close,
      };
}

class _PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;
  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      PaymentStatus.success => (Colors.green.shade100, Colors.green.shade800),
      PaymentStatus.pending => (Colors.orange.shade100, Colors.orange.shade800),
      PaymentStatus.failed => (Colors.red.shade100, Colors.red.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
