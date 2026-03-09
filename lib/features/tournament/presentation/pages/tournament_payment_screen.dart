import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/widgets/back_button_widget.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_payment_entity.dart';
import '../providers/tournament_payment_notifier.dart';

/// Modern payment screen for tournament entry fee
/// Displays tournament details and initiates eSewa payment
/// Arguments:
/// - `tournament` (TournamentEntity) - Tournament to pay for
class TournamentPaymentScreen extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const TournamentPaymentScreen({
    super.key,
    required this.tournament,
  });

  @override
  ConsumerState<TournamentPaymentScreen> createState() =>
      _TournamentPaymentScreenState();
}

class _TournamentPaymentScreenState
    extends ConsumerState<TournamentPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentState = ref.watch(tournamentPaymentProvider);

    // Listen for payment state changes
    ref.listen<TournamentPaymentState>(
      tournamentPaymentProvider,
      (previous, next) {
        if (next.flowStatus == PaymentFlowStatus.awaitingPayment &&
            next.paymentInitiation != null) {
          _navigateToEsewaPayment(next.paymentInitiation!);
        } else if (next.flowStatus == PaymentFlowStatus.failed &&
            next.error != null) {
          _showErrorSnackbar(next.error!);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: BackButtonWidget(label: 'Back'),
        ),
        leadingWidth: 100,
        title: const Text('Tournament Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
_buildHeader(theme),
              const SizedBox(height: 24),
_buildTournamentDetails(theme),
              const SizedBox(height: 20),
_buildPaymentSummary(theme),
              const SizedBox(height: 32),
_buildPayButton(paymentState),
              const SizedBox(height: 16),
_buildSecurityNotice(theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60BB46), Color(0xFF4A9635)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60BB46).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_esports,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Tournament',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete payment to participate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentDetails(ThemeData theme) {
    final t = widget.tournament;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tournament Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _DetailItem(
              icon: Icons.emoji_events,
              label: 'Tournament Name',
              value: t.name,
              iconColor: const Color(0xFFFFB300),
            ),
            if (t.game != null) ...[
              const SizedBox(height: 12),
              _DetailItem(
                icon: Icons.gamepad,
                label: 'Game',
                value: t.game!,
                iconColor: const Color(0xFF7C4DFF),
              ),
            ],
            if (t.startDate != null) ...[
              const SizedBox(height: 12),
              _DetailItem(
                icon: Icons.calendar_today,
                label: 'Tournament Date',
                value: dateFormat.format(t.startDate!),
                iconColor: const Color(0xFF2196F3),
              ),
            ],
            const SizedBox(height: 12),
            _DetailItem(
              icon: Icons.people,
              label: 'Participants',
              value: '${t.currentPlayers} / ${t.maxPlayers}',
              iconColor: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 12),
            _DetailItem(
              icon: Icons.category,
              label: 'Type',
              value: t.type.toUpperCase(),
              iconColor: const Color(0xFFFF5722),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    final entryFee = widget.tournament.entryFee;

    return Card(
      elevation: 2,
      color: AppColors.primaryLight.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Entry Fee', 'NPR ${entryFee.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Amount',
              'NPR ${entryFee.toStringAsFixed(2)}',
              isBold: true,
              valueColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(TournamentPaymentState paymentState) {
    final isProcessing = paymentState.flowStatus == PaymentFlowStatus.initiating;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF60BB46), // eSewa green
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF60BB46).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/p.svg',
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pay with eSewa',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your payment is processed securely through eSewa. PlaySync does not store your payment information.',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
Future<void> _initiatePayment() async {
    final notifier = ref.read(tournamentPaymentProvider.notifier);
    await notifier.initiatePayment(widget.tournament.id);
  }

  Future<void> _navigateToEsewaPayment(PaymentInitiation initiation) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.esewaPayment,
      arguments: {
        'paymentUrl': initiation.paymentUrl,
        'params': initiation.params,
        'tournamentId': widget.tournament.id,
      },
    );

    if (!mounted) return;

    if (result != null && result is String) {
      // User completed payment on eSewa, verify it
      final notifier = ref.read(tournamentPaymentProvider.notifier);
      await notifier.verifyPayment(result);

      // Navigate based on result
      if (!mounted) return;
      final paymentState = ref.read(tournamentPaymentProvider);

      if (paymentState.flowStatus == PaymentFlowStatus.success &&
          paymentState.lastPayment != null) {
        // Save payment locally
        await PaymentService.savePaymentStatus(
          tournamentId: widget.tournament.id,
          payment: paymentState.lastPayment!,
        );

        // Navigate to success screen
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.paymentSuccess,
            arguments: {
              'tournament': widget.tournament,
              'payment': paymentState.lastPayment,
            },
          );
        }
      } else if (paymentState.flowStatus == PaymentFlowStatus.failed) {
        // Navigate to failure screen
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.paymentFailed,
            arguments: {
              'tournament': widget.tournament,
              'error': paymentState.error ?? 'Payment verification failed',
            },
          );
        }
      }
    } else {
      // User cancelled payment
      _showErrorSnackbar('Payment cancelled');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
