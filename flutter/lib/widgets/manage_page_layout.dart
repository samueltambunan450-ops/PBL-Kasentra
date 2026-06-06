import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class ManagePageLayout extends StatelessWidget {
  final String title;
  final Widget formSection;
  final Widget listSection;
  final String listTitle;

  const ManagePageLayout({
    super.key,
    required this.title,
    required this.formSection,
    required this.listSection,
    required this.listTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.useSideNav(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.surface,
      body: ResponsiveContent(
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: _sectionCard(context, formSection),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: _sectionCard(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: listSection),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(context, formSection),
                  const SizedBox(height: 16),
                  Text(listTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Expanded(child: listSection),
                ],
              ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, Widget child) {
    return Card(
      child: Padding(
        padding: Responsive.pagePadding(context).copyWith(top: 20, bottom: 20),
        child: child,
      ),
    );
  }
}
