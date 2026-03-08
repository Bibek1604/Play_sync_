import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../profile/presentation/viewmodel/profile_notifier.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import '../widgets/create_game_sheet.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/game_entity.dart';
import 'game_detail_page.dart';
import '../../../chat/presentation/providers/chat_notifier.dart';

/// Filter options for offline games
enum OfflineFilter { all, nearby, open, myGames }

/// Offline Games — organized with filter tabs.
class OfflineGamesPage extends ConsumerStatefulWidget {
  const OfflineGamesPage({super.key});

  @override
  ConsumerState<OfflineGamesPage> createState() => _OfflineGamesPageState();
}

class _OfflineGamesPageState extends ConsumerState<OfflineGamesPage> {
  OfflineFilter _selectedFilter = OfflineFilter.all;
  bool _locationEnabled = false;
  bool _enablingLocation = false;
  String? _locationError;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    // Load joined/created game lists so we can detect already-joined games
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).setCategoryFilter('OFFLINE');
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();

      // Auto-trigger location detection for offline games
      _enableLocationBasedGames();
    });
  }

  @override
  void dispose() {
    ref.read(gameProvider.notifier).clearLocationFilter();
    super.dispose();
  }

  Future<void> _enableLocationBasedGames() async {
    if (_enablingLocation) return;

    if (!mounted) return;
    setState(() {
      _enablingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location access is required to see offline games near you.';
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint('[LOCATION] High accuracy failed or timed out, trying medium: $e');
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      }

      if (!mounted) return;

      if (position == null) {
        throw Exception('Could not determine your location. Please try again.');
      }

      setState(() {
        _locationEnabled = true;
        _userLat = position!.latitude;
        _userLng = position!.longitude;
      });

      await ref
          .read(gameProvider.notifier)
          .fetchOfflineGamesNearby(
            latitude: position!.latitude,
            longitude: position!.longitude,
            radius: 10,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationEnabled = false;
        _locationError = e.toString();
        _userLat = null;
        _userLng = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _enablingLocation = false;
      });
    }
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateGameSheet(isOnlineMode: false),
    );
  }

  List<GameEntity> _getFilteredGames(
    List<GameEntity> allOfflineGames,
    String? userId,
  ) {
    switch (_selectedFilter) {
      case OfflineFilter.all:
      case OfflineFilter.nearby:
        return allOfflineGames;
      case OfflineFilter.open:
        return allOfflineGames.where((g) => g.isOpen).toList();
      case OfflineFilter.myGames:
        if (userId == null) return [];
        return allOfflineGames
            .where((g) => g.isCreator(userId) || g.isParticipant(userId))
            .toList();
    }
  }

  Future<void> _refreshData() async {
    if (_selectedFilter == OfflineFilter.nearby &&
        _locationEnabled &&
        _userLat != null) {
      await _enableLocationBasedGames();
    } else {
      await Future.wait([
        ref.read(gameProvider.notifier).fetchGames(refresh: true),
        ref.read(gameProvider.notifier).fetchMyJoinedGames(),
        ref.read(gameProvider.notifier).fetchMyCreatedGames(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.userId;

    final allOfflineGames = () {
      final Set<String> allIds = {};
      final list = <GameEntity>[];
      for (final g in state.games) {
        if (g.category == 'OFFLINE' &&
            !allIds.contains(g.id) &&
            g.status != GameStatus.ENDED) {
          list.add(g);
          allIds.add(g.id);
        }
      }
      for (final g in state.myCreatedGames) {
        if (g.category == 'OFFLINE' &&
            !allIds.contains(g.id) &&
            g.status != GameStatus.ENDED) {
          list.add(g);
          allIds.add(g.id);
        }
      }
      for (final g in state.myJoinedGames) {
        if (g.category == 'OFFLINE' &&
            !allIds.contains(g.id) &&
            g.status != GameStatus.ENDED) {
          list.add(g);
          allIds.add(g.id);
        }
      }
      return list;
    }();

    final filteredGames = _locationEnabled && _userLat != null && _userLng != null
        ? _getFilteredGames(
            allOfflineGames.where((g) {
              if (g.location != null) {
                final distance = Geolocator.distanceBetween(
                  _userLat!,
                  _userLng!,
                  g.location!.latitude,
                  g.location!.longitude,
                );
                return distance <= 10000;
              }
              return false;
            }).toList(),
            currentUserId,
          )
        : _getFilteredGames(allOfflineGames, currentUserId);

    final joinedGameIds = <String>{
      ...state.myJoinedGames.map((g) => g.id),
      ...state.myCreatedGames.map((g) => g.id),
    };
    final createdGameIds = <String>{...state.myCreatedGames.map((g) => g.id)};

    Future<void> doAction(
      Future<bool> Function() action,
      String successMsg,
      String failKey,
    ) async {
      final ok = await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? successMsg : (ref.read(gameProvider).error ?? failKey),
          ),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    Future<void> confirmDelete(String gameId) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Game'),
          content: const Text(
            'Are you sure you want to permanently delete this game? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await doAction(
          () => ref.read(gameProvider.notifier).deleteGame(gameId),
          'Game deleted',
          'Failed to delete game',
        );
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      drawer: const AppDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: const Color(0xFF0284C7),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/pattern_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                  Positioned(
                    top: 55,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 65),
              title: const Text(
                'Local Games',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -1.0,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: _enablingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _locationEnabled
                            ? Icons.my_location_rounded
                            : Icons.location_disabled_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                onPressed: _enablingLocation
                    ? null
                    : () {
                        if (_locationEnabled) {
                          setState(() {
                            _locationEnabled = false;
                            _userLat = null;
                            _userLng = null;
                            _locationError = null;
                          });
                          ref.read(gameProvider.notifier).clearLocationFilter();
                        } else {
                          _enableLocationBasedGames();
                        }
                      },
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _refreshData,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        count: allOfflineGames.length,
                        isSelected: _selectedFilter == OfflineFilter.all,
                        onTap: () {
                          if (_selectedFilter == OfflineFilter.all) return;
                          setState(() => _selectedFilter = OfflineFilter.all);
                          ref.read(gameProvider.notifier).clearLocationFilter();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Nearby',
                        count: allOfflineGames.where((g) {
                          if (_userLat != null && _userLng != null && g.location != null) {
                            final d = Geolocator.distanceBetween(_userLat!, _userLng!, g.location!.latitude, g.location!.longitude);
                            return d <= 10000;
                          }
                          return false;
                        }).length,
                        isSelected: _selectedFilter == OfflineFilter.nearby,
                        onTap: () {
                          if (_selectedFilter == OfflineFilter.nearby) return;
                          setState(() => _selectedFilter = OfflineFilter.nearby);
                          if (!_locationEnabled) {
                            _enableLocationBasedGames();
                          } else {
                             // Location already on, just refresh for nearby
                             _refreshData();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Open',
                        count: allOfflineGames.where((g) => g.isOpen).length,
                        isSelected: _selectedFilter == OfflineFilter.open,
                        onTap: () => setState(
                          () => _selectedFilter = OfflineFilter.open,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'My Games',
                        count: currentUserId != null
                            ? allOfflineGames
                                .where(
                                  (g) =>
                                      g.isCreator(currentUserId) ||
                                      g.isParticipant(currentUserId),
                                )
                                .length
                            : 0,
                        isSelected: _selectedFilter == OfflineFilter.myGames,
                        onTap: () => setState(
                          () => _selectedFilter = OfflineFilter.myGames,
                        ),
                      ),
                      if (_locationEnabled && !_enablingLocation) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withOpacity(0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.radar_rounded,
                                size: 12,
                                color: Color(0xFF0284C7),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '10km Radius',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Container(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          child: state.isLoading && allOfflineGames.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : (_selectedFilter == OfflineFilter.nearby && !_locationEnabled)
                  ? _LocationAccessState(
                      isLoading: _enablingLocation,
                      error: _locationError,
                      onEnable: _enableLocationBasedGames,
                    )
                  : filteredGames.isEmpty
                      ? _EmptyState(
                          filter: _selectedFilter,
                          onCreateTap: () => _showCreateSheet(context),
                          onShowAll: () =>
                              setState(() => _selectedFilter = OfflineFilter.all),
                        )
                      : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _refreshData,
                      child: ListView.separated(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        itemCount: filteredGames.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) {
                          final game = filteredGames[i];
                          final isAlreadyJoined = currentUserId != null &&
                              (joinedGameIds.contains(game.id) ||
                                  game.isCreator(currentUserId) ||
                                  game.isParticipant(currentUserId));
                          final isAlreadyCreator = createdGameIds
                                  .contains(game.id) ||
                              (currentUserId != null &&
                                  game.isCreator(currentUserId));
                          return GameCard(
                            game: game,
                            currentUserId: currentUserId,
                            isAlreadyJoined: isAlreadyJoined,
                            isAlreadyCreator: isAlreadyCreator,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GameDetailPage(
                                  gameId: game.id,
                                  preloadedGame: game,
                                ),
                              ),
                            ),
                            onJoin: () => doAction(
                              () async {
                                final result = await ref
                                    .read(gameProvider.notifier)
                                    .joinGame(game.id);
                                return result != null;
                              },
                              'Joined game!',
                              'Failed to join',
                            ),
                            onLeave: () => doAction(
                              () async {
                                final result = await ref
                                    .read(gameProvider.notifier)
                                    .leaveGame(game.id);
                                if (result != null) {
                                  ref
                                      .read(chatProvider.notifier)
                                      .leaveRoom(game.id);
                                }
                                return result != null;
                              },
                              'Left game',
                              'Failed to leave',
                            ),
                            onCancel: () => doAction(
                              () async {
                                final result = await ref
                                    .read(gameProvider.notifier)
                                    .cancelGame(game.id);
                                return result != null;
                              },
                              'Game cancelled',
                              'Failed to cancel',
                            ),
                            onDelete: isAlreadyCreator
                                ? () => confirmDelete(game.id)
                                : null,
                          );
                        },
                      ),
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Create Game',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationAccessState extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onEnable;

  const _LocationAccessState({
    required this.isLoading,
    required this.error,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 52,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Enable location to see offline games within 10 km.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (error != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ],
            SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onEnable,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                isLoading ? 'Detecting location...' : 'Enable Location',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final OfflineFilter filter;
  final VoidCallback onCreateTap;
  final VoidCallback onShowAll;

  const _EmptyState({
    required this.filter,
    required this.onCreateTap,
    required this.onShowAll,
  });

  String get _title => switch (filter) {
    OfflineFilter.all => 'No Offline Games Yet',
    OfflineFilter.nearby => 'No Games Nearby',
    OfflineFilter.open => 'No Open Games',
    OfflineFilter.myGames => 'No Games You\'re Part Of',
  };

  String get _subtitle => switch (filter) {
    OfflineFilter.all =>
      'Organise a local match and meet\nplayers in your area!',
    OfflineFilter.nearby =>
      'Search for games within 10km or\ncreate your own local game!',
    OfflineFilter.open =>
      'All games are either full or ended.\nCreate a new one!',
    OfflineFilter.myGames => 'Join a game or create your own\nto see it here.',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xxl),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                filter == OfflineFilter.myGames
                    ? Icons.person_outline_rounded
                    : Icons.sports_rounded,
                size: 56,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              _title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            if (filter != OfflineFilter.all) ...[
              OutlinedButton(
                onPressed: onShowAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text(
                  'Show All Games',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: AppSpacing.md),
            ],
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create Offline Game',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md + 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
