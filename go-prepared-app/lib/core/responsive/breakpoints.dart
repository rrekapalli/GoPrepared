import 'package:flutter/material.dart';

enum AppBreakpoint { compact, medium, expanded }

class Breakpoints {
  static AppBreakpoint of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return AppBreakpoint.expanded;
    if (w >= 600) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }

  static double contentMaxWidth(BuildContext context) {
    return switch (Breakpoints.of(context)) {
      AppBreakpoint.expanded => 840,
      AppBreakpoint.medium => 720,
      AppBreakpoint.compact => double.infinity,
    };
  }
}
