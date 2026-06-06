import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class CommonPageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Color headerColor;
  final Widget? floatingActionButton;

  const CommonPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions,
    this.headerColor = AppColors.primary,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final headerPadding = Responsive.value(
      context,
      mobile: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      tablet: const EdgeInsets.fromLTRB(28, 20, 28, 24),
      desktop: const EdgeInsets.fromLTRB(32, 24, 32, 28),
    );

    return Scaffold(
      backgroundColor: headerColor,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColor, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            padding: headerPadding,
            child: SafeArea(
              bottom: false,
              child: ResponsiveContent(
                padding: EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: Responsive.value(
                                context,
                                mobile: 24.0,
                                tablet: 28.0,
                                desktop: 32.0,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (actions != null) Row(children: actions!),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.surface,
              child: ResponsiveContent(
                padding: Responsive.pagePadding(context),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
