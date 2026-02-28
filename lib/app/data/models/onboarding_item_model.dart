import 'package:flutter/material.dart';

class OnboardingItemModel {
  const OnboardingItemModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.blobColor,
    required this.circleColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color blobColor;
  final Color circleColor;
}
