import 'package:flutter/material.dart';

class AppFontSize {
  AppFontSize._();

  // Base sizes (designed for ~400px wide phone)
  static const double tiny = 9.5;     // tagline
  static const double xs = 10.5;      // chips, small labels
  static const double sm = 11.5;      // subtitle, "Level progress"
  static const double md = 13;        // body text
  static const double lg = 14;        // coin count
  static const double xl = 16;        // progress heading
  static const double button = 16.5;  // main button
  static const double title = 20;     // app name
  static const double h2 = 28;        // card title
  static const double h1 = 30;        // main heading

  // Small screen = smaller, large screen = larger
  static double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / 400).clamp(0.85, 1.3);
  }

  static double s(BuildContext context, double size) =>
      size * _scale(context);
}