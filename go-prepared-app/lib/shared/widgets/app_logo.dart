import 'package:flutter/material.dart';

import '../../core/theme/app_assets.dart';

/// GoPrepared launcher mark for headers, profile, and splash-style layouts.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.borderRadius,
  });

  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        AppAssets.logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'GoPrepared',
      ),
    );
  }
}
