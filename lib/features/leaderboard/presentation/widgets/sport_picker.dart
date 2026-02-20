import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Horizontal chip row for selecting sport type filter on leaderboard.
class SportPicker extends StatelessWidget {
  final String? selectedSport;
  final void Function(String?) onChanged;

  static const _sports = ['All', 'Football', 'Basketball', 'Cricket', 'Tennis', 'Badminton', 'Volleyball'];

  const SportPicker({super.key, this.selectedSport, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sports.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final sport = _sports[i];
          final isSelected = (sport == 'All' && selectedSport == null) || selectedSport == sport;
          return ChoiceChip(
            label: Text(sport),
            selected: isSelected,
            selectedColor: AppColors.emerald500.withValues(alpha: 0.2),
            onSelected: (_) => onChanged(sport == 'All' ? null : sport),
          );
        },
      ),
    );
  }
}
