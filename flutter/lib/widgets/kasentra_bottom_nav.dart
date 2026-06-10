import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KasentraNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const KasentraNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class KasentraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<KasentraNavDestination> destinations;
  final int fabIndex;

  const KasentraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.fabIndex = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(destinations.length, (index) {
              if (index == fabIndex) {
                return Expanded(child: _buildFab(context));
              }
              return Expanded(child: _buildItem(index));
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    final selected = currentIndex == fabIndex;
    return GestureDetector(
      onTap: () => onDestinationSelected(fabIndex),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryDark : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            destinations[fabIndex].label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final dest = destinations[index];
    final selected = currentIndex == index;

    return GestureDetector(
      onTap: () => onDestinationSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? dest.selectedIcon : dest.icon,
            size: 22,
            color: selected ? AppColors.primary : Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          Text(
            dest.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
