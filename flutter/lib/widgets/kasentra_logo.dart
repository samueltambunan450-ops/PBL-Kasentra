import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KasentraLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const KasentraLogo({
    super.key,
    this.size = 72,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: size * 0.48,
            color: AppColors.primary,
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          Text(
            'KASENTRA',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: textColor ?? AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sistem Keuangan UMKM',
            style: TextStyle(
              fontSize: size * 0.14,
              color: (textColor ?? AppColors.primaryDark).withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
