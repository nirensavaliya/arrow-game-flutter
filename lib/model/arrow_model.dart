import 'package:flutter/material.dart';

class ArrowModel {
  final List<Offset> points;

  final bool isActive;
  final bool isMoving;
  final bool isBlocked;

  /// Progress of the arrow's exit animation: 0.0 to 1.0.
  final double progress;

  /// Normalized distance the arrow moves forward when blocked.
  final double bumpTravel;

  /// Blocked animation progress: 0.0 to 1.0 and back to 0.0.
  final double bumpProgress;

  const ArrowModel({
    required this.points,
    this.isActive = true,
    this.isMoving = false,
    this.isBlocked = false,
    this.progress = 0.0,
    this.bumpTravel = 0.0,
    this.bumpProgress = 0.0,
  });

  Offset get start => points.isEmpty ? Offset.zero : points.first;

  Offset get end => points.isEmpty ? Offset.zero : points.last;

  ArrowModel copyWith({
    List<Offset>? points,
    bool? isActive,
    bool? isMoving,
    bool? isBlocked,
    double? progress,
    double? bumpTravel,
    double? bumpProgress,
  }) {
    return ArrowModel(
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      isMoving: isMoving ?? this.isMoving,
      isBlocked: isBlocked ?? this.isBlocked,
      progress: progress ?? this.progress,
      bumpTravel: bumpTravel ?? this.bumpTravel,
      bumpProgress: bumpProgress ?? this.bumpProgress,
    );
  }
}
