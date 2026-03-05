import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:play_sync_new/app/routes/app_routes.dart";
import "package:play_sync_new/core/constants/app_colors.dart";
import "../viewmodel/profile_notifier.dart";

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileNotifierProvider.notifier).getProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    final profile = state.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && profile == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileNotifierProvider.notifier).getProfile(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(isDark, profile?.fullName ?? "Gamer", profile?.avatar),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(
                      isDark: isDark,
                      wins: profile?.wins ?? 0,
                      level: profile?.level ?? 1,
                      xp: profile?.xp ?? 0,
                    ),
                    const SizedBox(height: 28),
                    _buildSectionHeader("Account Details", isDark),
                    const SizedBox(height: 14),
                    _buildProfileTile(Icons.alternate_email_rounded, "Email Address", profile?.email ?? "-", isDark),
                    _buildProfileTile(Icons.phone_iphone_rounded, "Phone Number", profile?.phone ?? "-", isDark),
                    _buildProfileTile(Icons.location_on_outlined, "Region", profile?.place ?? "-", isDark),
                    _buildProfileTile(Icons.sports_esports_rounded, "Favorite Game", profile?.favoriteGame ?? "-", isDark),
                    const SizedBox(height: 28),
                    _buildSectionHeader("Actions", isDark),
                    const SizedBox(height: 14),
                    _buildActionTile(Icons.edit_rounded, "Edit Profile", isDark, () => Navigator.pushNamed(context, AppRoutes.settings)),
                    _buildActionTile(Icons.pin_drop_outlined, "Update Location", isDark, () => Navigator.pushNamed(context, AppRoutes.location)),
                    _buildActionTile(Icons.settings_rounded, "Preferences", isDark, () => Navigator.pushNamed(context, AppRoutes.settings)),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark, String name, String? avatarUrl) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.backgroundDark,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.backgroundDark, AppColors.surfaceDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceVariantDark,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(Icons.person_rounded, size: 56, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid({required bool isDark, required int wins, required int level, required int xp}) {
    return Row(
      children: [
        _buildCompactStat("Wins", wins.toString(), Icons.emoji_events_rounded, isDark),
        const SizedBox(width: 12),
        _buildCompactStat("Level", level.toString(), Icons.military_tech_rounded, isDark),
        const SizedBox(width: 12),
        _buildCompactStat("XP", xp.toString(), Icons.bolt_rounded, isDark),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textPrimary)),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
        color: isDark ? AppColors.primary.withOpacity(0.8) : AppColors.primary,
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        tileColor: isDark ? AppColors.surfaceDark : Colors.white,
        leading: Icon(icon, color: isDark ? Colors.white : AppColors.textPrimary, size: 21),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
      ),
    );
  }
}
