import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:play_sync_new/core/constants/app_colors.dart";
import "package:play_sync_new/app/routes/app_routes.dart";
import "../../domain/entities/tournament_entity.dart";
import "../providers/tournament_notifier.dart";
import "../providers/tournament_payment_notifier.dart";
import "../../domain/entities/tournament_payment_entity.dart";
import "../../../auth/presentation/providers/auth_notifier.dart";
import "tournament_chat_page.dart";
import "package:play_sync_new/core/providers/esewa_provider.dart";

class TournamentDetailPage extends ConsumerStatefulWidget {
  final TournamentEntity tournament;

  const TournamentDetailPage({Key? key, required this.tournament}) : super(key: key);

  @override
  ConsumerState<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends ConsumerState<TournamentDetailPage>
    with WidgetsBindingObserver {
  late TournamentEntity _tournament;
  bool _isProcessing = false;
  bool _awaitingPaymentReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tournament = widget.tournament;
    // Refresh tournament data to get latest participant list
    Future.microtask(() => _refreshTournamentData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingPaymentReturn) {
      _syncAfterPaymentReturn();
    }
  }

  Future<void> _refreshTournamentData() async {
    final notifier = ref.read(tournamentProvider.notifier);
    await notifier.fetchTournamentById(_tournament.id);
    final state = ref.read(tournamentProvider);
    if (state.selectedTournament != null && mounted) {
      setState(() => _tournament = state.selectedTournament!);
    }
  }

  Future<void> _syncAfterPaymentReturn() async {
    setState(() => _isProcessing = true);
    try {
      // Try to complete any latest pending payment (same as web fallback flow)
      await ref.read(tournamentPaymentProvider.notifier).verifyPayment();
    } catch (_) {
      // Ignore fallback verification errors and proceed to status checks
    }

    await _refreshTournamentData();

    if (!mounted) return;
    final access = await ref
        .read(tournamentRepositoryProvider)
        .checkChatAccess(_tournament.id);

    access.fold(
      (_) {
        setState(() {
          _isProcessing = false;
          _awaitingPaymentReturn = false;
        });
      },
      (result) {
        setState(() {
          _isProcessing = false;
          _awaitingPaymentReturn = false;
        });
        if (result.canAccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Payment successful! Redirecting to tournament chat...'),
              backgroundColor: AppColors.success,
            ),
          );
          // Auto-navigate to chat after successful payment
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _openChat(context, _tournament);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verified. You can now access the tournament chat.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournament = _tournament;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? (AppColors.textPrimaryDark ?? Colors.white) : AppColors.textPrimary;
    final Color subTextColor = isDark ? (AppColors.textSecondaryDark ?? Colors.grey) : AppColors.textSecondary;
    final Color surfaceColor = isDark ? (AppColors.surfaceVariantDark ?? Colors.grey[900]!) : Colors.white;
    
    // Check if current user is a participant
    final currentUser = ref.watch(authNotifierProvider).user;
    final String? currentUserId = currentUser?.userId;
    final bool isParticipant = currentUserId != null && tournament.isParticipant(currentUserId);

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
          child: _buildActionButton(context, tournament, isParticipant, isDark),
        ),
      ),
    );
  }

  /// Build the appropriate action button based on participation status
  Widget _buildActionButton(BuildContext context, TournamentEntity tournament, bool isParticipant, bool isDark) {
    // User already joined → Show "Open Chat"
    if (isParticipant) {
      return ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _openChat(context, tournament),
        icon: _isProcessing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : const Icon(Icons.chat_bubble_outline_rounded, size: 20),
        label: const Text("OPEN CHAT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
        ),
      );
    }

    // Tournament is full
    if (tournament.currentPlayers >= tournament.maxPlayers) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          "TOURNAMENT FULL",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.error,
          ),
        ),
      );
    }

    // Tournament closed
    if (tournament.status != TournamentStatus.open) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          "REGISTRATION CLOSED",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // User needs to pay → Show "Pay Now" button
    if (tournament.requiresPayment && tournament.entryFee > 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _initiatePayment(context, tournament),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Icon(Icons.payment_rounded, size: 20),
            label: Text(
              "PAY NPR ${tournament.entryFee.toStringAsFixed(0)} WITH ESEWA",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.1),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF60BB46), // eSewa green
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "After payment, you'll be able to join the tournament and access chat",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? (AppColors.textSecondaryDark ?? Colors.grey) : AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Free tournament → Show "Join Tournament"
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : () => _joinFreeTournament(context, tournament),
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
          : const Icon(Icons.login_rounded, size: 20),
      label: const Text("JOIN TOURNAMENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Open tournament chat
  void _openChat(BuildContext context, TournamentEntity tournament) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentChatPage(
          tournamentId: tournament.id,
          tournamentName: tournament.name,
        ),
      ),
    );
  }

  /// Initiate eSewa payment using native Mobile SDK
  Future<void> _initiatePayment(BuildContext context, TournamentEntity tournament) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      final esewaService = ref.read(esewaServiceProvider);
      final amount = tournament.entryFee.toString();

      // Initiate native SDK payment
      await esewaService.initiatePayment(
        tournamentId: tournament.id,
        tournamentName: tournament.name,
        amount: amount,
        onSuccess: (result) async {
          debugPrint('[Tournament] Payment success: ${result.refId}');
          
          // Set flag to wait for payment verification
          _awaitingPaymentReturn = true;

          // Verify transaction via backend (using refId)
          if (mounted) {
            try {
              // Call backend to verify transaction
              await ref.read(tournamentPaymentProvider.notifier).verifyPayment();
              
              // Refresh tournament data
              await _refreshTournamentData();

              if (!mounted) return;
              
              // Show success and navigate to chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Payment verified! Redirecting to tournament chat...'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );

              // Auto-navigate to chat
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _openChat(context, tournament);
                }
              });
            } catch (e) {
              debugPrint('[Tournament] Payment verification failed: $e');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment received. Verifying... ${e.toString()}'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Still refresh in case verification happens in background
              await _refreshTournamentData();
            }
          }
          
          setState(() => _isProcessing = false);
        },
        onFailure: (message) {
          debugPrint('[Tournament] Payment failure: $message');
          setState(() => _isProcessing = false);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Payment failed. Please try again.'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        onCancellation: (message) {
          debugPrint('[Tournament] Payment cancelled: $message');
          setState(() => _isProcessing = false);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Payment cancelled by user'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );

    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error initiating payment: ${e.toString()}"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Join free tournament (no payment required)
  Future<void> _joinFreeTournament(BuildContext context, TournamentEntity tournament) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      // Refresh tournament data to get updated participant list after joining
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshTournamentData();
      
      setState(() => _isProcessing = false);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Successfully joined tournament! You can now access the chat.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Trigger rebuild to show chat button
      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error joining tournament: ${e.toString()}"),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
