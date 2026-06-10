import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'kasentra_bottom_nav.dart';

class AdaptiveDashboardScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> pages;
  final List<KasentraNavDestination> destinations;
  final int fabIndex;

  const AdaptiveDashboardScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.pages,
    required this.destinations,
    this.fabIndex = 2,
  });

  @override
  Widget build(BuildContext context) {
    final useSideNav = Responsive.useSideNav(context);

    if (useSideNav) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: KasentraBottomNav(
        currentIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        fabIndex: fabIndex,
      ),
    );
  }
}
