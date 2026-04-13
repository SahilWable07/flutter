import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;   // Base 8px grid
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Spacing helper for Padding/Margin
  static const EdgeInsets pSmall = EdgeInsets.all(s);
  static const EdgeInsets pMedium = EdgeInsets.all(m);
  static const EdgeInsets pLarge = EdgeInsets.all(l);
  
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 16.0;
  static const double borderRadiusL = 24.0;
  static const double borderRadiusXL = 32.0;
}
