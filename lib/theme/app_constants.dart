

library;

import 'package:flutter/material.dart';


class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}


class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 100.0;


  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(xl));
}


class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);
}


class AppIconSize {
  AppIconSize._();

  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
  static const double xxxl = 80.0;
}


class AppElevation {
  AppElevation._();

  static const double none = 0.0;
  static const double sm = 1.0;
  static const double md = 2.0;
  static const double lg = 4.0;
  static const double xl = 8.0;
}


class AppPadding {
  AppPadding._();


  static const EdgeInsets xs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets sm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets md = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets lg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets xl = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets xxl = EdgeInsets.all(AppSpacing.xxl);


  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: AppSpacing.md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: AppSpacing.xl);


  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: AppSpacing.sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: AppSpacing.md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: AppSpacing.lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: AppSpacing.xl);


  static const EdgeInsets screen = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets screenLarge = EdgeInsets.all(AppSpacing.lg);


  static const EdgeInsets card = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.md,
  );
}


class AppConstraints {
  AppConstraints._();

  static const double maxContentWidth = 800.0;
  static const double minTouchTarget = 48.0;
  static const double inputFieldHeight = 56.0;
  static const double buttonHeight = 48.0;
}
