import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/manage_page_layout.dart';

class ManagePageLayout extends StatelessWidget {
  final String title;
  final String listTitle;
  final Widget formSection;
  final Widget listSection;

  const ManagePageLayout({
    super.key,
    required this.title,
    required this.listTitle,
    required this.formSection,
    required this.listSection,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isWide
          // DESKTOP — split layout
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form section (kiri)
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: formSection,
                  ),
                ),
                const VerticalDivider(width: 1),
                // List section (kanan)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Text(
                          listTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(child: listSection),
                    ],
                  ),
                ),
              ],
            )
          // MOBILE — scroll vertikal
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  formSection,
                  const SizedBox(height: 24),
                  Text(
                    listTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 500,
                    child: listSection,
                  ),
                ],
              ),
            ),
    );
  }
}