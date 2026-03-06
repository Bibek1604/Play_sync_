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
    final Color primaryColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF0284C7);
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    if (state.isLoading && profile == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? null : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF0F9FF)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => ref.read(profileNotifierProvider.notifier).getProfile(),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(isDark, profile?.fullName ?? "Gamer", profile?.avatar, primaryColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(
                        isDark: isDark,
                        wins: profile?.wins ?? 0,
                        level: profile?.level ?? 1,
                        xp: profile?.xp ?? 0,
                        primaryColor: primaryColor,
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
      ),
    );
  }

  Widget _buildAppBar(bool isDark, String name, String? avatarUrl, Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image / Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1E40AF)] 
                    : [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
                ),
              ),
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/pattern_bg.png', // Fallback pattern or generic sport pattern
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
            // Bottom Gradient Overlay for name readability
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
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar with premium border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white24,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(Icons.person_rounded, size: 60, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 14, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        "PREMIUM GAMER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid({required bool isDark, required int wins, required int level, required int xp, required Color primaryColor}) {
    return Row(
      children: [
        _buildCompactStat("Wins", wins.toString(), Icons.emoji_events_rounded, isDark, const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _buildCompactStat("Level", level.toString(), Icons.military_tech_rounded, isDark, primaryColor),
        const SizedBox(width: 12),
        _buildCompactStat("XP", xp.toString(), Icons.bolt_rounded, isDark, const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, IconData icon, bool isDark, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textPrimary, letterSpacing: -0.5)),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(), 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w700, 
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title, 
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary, 
                    fontWeight: FontWeight.w700, 
                    fontSize: 15,
                    letterSpacing: -0.2,
                  )
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
